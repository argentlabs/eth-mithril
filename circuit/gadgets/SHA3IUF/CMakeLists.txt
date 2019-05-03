cmake_minimum_required(VERSION 2.8)

option(
  SHA3_USE_KECCAK
  "Use the Keccak variant, 0x6 rather than 0x1 for padding prefix"
  ON
)

option(SHA3IUF_DISABLE_TESTS "Disable SHA3IUF tests")

add_library(SHA3IUF STATIC ${CMAKE_CURRENT_SOURCE_DIR}/sha3.c)
target_include_directories(SHA3IUF PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

if(${SHA3_USE_KECCAK})
	target_compile_definitions(SHA3IUF PRIVATE SHA3_USE_KECCAK=1)
	target_compile_definitions(SHA3IUF PUBLIC SHA3_USE_KECCAK=1)
	add_definitions(-DSHA3_USE_KECCAK=1)
endif()

add_executable(sha3sum ${CMAKE_CURRENT_SOURCE_DIR}/sha3sum.c)
target_link_libraries(sha3sum SHA3IUF)

include(CTest)
enable_testing()

if(NOT ${SHA3IUF_DISABLE_TESTS})
	add_executable(sha3test ${CMAKE_CURRENT_SOURCE_DIR}/sha3test.c)
	target_link_libraries(sha3test SHA3IUF)
	add_test(NAME run_sha3test COMMAND sha3test)
endif()
