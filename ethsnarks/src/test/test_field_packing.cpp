#include <cstdlib>
#include <cstring>

#include <libff/algebra/fields/field_utils.hpp>
#include <libsnark/gadgetlib1/gadgets/hashes/sha256/sha256_components.hpp>  // digest size

#include "utils.hpp"
#include "ethsnarks.hpp"

#include <openssl/sha.h>

using ethsnarks::ppT;
using ethsnarks::FieldT;
using ethsnarks::bytes_to_bv;


/**
* Fill buffer of N x 32 bytes with the SHA256 hash of the reference string
*/
unsigned char *fill_words( size_t n_words, const char *refstr, size_t *buffer_sz )
{
	*buffer_sz = (libsnark::SHA256_digest_size / 8) * n_words;
	unsigned char *buffer = (decltype(buffer))::malloc(*buffer_sz);
	unsigned char *bufout = buffer;
	size_t reflen = ::strlen(refstr);
	SHA256_CTX ctx;

	for( size_t i = 0; i < n_words; i++ )
	{
		SHA256_Init(&ctx);
        SHA256_Update(&ctx, refstr, reflen);
        SHA256_Final(bufout, &ctx);
        bufout += (libsnark::SHA256_digest_size / 8);
	}

	return buffer;
}


void test_packing_bytes_to_field( int n_words, const char *refstr )
{
	size_t buffer_sz;
	auto buffer = fill_words(n_words, refstr, &buffer_sz);

	const auto buffer_bv = bytes_to_bv(buffer, buffer_sz);

	const auto buffer_fields = libff::pack_bit_vector_into_field_element_vector<FieldT>(buffer_bv);

	::printf("%d words, refstr: '%s'\n", n_words, refstr);
	for( auto& f : buffer_fields )
	{
		std::cout << "\t" << f << "\n";
	}
	::printf("\n\n");

	::free(buffer);
}

int main( int argc, char **argv )
{
	// Types for board
	ppT::init_public_params();

	char refstr[100];

	for( int i = 0; i < 21; i++ )
	{
		::sprintf(refstr, "test%d", i);
		test_packing_bytes_to_field(i, refstr);
	}

	return 0;
}