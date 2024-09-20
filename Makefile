BUILDPATH = $(CURDIR)/build
WX_CONFIG = $(shell wx-config --cxxflags --libs)
ARCH = $(shell uname -m)
ARCH_FLAGS = $(shell if [ "$(ARCH)" = "arm64" ]; then echo "-arch arm64"; fi)
BREW_PREFIX = $(shell brew --prefix)
BREW_INCLUDE = -I$(BREW_PREFIX)/include
BREW_LIB = -L$(BREW_PREFIX)/lib
OPENSSL_PREFIX = $(shell brew --prefix openssl)
OPENSSL_PREFIX_LIB = $(OPENSSL_PREFIX)/lib
OPENSLL_lib1 = $(OPENSSL_PREFIX_LIB)/libssl.3.dylib
OPENSLL_lib2 = $(OPENSSL_PREFIX_LIB)/libcrypto.3.dylib
LUA_PREFIX = $(shell brew --prefix lua)
LUA_INCLUDE = -I$(LUA_PREFIX)/include
LUA_LIB = -L$(LUA_PREFIX)/lib -llua
CC = clang++
CXXFLAGS = -x objective-c++ $(WX_CONFIG) $(LIBRARY_PATH) $(BREW_LIB) $(BREW_INCLUDE) $(LUA_INCLUDE)
LDFLAGS = $(ARCH_FLAGS) $(WX_CONFIG) $(CPATH) $(CURLPP_CONFIG_CFLAGS) $(CURLPP_CONFIG_INCLUDE) $(MINI_CONFIG_LIBS) $(MINI_CONFIG_INCLUDE) -framework CoreFoundation -framework DiskArbitration -framework Foundation -framework Cocoa -framework UserNotifications -framework ServiceManagement -lssl -lcrypto $(LUA_LIB) --std=c++20

# Default target
all: create_runner_app create_main_app create_background_app resign

create_smart_app:
	@xcodebuild -project $(CURDIR)/"Smart Join"/"Smart Join.xcodeproj" -scheme "Smart Join" -configuration Release -derivedDataPath $(CURDIR)/"Smart Join"
	@mv -f $(CURDIR)/"Smart Join"/Build/Products/Release/"Smart Join.app" $(BUILDPATH)/Macblox/"Smart Join.app"
	@mv -f $(CURDIR)/"Smart Join"/Build/Products/Release/"Smart Join.app.dSYM" $(BUILDPATH)/Macblox/"Smart Join.app.dSYM"

create_helper_app:
	@xcodebuild -project $(CURDIR)/"GameWatcher"/"GameWatcher.xcodeproj" -scheme "GameWatcher" -configuration Release -derivedDataPath $(CURDIR)/"GameWatcher"

