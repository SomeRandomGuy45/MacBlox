BUILDPATH = $(CURDIR)/build
BUILDARGS = -ldiscord-rpc -lcurl -lcurlpp -lz -lminizip -framework CoreFoundation -framework DiskArbitration -framework Foundation -framework Cocoa -lssl -lcrypto --std=c++20
CC = clang++
CXXFLAGS = -x objective-c++ -I/usr/local/include/curlpp
LDFLAGS = -L/usr/local/lib  # Add library directory for curlpp

create_main_app:
	@if [ -d $(BUILDPATH) ]; then \
		rm -d -r $(BUILDPATH); \
	fi
	@mkdir $(BUILDPATH)
	$(CC) $(CXXFLAGS) $(LDFLAGS) -o $(BUILDPATH)/runner $(CURDIR)/runner/main.cpp $(BUILDARGS)
	$(CC) $(CXXFLAGS) $(LDFLAGS) -o $(BUILDPATH)/installer $(CURDIR)/installer/main.cpp $(BUILDARGS)
	$(CC) $(CXXFLAGS) $(LDFLAGS) -o $(BUILDPATH)/main $(CURDIR)/main_app/main.cpp $(BUILDARGS)
