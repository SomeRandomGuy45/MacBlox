BULIDPATH = "$(CURDIR)/bulid"
create_main_app:
	@if [ -d BULIDPATH ]; then \
		echo "[INFO] Directory exists."; \
	else \
		mkdir BULIDPATH; \
	fi
	g++ -o $(CURDIR)/bulid/runner $(CURDIR)/runner/main.cpp --std=c++20
	clang++ -o $(CURDIR)/bulid/installer $(CURDIR)/installer/main.cpp -lcurl -lz -lminizip -framework CoreFoundation -framework DiskArbitration --std=c++20