# Create the main app
create_runner_app:
	@if [ -d $(BUILDPATH) ]; then \
		rm -d -r -rf $(BUILDPATH); \
	fi
	@rm -rf $(CURDIR)/GameWatcherApp 
	@mkdir $(BUILDPATH)
	@mkdir $(BUILDPATH)/Macblox
	$(CC) $(CXXFLAGS) $(LDFLAGS) -o $(BUILDPATH)/runner $(CURDIR)/runner/main.m $(CURDIR)/runner/helper.mm $(CURDIR)/runner/AppDelegate.mm $(CURDIR)/runner/main_helper.mm
	@./appify_background -s build/runner -n play -i Images/icon.icns
	@codesign --sign - --entitlements Macblox.plist --deep play.app --force
	@mv -f play.app $(BUILDPATH)/play.app
	@mv $(BUILDPATH)/play.app $(BUILDPATH)/Macblox/"Play.app"
	@cp -R $(CURDIR)/runner/Discord $(BUILDPATH)/Macblox/"Play.app"/Contents/Resources/
	@cp -R $(CURDIR)/runner/display.png $(BUILDPATH)/Macblox/"Play.app"/Contents/Resources/
	@cp -R $(CURDIR)/runner/display@2x.png $(BUILDPATH)/Macblox/"Play.app"/Contents/Resources/
	@rm -f $(BUILDPATH)/runner
	@./fixInstall.sh $(BUILDPATH)/Macblox/"Play.app"/Contents/MacOS/play $(BUILDPATH)/Macblox/"Play.app"/Contents/
	$(CC) $(CXXFLAGS) $(LDFLAGS) -o $(BUILDPATH)/bootstrap $(CURDIR)/bootstrap/app.mm $(CURDIR)/bootstrap/helper.mm $(CURDIR)/bootstrap/tinyxml2.cpp $(CURDIR)/bootstrap/multi.mm $(CURDIR)/bootstrap/autoUpdater.mm
	@./appify -s build/bootstrap -n bootstrap -i Images/icon.icns
	@codesign --sign - --entitlements Macblox.plist --deep bootstrap.app --force
	@mv -f bootstrap.app $(BUILDPATH)/bootstrap.app
	@mv $(BUILDPATH)/bootstrap.app $(BUILDPATH)/Macblox/"Bootstrap.app"
	@cp -R $(CURDIR)/bootstrap/bootstrap_data.json $(BUILDPATH)/Macblox/"Bootstrap.app"/Contents/Resources/
	@cp -R $(CURDIR)/bootstrap/bootstrap_icon.ico $(BUILDPATH)/Macblox/"Bootstrap.app"/Contents/Resources/
	@cp -R $(CURDIR)/bootstrap/128x128.ico $(BUILDPATH)/Macblox/"Bootstrap.app"/Contents/Resources/
	@cp -R $(CURDIR)/bootstrap/helper.sh $(BUILDPATH)/Macblox/"Bootstrap.app"/Contents/Resources/
	@cp -R $(CURDIR)/Macblox.plist $(BUILDPATH)/Macblox/"Bootstrap.app"/Contents/Resources/
	@chmod +x $(BUILDPATH)/Macblox/"Bootstrap.app"/Contents/Resources/helper.sh
	@./fixInstall.sh $(BUILDPATH)/Macblox/"Bootstrap.app"/Contents/MacOS/bootstrap $(BUILDPATH)/Macblox/"Bootstrap.app"/Contents/
	@rm -f $(BUILDPATH)/bootstrap
	@mv $(BUILDPATH)/Macblox/"Bootstrap.app" $(BUILDPATH)/Macblox/"Play.app"/Contents/MacOS
	$(CC) $(CXXFLAGS) $(LDFLAGS) -o $(BUILDPATH)/openRoblox $(CURDIR)/openRoblox/main.m $(CURDIR)/openRoblox/AppDelegate.mm
	@./appify -s build/openRoblox -n openRoblox -i Images/icon.icns
	@codesign --sign - --entitlements Macblox.plist --deep openRoblox.app --force
	@mv -f openRoblox.app $(BUILDPATH)/Macblox/"Open Roblox.app"
	@./fixInstall.sh $(BUILDPATH)/Macblox/"Open Roblox.app"/Contents/MacOS/openRoblox $(BUILDPATH)/Macblox/"Open Roblox.app"/Contents/
	@rm -f $(BUILDPATH)/openRoblox
	@git clone https://github.com/SomeRandomGuy45/GameWatcherApp.git
	@unzip $(CURDIR)/GameWatcherApp/GameWatcher.app.zip
	@chmod +x $(CURDIR)/GameWatcher.app/Contents/MacOS/GameWatcher
	@mv $(CURDIR)/GameWatcher.app $(BUILDPATH)/Macblox/"Play.app"/Contents/MacOS

create_main_app:
	$(CC) $(CXXFLAGS) $(LDFLAGS) -o $(BUILDPATH)/main $(CURDIR)/main_app/main.mm $(CURDIR)/main_app/Downloader.mm
	@./appify -s build/main -n Macblox -i Images/icon.icns
	@codesign --sign - --entitlements Macblox.plist --deep Macblox.app --force
	@mv -f Macblox.app $(BUILDPATH)/Macblox/Macblox.app
	@./fixInstall.sh $(BUILDPATH)/Macblox/"Macblox.app"/Contents/MacOS/Macblox $(BUILDPATH)/Macblox/"Macblox.app"/Contents/
	@rm -f $(BUILDPATH)/main

create_installer_app:
	@./appify -s Install.sh -n Install -i Images/icon.icns  
	@codesign --sign - --entitlements Macblox.plist --deep Install.app --force

resign:
	@codesign --sign - --entitlements Macblox.plist --deep $(BUILDPATH)/Macblox/"Macblox.app" --force
	@codesign --sign - --entitlements Macblox.plist --deep $(BUILDPATH)/Macblox/"Open Roblox.app" --force
	@codesign --sign - --entitlements Macblox.plist --deep $(BUILDPATH)/Macblox/"Play.app" --force
	@codesign --sign - --entitlements Macblox.plist --deep $(BUILDPATH)/Macblox/"Play.app"/Contents/MacOS/"Bootstrap.app" --force

# Clean the build directory
clean:
	rm -rf $(BUILDPATH)

# Phony targets
.PHONY: all create_main_app create_background_app clean