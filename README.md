> [!CAUTION]
> This project is in the alpha stage which means you should execpt alot of bugs.
# <img src="https://raw.githubusercontent.com/SomeRandomGuy45/MacBlox/main/Images/icon.png" width="60"/> Macblox
[![GitHub Workflow Status for ARM](https://img.shields.io/github/actions/workflow/status/SomeRandomGuy45/MacBlox/arm.yml?branch=main&label=arm%20build)](https://github.com/SomeRandomGuy45/MacBlox/actions/workflows/arm.yml)
[![GitHub Workflow Status x86_64](https://img.shields.io/github/actions/workflow/status/SomeRandomGuy45/MacBlox/x86_64.yml?branch=main&label=x86_64%20build)](https://github.com/SomeRandomGuy45/MacBlox/actions/workflows/x86_64.ymls)
[![Discord Server](https://img.shields.io/discord/1273371922226483342?logo=discord&logoColor=white&color=4d3dff)](https://discord.gg/veT7GWJQ6Q)
[![cool image!](https://img.shields.io/badge/macblox%20is%20cool-yes-8A2BE2)](https://tenor.com/view/pizza-pizza-rolls-pizza-roll-gif-26147512)

Macblox is a funny project i wanted to do because there wasn't bloxstrap for macos (there is but its in py and its a api)!
(insp for top is bloxstrap!!!!)

# The TODO List
- [ ] aarch64 support (currently unknown since I don't have a aarch64 mac)
- [x] Some basic bootstrap support
- [x] Figure out how to get access to /Applications/ with out file prompt (and stop using alot of file prompts)
- [x] Discord RPC support
- [x] Checking for roblox updates
- [x] Adding ClientAppSettings
- [ ] Find a different way to close the terminal
- [x] Make a background thing that checks if roblox is being open
- [ ] Installer (im working on it)

# Building
### Libraries needed:
* wxwidgets [Github](https://github.com/wxWidgets/wxWidgets)
### Building the project:
Just run the following command
``
make
``
### Building installer:
Just install NPM and run this command
```
npm install -g appdmg
```

# Credits
* Bloxstrap for some code and inspiration [Github](https://github.com/pizzaboxer/bloxstrap)
* Emojis for MacBlox [Github](https://github.com/bloxstraplabs/rbxcustom-fontemojis) [Orignal github](https://github.com/NikSavchenk0/rbxcustom-fontemojis)
* multi-roblox-macos (for multi launcher and opening a new window) [Github](https://github.com/Insadem/multi-roblox-macos/)
* Roblox Studio Mod Manager [Github](https://github.com/MaximumADHD/Roblox-Studio-Mod-Manager)
* appify.sh [Github](https://gist.github.com/advorak/1403124)
* nlohmann json [Github](https://github.com/nlohmann/json)
* tinyxml2 [Github](https://github.com/leethomason/tinyxml2)