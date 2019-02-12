cmake_minimum_required(VERSION 3.8)
project(argent-mixer C CXX)

if (IOS_BUILD)
    set(CMAKE_INSTALL_PREFIX  ../ios/iOSProver/depends)
    set(PKG_CONFIG_EXECUTABLE /usr/local/bin/pkg-config)
    set(OPENSSL_INCLUDE_DIR /usr/local/include)
    set(OPENSSL_CRYPTO_LIBRARY /usr/local/opt/openssl/lib/libcrypto.dylib)
    set(GMP_INCLUDE_DIR /usr/local/include)
    set(GMPXX_INCLUDE_DIR /usr/local/include)
    set(GMP_LIBRARY ${CMAKE_INSTALL_PREFIX}/lib/libgmp.dylib)
    set(GMPXX_LIBRARY ${CMAKE_INSTALL_PREFIX}/lib/libgmpxx.dylib)
endif()

add_subdirectory(../ethsnarks ../.build/ethsnarks EXCLUDE_FROM_ALL)

add_library(mixer SHARED mixer.cpp)
target_link_libraries(mixer ethsnarks_common)
set_property(TARGET mixer PROPERTY POSITION_INDEPENDENT_CODE ON)

if (IOS_BUILD)
    install (TARGETS mixer DESTINATION lib)
    install (FILES mixer.hpp DESTINATION include)
    install (FILES ../.keys/mixer.pk.raw DESTINATION data)
else()
    add_executable(mixer_cli mixer_cli.cpp)
    target_link_libraries(mixer_cli ethsnarks_common)
endif()

