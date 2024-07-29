BULIDPATH = $(CURDIR)/build

create_main_app:
	@if [ -d $(BULIDPATH) ]; then \
		echo "[INFO] Directory exists."; \
	else \
		mkdir $(BULIDPATH); \
	fi
	g++ -o $(BULIDPATH)/runner $(CURDIR)/runner/main.cpp -ldiscord-rpc -framework CoreFoundation -framework Foundation -framework Cocoa --std=c++20
	clang++ -o $(BULIDPATH)/installer $(CURDIR)/installer/main.cpp -lcurl -lz -lminizip -framework CoreFoundation -framework DiskArbitration -framework Foundation -framework Cocoa --std=c++20