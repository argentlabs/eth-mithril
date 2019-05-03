add_library(SHA3IUF STATIC SHA3IUF/sha3.c)
target_include_directories(SHA3IUF PUBLIC SHA3IUF)
target_compile_definitions(SHA3IUF PRIVATE SHA3_USE_KECCAK=1)