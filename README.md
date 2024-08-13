> [!CAUTION]
> This project is in the alpha stage which means you should execpt alot of bugs.

# Macblox
Macblox is a funny project i wanted to do because there wasn't bloxstrap for macos (there is but its in py and its a api)!

# The TODO List
- [ ] aarch64 support (currently unknown since I don't have a aarch64 mac)
- [x] Some basic bootstrap support
- [x] Figure out how to get access to /Applications/ with out file prompt (and stop using alot of file prompts)
- [x] Discord RPC support
- [x] Checking for roblox updates
- [x] Adding ClientAppSettings
- [ ] Find a different way to close the terminal
- [ ] Make a background thing that checks if roblox is being open

# Building
### Libraries needed:
* discord-rpc [Download](https://github.com/discord/discord-rpc)
* libcurl [Website](https://curl.se/libcurl/)
* curlpp [Github](https://github.com/jpbarrette/curlpp/)
* wxwidgets [Github](https://github.com/wxWidgets/wxWidgets)
### Building the project:
Just run the following command
``
make
``

# Credits
* Bloxstrap for some code and inspiration [Github](https://github.com/pizzaboxer/bloxstrap)
* appify.sh [Github](https://gist.github.com/advorak/1403124)