BUILDPATH = .build
KEYPATH = .keys

all: clean build test

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
	# make -C solidity test