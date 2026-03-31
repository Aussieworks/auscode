#Requires -Version 5.1
<#
.SYNOPSIS
  Aus server manager install for Windows (venv, API/CLI, launcher scripts).

.DESCRIPTION
  Manager ONLY on Windows — not the Linux Steam/bootstrap flow. See repo README "Which install script".

  Copies server_manager / aus_cli, creates a venv, installs requirements, and writes
  bin\*.cmd plus start/stop PowerShell helpers. Does not install Steam or Stormworks.

.PARAMETER InstallRoot
  Install directory (default: %LOCALAPPDATA%\Aus).

.PARAMETER ApiUrl
  Base URL for the aus CLI (default: http://127.0.0.1:8000).

.PARAMETER ApiPort
  Port for uvicorn when running aus-server (default: 8000).

.PARAMETER NonInteractive
  Skip prompts; use defaults and parameters only.

.PARAMETER SkipDefaultServersJson
  Do not copy servers.json.example (e.g. if another step will write servers.json).

.EXAMPLE
  .\install_manager.ps1

.EXAMPLE
  .\install_manager.ps1 -InstallRoot D:\Aus -ApiPort 8080 -NonInteractive
#>
[CmdletBinding()]
param(
    [string] $InstallRoot = "",
    [string] $ApiUrl = "",
    [int] $ApiPort = 0,
    [switch] $NonInteractive,
    [switch] $SkipDefaultServersJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$DefaultInstallRoot = Join-Path $env:LOCALAPPDATA "Aus"
$DefaultApiPort = 8000
$DefaultApiUrl = "http://127.0.0.1:$DefaultApiPort"

if (-not $InstallRoot) { $InstallRoot = $DefaultInstallRoot }
if (-not $ApiPort) { $ApiPort = $DefaultApiPort }
if (-not $ApiUrl) { $ApiUrl = "http://127.0.0.1:$ApiPort" }

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$NestedLib = Join-Path $RepoRoot "auscode\auscode"
$FlatLib = Join-Path $RepoRoot "auscode"
if (Test-Path -LiteralPath (Join-Path $NestedLib "server_manager.py") -PathType Leaf) {
    $SrcLib = $NestedLib
    $SrcConfigDir = Join-Path $RepoRoot "auscode\config"
    $ReqFile = Join-Path $RepoRoot "auscode\requirements.txt"
}
elseif (Test-Path -LiteralPath (Join-Path $FlatLib "server_manager.py") -PathType Leaf) {
    $SrcLib = $FlatLib
    $SrcConfigDir = Join-Path $RepoRoot "config"
    $ReqFile = Join-Path $RepoRoot "requirements.txt"
}
else {
    throw "Cannot find server_manager.py under $RepoRoot (expected auscode\auscode\ or auscode\)."
}

if (-not $NonInteractive) {
    Write-Host "Aus server manager installer (Windows)"
    Write-Host "--------------------------------------"
    $r = Read-Host "Install directory for Aus (venv, config, bin) [$InstallRoot]"
    if ($r) { $InstallRoot = $r }
    $r = Read-Host "API URL for CLI [$ApiUrl]"
    if ($r) { $ApiUrl = $r }
    $r = Read-Host "HTTP port for aus-server [$ApiPort]"
    if ($r) { $ApiPort = [int]$r }
}

$InstallRoot = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($InstallRoot)
New-Item -ItemType Directory -Force -Path (Join-Path $InstallRoot "lib") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $InstallRoot "config") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $InstallRoot "bin") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $InstallRoot "run") | Out-Null

Write-Host "Installing to: $InstallRoot"
Write-Host "Using REPO_ROOT: $RepoRoot"

