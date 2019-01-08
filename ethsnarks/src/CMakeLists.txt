include_directories(.)


add_library(ethsnarks_common STATIC export.cpp import.cpp stubs.cpp utils.cpp)
target_link_libraries(ethsnarks_common ff)
target_include_directories(ethsnarks_common PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

add_library(hashpreimage SHARED mod/hashpreimage.cpp)
target_link_libraries(hashpreimage ethsnarks_gadgets)
set_property(TARGET hashpreimage PROPERTY POSITION_INDEPENDENT_CODE ON)

add_executable(hashpreimage_cli hashpreimage_cli.cpp)
target_link_libraries(hashpreimage_cli ethsnarks_gadgets)


add_executable(verify verify.cpp)
target_link_libraries(verify ethsnarks_gadgets)


add_subdirectory(test)
add_subdirectory(r1cs_gg_ppzksnark_zok)
add_subdirectory(gadgets)
add_subdirectory(jubjub)
add_subdirectory(pinocchio)
