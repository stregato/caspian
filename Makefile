LIBS=../libs

libs:
	cp -rf $(LIBS)/* .

android: libs
	mkdir -p android/arm64-v8a
	mkdir -p android/x86_64

	test -e $(LIBS)/macos/libsafepool.dylib && cp $(LIBS)/macos/libsafepool.dylib macos/libs
	flutter build appbundle

linux: 
	flutter build linux

macos:
	mkdir -p macos/libs
	test -e $(LIBS)/macos/libsafepool.dylib && cp $(LIBS)/macos/libsafepool.dylib macos/libs
	flutter build macos
