@echo off
REM Windows: manager ONLY. For Linux full install (Steam+dedicated) use install/bootstrap.sh — see README.
REM Runs install_manager.ps1 (venv, aus-server, aus, start/stop).
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_manager.ps1" %*
exit /b %ERRORLEVEL%
