file(GLOB test_sources "*.cpp")

foreach(test_path ${test_sources})
	get_filename_component(test_name ${test_path} NAME)
	string(REPLACE ".cpp" "" test_executable ${test_name})
	add_executable(${test_executable} ${test_name})
	target_link_libraries(${test_executable} ethsnarks_jubjub)
	add_test(NAME run_${test_executable} COMMAND ${test_executable})
endforeach()
