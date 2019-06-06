BUILDPATH = .build
IOSBUILDPATH = .build-ios
KEYPATH = .keys
BUILD_IOS = make -C $(IOSBUILDPATH) && make -C $(IOSBUILDPATH) install
IOSINSTALLPATH = ios/Hopper/depends/lib

all: clean build test ios-build-device solidity-deploy

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
	make -C solidity deploy-ropsten

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
	mv $(IOSINSTALLPATH)/libmixer.a $(IOSINSTALLPATH)/libmixer.a.device
	mv $(IOSINSTALLPATH)/libff.a $(IOSINSTALLPATH)/libff.a.device
	mv $(IOSINSTALLPATH)/libethsnarks_common.a $(IOSINSTALLPATH)/libethsnarks_common.a.device
	mv $(IOSINSTALLPATH)/libSHA3IUF.a $(IOSINSTALLPATH)/libSHA3IUF.a.device
	$(MAKE) ios-build-simulator
	mv $(IOSINSTALLPATH)/libmixer.a $(IOSINSTALLPATH)/libmixer.a.simulator
	mv $(IOSINSTALLPATH)/libff.a $(IOSINSTALLPATH)/libff.a.simulator
	mv $(IOSINSTALLPATH)/libethsnarks_common.a $(IOSINSTALLPATH)/libethsnarks_common.a.simulator
	mv $(IOSINSTALLPATH)/libSHA3IUF.a $(IOSINSTALLPATH)/libSHA3IUF.a.simulator
	lipo -create -output $(IOSINSTALLPATH)/libmixer.a $(IOSINSTALLPATH)/libmixer.a.{device,simulator}
	lipo -create -output $(IOSINSTALLPATH)/libff.a $(IOSINSTALLPATH)/libff.a.{device,simulator}
	lipo -create -output $(IOSINSTALLPATH)/libethsnarks_common.a $(IOSINSTALLPATH)/libethsnarks_common.a.{device,simulator}
	lipo -create -output $(IOSINSTALLPATH)/libSHA3IUF.a $(IOSINSTALLPATH)/libSHA3IUF.a.{device,simulator}
	rm $(IOSINSTALLPATH)/lib*.a.*
