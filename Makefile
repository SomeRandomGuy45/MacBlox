# Paths and configuration
BUILDPATH = $(CURDIR)/build
WX_CONFIG = $(shell wx-config --cxxflags --libs)
CC = clang++
CXXFLAGS = -x objective-c++ $(WX_CONFIG) $(LIBRARY_PATH)
LDFLAGS = $(WX_CONFIG) $(CPATH) -lcurl -lcurlpp -lz -lminizip -framework CoreFoundation -framework DiskArbitration -framework Foundation -framework Cocoa -framework UserNotifications -framework ServiceManagement -lssl -lcrypto --std=c++20

# Default target
all: create_runner_app create_main_app create_background_app

# Create the main app
create_runner_app:
	@if [ -d $(BUILDPATH) ]; then \
		rm -d -r $(BUILDPATH); \
	fi
	@mkdir $(BUILDPATH)
	@mkdir $(BUILDPATH)/Macblox
	$(CC) $(CXXFLAGS) $(LDFLAGS) -o $(BUILDPATH)/runner $(CURDIR)/runner/main.m $(CURDIR)/runner/helper.mm $(CURDIR)/runner/AppDelegate.mm $(CURDIR)/runner/main_helper.mm
	@./appify -s build/runner -n play -i test
	@codesign --sign - --entitlements Macblox.plist --deep play.app --force
	@mv -f play.app $(BUILDPATH)/play.app
	@mv $(BUILDPATH)/play.app $(BUILDPATH)/Macblox/"Play.app"
	@cp -R $(CURDIR)/runner/discord.py $(BUILDPATH)/Macblox/"Play.app"/Contents/Resources/
	@cp -R $(CURDIR)/runner/test_icon.png $(BUILDPATH)/Macblox/"Play.app"/Contents/Resources/
	@rm -f $(BUILDPATH)/runner
	$(CC) $(CXXFLAGS) $(LDFLAGS) -o $(BUILDPATH)/bootstrap $(CURDIR)/bootstrap/app.mm $(CURDIR)/bootstrap/helper.mm
	@./appify -s build/bootstrap -n bootstrap -i test
	@codesign --sign - --entitlements Macblox.plist --deep bootstrap.app --force
	@mv -f bootstrap.app $(BUILDPATH)/bootstrap.app
	@mv $(BUILDPATH)/bootstrap.app $(BUILDPATH)/Macblox/"Bootstrap.app"
	@cp -R $(CURDIR)/bootstrap/bootstrap_data.json $(BUILDPATH)/Macblox/"Bootstrap.app"/Contents/Resources/
	@cp -R $(CURDIR)/bootstrap/bootstrap_icon.png $(BUILDPATH)/Macblox/"Bootstrap.app"/Contents/Resources/
	@cp -R $(CURDIR)/bootstrap/helper.sh $(BUILDPATH)/Macblox/"Bootstrap.app"/Contents/Resources/
	@chmod +x $(BUILDPATH)/Macblox/"Bootstrap.app"/Contents/Resources/helper.sh
	@rm -f $(BUILDPATH)/bootstrap
	@mv $(BUILDPATH)/Macblox/"Bootstrap.app" $(BUILDPATH)/Macblox/"Play.app"/Contents/MacOS
	$(CC) $(CXXFLAGS) $(LDFLAGS) -o $(BUILDPATH)/BackgroundApp $(CURDIR)/background/AppDelegate.mm $(CURDIR)/background/helper.mm $(CURDIR)/background/BackgroundTask.mm $(CURDIR)/background/main.m $(CURDIR)/background/StartAtLoginController.m
	@./appify_background -s $(BUILDPATH)/BackgroundApp -n BackgroundApp -i test
	@codesign --sign - --entitlements Macblox_background.plist --deep BackgroundApp.app --force
	@mv -f BackgroundApp.app $(BUILDPATH)/Macblox/BackgroundApp.app
	@cp -R $(CURDIR)/background/test_icon.png $(BUILDPATH)/Macblox/"BackgroundApp.app"/Contents/Resources/
	@rm -f $(BUILDPATH)/BackgroundApp
	@mv $(BUILDPATH)/Macblox/"BackgroundApp.app" $(BUILDPATH)/Macblox/"Play.app"/Contents/MacOS

create_main_app:
	$(CC) $(CXXFLAGS) $(LDFLAGS) -o $(BUILDPATH)/main $(CURDIR)/main_app/main.cpp $(CURDIR)/main_app/Downloader.mm
	@./appify -s build/main -n Macblox -i test
	@codesign --sign - --entitlements Macblox.plist --deep Macblox.app --force
	@mv -f Macblox.app $(BUILDPATH)/Macblox/Macblox.app
	@rm -f $(BUILDPATH)/main

create_installer_app:
	@./appify -s Install.sh -n Install -i test  
	@codesign --sign - --entitlements Macblox.plist --deep Install.app --force

# Clean the build directory
clean:
	rm -rf $(BUILDPATH)

# Phony targets
.PHONY: all create_main_app create_background_app clean
