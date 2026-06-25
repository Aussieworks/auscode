# :books: Auscode 2.0
This repo is for the rewriten version of [auscode](https://github.com/Aussieworks/Aussieworks-Server-Script/). Auscode is an all in one stormworks server managment script that focuses on ease of use and control. With its comprehensive and easy to use settings file, its simple to customize auscode to you needs. If you would like any help you can join our discord server [here](https://discord.gg/snJyn6V2Qs).

## :hammer: Building
Building auscode requires [SSSWTool](https://github.com/Avril112113/SSSWTool), after SSSWTool has been installed and setup, download a [release](https://github.com/Aussieworks/auscode/releases) of auscode and unzip it. In the root directory of the unzipped release you can find the following files: `settings.lua` and `ssswtool.json`, the `settings.lua` file contains all the settings for auscode and the `ssswtool.json` contains the build settings for SSSWTool. After making any needed changes to the `settings.lua` and adding any `Modules` or `auscode` addons into the addons folder, running the command `ssswtool build .` will build auscode and put it into `%appdata%/Stormworks/data/missions/auscode`. If that path doesnt exist, download the `prebuilt.zip` from releases unzip and copy it into `%appdata%/Stormworks/data/missions/` and rename the folder to `auscode`, this will allow SSSWTool to build directly to the addon, the build out location can be changed by `"out": "{SW_SAVE}/data/missions/{NAME}/script.lua"` in `ssswtool.json` by setting it to the desired file path.

## :recycle: Updating
Before updating it is recommended to save a copy of your `settings.lua` and `ssswtool.json` if you have changed the build out path. Download the latest [release](https://github.com/Aussieworks/auscode/releases) of auscode, unzip it and copy everything inside. Navigate to your auscode source files and paste, clicking `replace all` if prompted. Now that auscode has been updated, open the saved copy of `settings.lua` and migrate your settings values into the new `settings.lua` making sure not to change the new defaults, this should be done for `ssswtool.json` if the build out path has been changed. After the old settings have be migrated or any changes have been made, make sure to run `ssswtool build .` to update the changes to stormworks.

## :star: Contributers and Credits
* [ChickenMst](https://github.com/chickenmst) - Main Contributer and Owner of Aussieworks
* [PeachSeatMe](https://github.com/peacheseatme) - Helping with making the backend for `auscode`
* [Avril112113](https://github.com/Avril112113) - Maker of `SSSWTool` and helped make custom buildactions for `SSSWTool`
* [Cuh4](https://github.com/cuh4) - Provided inspiration and feedback on `modules` and the rewrite of `auscode`
