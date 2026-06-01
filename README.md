# :books: Auscode 2.0
This repo is for the rewriten version of [auscode](https://github.com/Aussieworks/Aussieworks-Server-Script/). Auscode is an all in one stormworks server managment script that focuses on ease of use and control. With a easy to use settings file containing all settings its easy to customize auscode to you needs. If you would like any help you can join our discord server [here](https://discord.gg/snJyn6V2Qs).

## :hammer: Building
Building auscode requires [SSSWTool](https://github.com/Avril112113/SSSWTool), after SSSWTool has been installed and setup download a [release](https://github.com/Aussieworks/auscode/releases) of auscode and unzip it. In the root directory of the unzipped release you can find the following files: `settings.lua` and `ssswtool.json`, the `settings.lua` file contains all the settings for auscode and the `ssswtool.json` contains the build settings for SSSWTool. After making any needed changes to the `settings.lua` and adding any `Modules` or `auscode` addons into the addons folder, running the command `ssswtool build .` will build auscode and put it into `%appdata%/Stormworks/data/missions/auscode`. If that path doesnt exist, copy the prebuilt folder and place it into `%appdata%/Stormworks/data/missions/` and rename the folder to `auscode`, this will allow SSSWTool to build directly to the addon, the build out location can be changed by `"out": "{SW_SAVE}/data/missions/{NAME}/script.lua"` in `ssswtool.json` by setting it to the desired file path.

## :star: Contributers and Credits
* [ChickenMst](https://github.com/chickenmst) - Main Contributer and Owner of Aussieworks
* [PeachSeatMe](https://github.com/peacheseatme) - Helping with making the backend for `auscode`
* [Avril112113](https://github.com/Avril112113) - Maker of `SSSWTool` and helped make custom buildactions for `SSSWTool`
* [Cuh4](https://github.com/cuh4) - Provided inspiration and feedback on `modules` and the rewrite of `auscode`