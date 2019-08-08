# WASM support for Hopper

For OSX, this requires `llvm-ar` at the following path:

 * `/usr/local/opt/llvm/bin/llvm-ar`

This can be installed via Brew, aka `brew install llvm`.

Then, download, install and activate the Emscripten SDK:

```
./emsdk/emsdk install latest
./emsdk/emsdk activate latest
source emsdk/emsdk_env.sh
```

Then perform build by running:

 * `make`
