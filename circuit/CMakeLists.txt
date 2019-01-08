cmake_minimum_required(VERSION 3.8)
project(argent-mixer)
add_subdirectory(../ethsnarks ../.build/ethsnarks EXCLUDE_FROM_ALL)

add_library(mixer SHARED mixer.cpp)
target_link_libraries(mixer ethsnarks_common)
set_property(TARGET mixer PROPERTY POSITION_INDEPENDENT_CODE ON)

add_executable(mixer_cli mixer_cli.cpp)
target_link_libraries(mixer_cli ethsnarks_common)
