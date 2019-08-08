ROOT_DIR := $(shell dirname "$(realpath $(lastword $(MAKEFILE_LIST)))")

GMP_VERSION=6.1.2
GMP_DIR=gmp-$(GMP_VERSION)
GMP_TAR=$(GMP_DIR).tar.bz2
GMP_URL=https://ftp.gnu.org/pub/gnu/gmp/$(GMP_TAR)
GMP_MAKE_BINS=$(addprefix $(GMP_DIR)/, gen-fib gen-fac gen-bases gen-trialdivtab gen-jacobitab gen-psqr)

FASTCOMP = emsdk/fastcomp

OS := $(shell uname)


#######################################################################


all: emscripten gmp ethsnarks

installroot:
	mkdir -p $@

build:
	mkdir -p $@

example-server:
	php -t example -S 127.0.0.1:3333

clean:
	rm -rf build build.emscripten gmp-*


#######################################################################
# emscripten

emscripten: $(FASTCOMP)/emscripten/emcc

ifeq ($(OS), Darwin)
emscripten: $(FASTCOMP)/bin/llvm-ar.old $(FASTCOMP)/fastcomp/bin/llvm-ar.old

$(FASTCOMP)/bin/llvm-ar.old: $(FASTCOMP)/bin/llvm-ar
	cd $(dir $@) && mv llvm-ar llvm-ar.old && ln -s /usr/local/opt/llvm/bin/llvm-ar llvm-ar

$(FASTCOMP)/fastcomp/bin/llvm-ar.old: $(FASTCOMP)/fastcomp/bin/llvm-ar
	cd $(dir $@) && mv llvm-ar llvm-ar.old && ln -s /usr/local/opt/llvm/bin/llvm-ar llvm-ar
endif

.PHONY: $(FASTCOMP)/emscripten/emcc
$(FASTCOMP)/emscripten/emcc:
	./emsdk/emsdk install latest
	./emsdk/emsdk activate latest


#######################################################################
# ethsnarks

ethsnarks-patches:
	cd $(ROOT_DIR)/../ethsnarks/depends/libsnark/depends/libff && patch -Ntp1 < $(ROOT_DIR)/libff.patch || true

ethsnarks: build.emscripten/mixer_cli.js

cmake-patch:
	sed -i.bak -e 's/$$$$Browser/$$Browser/' ./build/CMakeFiles/mixer_js.dir/link.txt

build.emscripten/mixer_cli.js: build/cmake_install.cmake cmake-patch
	make -C build mixer_cli mixer_js mixer_selftest
	cp build.emscripten/mixer_js.* example/

build/cmake_install.cmake: build ethsnarks-patches
	cd build && emcmake cmake -DCMAKE_BUILD_TYPE=Release .. -DWITH_PROCPS=OFF -DPKG_CONFIG_USE_CMAKE_PREFIX_PATH=ON -DCMAKE_PREFIX_PATH=`pwd`/../installroot/ 


#######################################################################
# GMP

gmp-bins: $(GMP_MAKE_BINS)

.PHONY: gmp
gmp: installroot/lib/libgmp.a

installroot/lib/libgmp.a: installroot $(GMP_DIR) $(GMP_MAKE_BINS) $(GMP_DIR)/Makefile
	make -C $(GMP_DIR) -j 2
	make -C $(GMP_DIR) install

$(GMP_DIR)/Makefile: $(GMP_DIR)
	cd $< && sed -i.bak -e 's/^# Only do the GMP_ASM .*/gmp_asm_syntax_testing=no/' configure.ac && autoconf
	cd $< && emcmake ./configure ABI=standard CFLAGS="-O3" --prefix=`pwd`/../installroot/ --host=none --disable-assembly --disable-shared || cat config.log

$(GMP_DIR): $(GMP_TAR)
	tar -xf $<

$(GMP_TAR):
	curl -L -o $@ $(GMP_URL)

$(GMP_DIR)/gen-fib: $(GMP_DIR)/gen-fib.c

$(GMP_DIR)/gen-fac: $(GMP_DIR)/gen-fac.c

$(GMP_DIR)/gen-bases: $(GMP_DIR)/gen-bases.c

$(GMP_DIR)/gen-trialdivtab: $(GMP_DIR)/gen-trialdivtab.c

$(GMP_DIR)/gen-jacobitab: $(GMP_DIR)/gen-jacobitab.c

$(GMP_DIR)/gen-psqr: $(GMP_DIR)/gen-psqr.c
