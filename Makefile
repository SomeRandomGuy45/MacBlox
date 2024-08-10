BUILDPATH = $(CURDIR)/build
WX_CONFIG = $(shell wx-config --cxxflags --libs)
CC = clang++

CXXFLAGS = -x objective-c++ $(WX_CONFIG) -I/usr/local/include/wx-3.2 -I/usr/local/lib/wx/include/osx_cocoa-unicode-3.2 -std=c++20
LDFLAGS = $(WX_CONFIG) -ldiscord-rpc -lcurl -lcurlpp -lz -lminizip -framework CoreFoundation -framework DiskArbitration -framework Foundation -framework Cocoa -framework UserNotifications -lssl -lcrypto

create_main_app:
	@if [ -d $(BUILDPATH) ]; then \
		rm -d -r $(BUILDPATH); \
	fi
	@mkdir $(BUILDPATH)
	@mkdir $(BUILDPATH)/Macblox
	
	# Compile the runner app
	$(CC) $(CXXFLAGS) -o $(BUILDPATH)/runner $(CURDIR)/runner/main.cpp $(CURDIR)/runner/helper.mm $(LDFLAGS)
	@./appify -s build/runner -n play -i test
	@codesign --sign - --entitlements Macblox.plist --deep play.app --force
	@mv -f play.app $(BUILDPATH)/play.app
	@mv $(BUILDPATH)/play.app $(BUILDPATH)/Macblox/"Play Roblox.app"
	@rm -f $(BUILDPATH)/runner
	
	# Compile the bootstrap app
	$(CC) $(CXXFLAGS) -o $(BUILDPATH)/bootstrap $(CURDIR)/bootstrap/app.cpp $(CURDIR)/bootstrap/helper.mm $(LDFLAGS)
	@./appify -s build/bootstrap -n bootstrap -i test
	@codesign --sign - --entitlements Macblox.plist --deep bootstrap.app --force
	@mv -f bootstrap.app $(BUILDPATH)/bootstrap.app
	@mv $(BUILDPATH)/bootstrap.app $(BUILDPATH)/Macblox/"Bootstrap.app"
	@cp -R $(CURDIR)/bootstrap/bootstrap_data.json $(BUILDPATH)/Macblox/"Bootstrap.app"/Contents/Resources/
	@cp -R $(CURDIR)/bootstrap/bootstrap_icon.png $(BUILDPATH)/Macblox/"Bootstrap.app"/Contents/Resources/
	@cp -R $(CURDIR)/bootstrap/helper.sh $(BUILDPATH)/Macblox/"Bootstrap.app"/Contents/Resources/
	@chmod +x $(BUILDPATH)/Macblox/"Bootstrap.app"/Contents/Resources/helper.sh
	@rm -f $(BUILDPATH)/bootstrap
	
	# Compile the main Macblox app
	$(CC) $(CXXFLAGS) -o $(BUILDPATH)/main $(CURDIR)/main_app/main.cpp $(CURDIR)/main_app/Downloader.mm $(LDFLAGS)
	@./appify -s build/main -n Macblox -i test
	@codesign --sign - --entitlements Macblox.plist --deep Macblox.app --force
	@mv -f Macblox.app $(BUILDPATH)/Macblox/Macblox.app
	@rm -f $(BUILDPATH)/main
