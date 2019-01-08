add_library(ethsnarks_gadgets STATIC
	longsightl.cpp
	longsightl_constants.cpp

	merkle_tree.cpp

	one_of_n.cpp
	sha256_full.cpp
	sha256_many.cpp
	shamir_poly.cpp

	lookup_1bit.cpp
	lookup_2bit.cpp
	lookup_3bit.cpp
	lookup_signed_3bit.cpp

	subadd.cpp
	isnonzero.cpp
	field2bits_strict.cpp
)
target_link_libraries(ethsnarks_gadgets ethsnarks_common OpenSSL::Crypto)
target_compile_features(ethsnarks_gadgets PUBLIC cxx_std_11)