BUILDPATH = $(CURDIR)/build
WX_CONFIG = $(shell wx-config --cxxflags --libs)
CC = clang++
CXXFLAGS = -x objective-c++ $(WX_CONFIG)
LDFLAGS = $(WX_CONFIG) -ldiscord-rpc -lcurl -lcurlpp -lz -lminizip -framework CoreFoundation -framework DiskArbitration -framework Foundation -framework Cocoa -lssl -lcrypto --std=c++20

create_main_app:
	@if [ -d $(BUILDPATH) ]; then \
		rm -d -r $(BUILDPATH); \
	fi
	@if [ -d $(CURDIR)/Macblox.app ]; then \
		rm -f -r $(CURDIR)/Macblox.app; \
	fi
	@mkdir $(BUILDPATH)
	$(CC) $(CXXFLAGS) $(LDFLAGS) -o $(BUILDPATH)/runner $(CURDIR)/runner/main.cpp
	$(CC) $(CXXFLAGS) $(LDFLAGS) -o $(BUILDPATH)/installer $(CURDIR)/installer/main.cpp
	$(CC) $(CXXFLAGS) $(LDFLAGS) -o $(BUILDPATH)/main $(CURDIR)/main_app/main.cpp
	@./appify -s build/main -n Macblox