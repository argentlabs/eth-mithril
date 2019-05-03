BUILDPATH = .build
IOSBUILDPATH = .build-ios
KEYPATH = .keys
BUILD_IOS = make -C $(IOSBUILDPATH) && make -C $(IOSBUILDPATH) install
IOSINSTALLPATH = ios/iOSProver/depends/lib/libmixer.dylib

all: clean build test ios-build-universal solidity-deploy

build: release
	make -C $(BUILDPATH)

release:
	mkdir -p $(BUILDPATH) && cd $(BUILDPATH) && cmake -DCMAKE_BUILD_TYPE=Release ../circuit/
debug:
	mkdir -p $(BUILDPATH) && cd $(BUILDPATH) && cmake -DCMAKE_BUILD_TYPE=Debug ../circuit/
performance:
	mkdir -p $(BUILDPATH) && cd $(BUILDPATH) && cmake -DCMAKE_BUILD_TYPE=Release -DPERFORMANCE=1 ../circuit/

update-submodules:
	git submodule update --init --recursive

clean:
	rm -rf $(BUILDPATH) && rm -rf $(KEYPATH)

genkeys: build
	mkdir -p $(KEYPATH)
	$(BUILDPATH)/mixer_cli genkeys $(KEYPATH)/mixer.pk.raw $(KEYPATH)/mixer.vk.json

test: genkeys solidity-test python-test

python-test:
	make -C python test

solidity-test:
	make -C solidity test
solidity-deploy:
	make -C solidity deploy-rinkeby

ios-clean:
	rm -rf $(IOSBUILDPATH)
ios-simulator: ios-clean
	mkdir -p $(IOSBUILDPATH) && cd $(IOSBUILDPATH) && cmake -DCMAKE_TOOLCHAIN_FILE=../ios/ios.toolchain.cmake -DIOS_PLATFORM=SIMULATOR64 -DENABLE_VISIBILITY=1 -DIOS_BUILD=1 -DCMAKE_BUILD_TYPE=Release ../circuit/
ios-device: ios-clean
	mkdir -p $(IOSBUILDPATH) && cd $(IOSBUILDPATH) && cmake -DCMAKE_TOOLCHAIN_FILE=../ios/ios.toolchain.cmake -DIOS_PLATFORM=OS64 -DENABLE_BITCODE=0 -DENABLE_VISIBILITY=1 -DIOS_BUILD=1 -DCMAKE_BUILD_TYPE=Release ../circuit/
ios-build-device: ios-device
	$(BUILD_IOS)
ios-build-simulator: ios-simulator
	$(BUILD_IOS)
ios-build-universal: ios-build-device
	mv $(IOSINSTALLPATH) $(IOSINSTALLPATH).device
	$(MAKE) ios-build-simulator
	mv $(IOSINSTALLPATH) $(IOSINSTALLPATH).simulator
	lipo -create -output $(IOSINSTALLPATH) $(IOSINSTALLPATH).{device,simulator}
	rm $(IOSINSTALLPATH).*