Copy-Item -Force (Join-Path $SrcLib "server_manager.py") (Join-Path $InstallRoot "lib\")
Copy-Item -Force (Join-Path $SrcLib "aus_cli.py") (Join-Path $InstallRoot "lib\")
Copy-Item -Force $ReqFile (Join-Path $InstallRoot "requirements.txt")

$CfgOut = Join-Path $InstallRoot "config\servers.json"
if ($SkipDefaultServersJson) {
    Write-Host "Skipping default servers.json."
}
elseif (-not (Test-Path -LiteralPath $CfgOut -PathType Leaf)) {
    $Example = Join-Path $SrcConfigDir "servers.json.example"
    if (Test-Path -LiteralPath $Example -PathType Leaf) {
        Copy-Item -Force $Example $CfgOut
        Write-Host "Created $CfgOut from example — edit executable_path and working_directory for Stormworks."
    }
    else {
        '{"servers":{"1":{"executable_path":".\\Stormworks_Server_x64.exe","launch_args":"","working_directory":".","use_wine":false}}}' |
            Set-Content -LiteralPath $CfgOut -Encoding UTF8
        Write-Host "Created minimal $CfgOut — edit before use."
    }
}
else {
    Write-Host "Keeping existing $CfgOut"
}

$VenvPython = Join-Path $InstallRoot "venv\Scripts\python.exe"
if (-not (Test-Path -LiteralPath $VenvPython -PathType Leaf)) {
    if (Get-Command py -ErrorAction SilentlyContinue) {
        py -3 -m venv (Join-Path $InstallRoot "venv")
    }
    else {
        python -m venv (Join-Path $InstallRoot "venv")
    }
}

if (-not (Test-Path -LiteralPath $VenvPython -PathType Leaf)) {
    Write-Error "Python venv failed. Install Python 3.10+ from python.org and ensure 'python' or 'py' is on PATH."
}

& $VenvPython -m pip install --upgrade pip
& $VenvPython -m pip install -r (Join-Path $InstallRoot "requirements.txt")

$Bin = Join-Path $InstallRoot "bin"
$VenvPy = Join-Path $InstallRoot "venv\Scripts\python.exe"
$LibPy = Join-Path $InstallRoot "lib\aus_cli.py"

# --- aus.cmd ---
$AusCmd = @"
@echo off
setlocal
set "AUS_CONFIG_DIR=$InstallRoot\config"
set "AUS_API_URL=$ApiUrl"
"$VenvPy" "$LibPy" %*
"@
Set-Content -LiteralPath (Join-Path $Bin "aus.cmd") -Value $AusCmd -Encoding ASCII

# --- aus-server.cmd ---
$AusServerCmd = @"
@echo off
setlocal
set "AUS_CONFIG_DIR=$InstallRoot\config"
set "PYTHONPATH=$InstallRoot\lib"
cd /d "$InstallRoot\lib"
"$VenvPy" -m uvicorn server_manager:app --host 0.0.0.0 --port $ApiPort %*
"@
Set-Content -LiteralPath (Join-Path $Bin "aus-server.cmd") -Value $AusServerCmd -Encoding ASCII

# --- start-aus.ps1 ---
$StartPs1 = @"
`$ErrorActionPreference = 'Stop'
`$InstallRoot = '$($InstallRoot.Replace("'", "''"))'
`$ApiPort = $ApiPort
`$ApiUrl = '$($ApiUrl.Replace("'", "''"))'
`$env:AUS_CONFIG_DIR = Join-Path `$InstallRoot 'config'
`$env:AUS_API_URL = `$ApiUrl
`$env:PYTHONPATH = Join-Path `$InstallRoot 'lib'
`$VenvPy = Join-Path `$InstallRoot 'venv\Scripts\python.exe'
`$PidFile = Join-Path `$InstallRoot 'run\aus-server.pid'
`$LogFile = Join-Path `$InstallRoot 'run\aus-server.log'
`$StatusUrl = "http://127.0.0.1:`$ApiPort/server/status"
`$ok = `$false
try {
    Invoke-WebRequest -Uri `$StatusUrl -UseBasicParsing -TimeoutSec 2 | Out-Null
    `$ok = `$true
} catch { }
if (-not `$ok) {
    Write-Host 'Starting aus-server in background...'
    `$argList = @('-m', 'uvicorn', 'server_manager:app', '--host', '0.0.0.0', '--port', `$ApiPort)
    `$errLog = Join-Path `$InstallRoot 'run\aus-server.err.log'
    `$p = Start-Process -FilePath `$VenvPy -ArgumentList `$argList -WorkingDirectory (Join-Path `$InstallRoot 'lib') `
        -WindowStyle Hidden -PassThru -RedirectStandardOutput `$LogFile -RedirectStandardError `$errLog
    `$p.Id | Out-File -LiteralPath `$PidFile -Encoding ascii -NoNewline
    Start-Sleep -Seconds 2
} else {
    Write-Host "aus-server already responding on port `$ApiPort"
}
Write-Host "Server starting; API at `$ApiUrl — stop: $(Join-Path $Bin 'stop-aus.ps1')"
`$AusBat = Join-Path `$InstallRoot 'bin\aus.cmd'
& `$AusBat start 1
if (`$null -ne `$LASTEXITCODE -and `$LASTEXITCODE -ne 0) { exit `$LASTEXITCODE }
"@
Set-Content -LiteralPath (Join-Path $Bin "start-aus.ps1") -Value $StartPs1 -Encoding UTF8

# --- stop-aus.ps1 ---
$StopPs1 = @"
`$ErrorActionPreference = 'Continue'
`$InstallRoot = '$($InstallRoot.Replace("'", "''"))'
`$ApiUrl = '$($ApiUrl.Replace("'", "''"))'
`$env:AUS_CONFIG_DIR = Join-Path `$InstallRoot 'config'
`$env:AUS_API_URL = `$ApiUrl
`$PidFile = Join-Path `$InstallRoot 'run\aus-server.pid'
if (Test-Path -LiteralPath `$PidFile) {
    `$id = (Get-Content -LiteralPath `$PidFile -Raw).Trim()
    if (`$id -match '^\d+`$') {
        try { Stop-Process -Id ([int]`$id) -Force -ErrorAction SilentlyContinue } catch { }
    }
    Remove-Item -LiteralPath `$PidFile -Force -ErrorAction SilentlyContinue
}
`$AusBat = Join-Path `$InstallRoot 'bin\aus.cmd'
& `$AusBat stop 1 2>`$null
Write-Host 'Stopped API (if running) and requested managed server stop.'
"@
Set-Content -LiteralPath (Join-Path $Bin "stop-aus.ps1") -Value $StopPs1 -Encoding UTF8

# Thin cmd stubs so PATH / double-click works
$StartCmd = @"
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-aus.ps1"
"@
Set-Content -LiteralPath (Join-Path $Bin "start-aus.cmd") -Value $StartCmd -Encoding ASCII

$StopCmd = @"
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0stop-aus.ps1"
"@
Set-Content -LiteralPath (Join-Path $Bin "stop-aus.cmd") -Value $StopCmd -Encoding ASCII

Write-Host ""
Write-Host "Done."
Write-Host "  Start API:  $(Join-Path $Bin 'aus-server.cmd')"
Write-Host "  One-shot:   $(Join-Path $Bin 'start-aus.cmd')  (or start-aus.ps1)"
Write-Host "  Stop:       $(Join-Path $Bin 'stop-aus.cmd')"
Write-Host "  CLI:        $(Join-Path $Bin 'aus.cmd')"
Write-Host "  Config:     $CfgOut"
Write-Host ""
Write-Host "Add to PATH for this session:  set PATH=$Bin;%PATH%"
Write-Host ""
