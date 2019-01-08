add_library(ethsnarks_pinocchio STATIC
	circuit_reader.cpp
)
target_link_libraries(ethsnarks_pinocchio ethsnarks_common)

add_executable(pinocchio main.cpp)
target_link_libraries(pinocchio ethsnarks_pinocchio)


add_executable(jsnark_test jsnark_test.cpp)
target_link_libraries(jsnark_test ethsnarks_pinocchio)
