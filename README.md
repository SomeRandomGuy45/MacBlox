> [!CAUTION]
> This project is in the alpha stage which means you should execpt alot of bugs.

# Macblox
Macblox is a funny project i wanted to do because there wasn't bloxstrap for macos (there is but its in py and its a api)!

# Building
### Libraries needed:
* discord-rpc [Download](https://github.com/discord/discord-rpc)
* libcurl [Website](https://curl.se/libcurl/)
* curlpp [Github](https://github.com/jpbarrette/curlpp/)
* wxwidgets [Github](https://github.com/wxWidgets/wxWidgets)
### Building the project:
Just run the following commands

``
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_MAKE_PROGRAM=ninja -DCMAKE_TOOLCHAIN_FILE= <user path here>/.vcpkg/vcpkg/scripts/buildsystems/vcpkg.cmake -G Ninja -S <path to project>s/Macblox -B <path to project>/build
``

# Credits
* Bloxstrap for some code and inspiration [Github](https://github.com/pizzaboxer/bloxstrap)
* appify.sh [Github](https://gist.github.com/advorak/1403124)