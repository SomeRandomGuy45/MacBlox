BUILDPATH = $(CURDIR)/build
BUILDARGS = -ldiscord-rpc -lcurl -lcurlpp -lz -lminizip -framework CoreFoundation -framework DiskArbitration -framework Foundation -framework Cocoa -lssl -lcrypto --std=c++20
CC = clang++
CXXFLAGS += -x objective-c++

create_main_app:
	@if [ -d $(BUILDPATH) ]; then \
		rm -d -r $(BUILDPATH); \
	fi
	@mkdir $(BUILDPATH)
	$(CC) $(CXXFLAGS) -o $(BUILDPATH)/runner $(CURDIR)/runner/main.cpp $(BUILDARGS)
	$(CC) -o $(BUILDPATH)/installer $(CURDIR)/installer/main.cpp $(BUILDARGS)
