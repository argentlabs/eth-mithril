#include <libff/algebra/curves/alt_bn128/alt_bn128_pp.hpp>

#include "gadgets/sha256_full.cpp"
#include "utils.hpp"


#include <openssl/sha.h>
#include <openssl/rand.h>

using libsnark::digest_variable;
using libsnark::block_variable;
using libsnark::SHA256_digest_size;
using libsnark::SHA256_block_size;

using ethsnarks::ppT;

namespace ethsnarks {

/**
* Verifies that the SHA256_full gadget matches a reference implementation
*
* Runs SHA256_Update with a full block
* Verifies that the state matches
*
* TODO:
*  - Flip bits in Witness
*  - Flip bits in left/right
*  - all flip options toggleable
*/
bool test_sha256_full_gadget()
{
    // Create a block_size'd buffer of random bytes
    SHA256_CTX ctx;
    SHA256_Init(&ctx);
    uint8_t input_buffer[SHA256_block_size_bytes];
    uint8_t output_digest[SHA256_digest_size_bytes];
    assert( SHA256_block_size / 2 == SHA256_digest_size );

    // Perform full round of SHA256 using the test vector
    SHA256_Init(&ctx);
    SHA256_Update(&ctx, "test", 4);
    SHA256_Final(input_buffer, &ctx);
    memcpy(&input_buffer[SHA256_digest_size_bytes], input_buffer, SHA256_digest_size_bytes);
    // 9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a089f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08'

    // Then verify the result is as expected
    // sha256(sha256('test').digest() + sha256('test').digest()).digest()
    SHA256_Init(&ctx);
    SHA256_Update(&ctx, input_buffer, sizeof(input_buffer));    
    SHA256_Final(output_digest, &ctx);
    uint8_t output_expected[] = {
        0xD2, 0x94, 0xF6, 0xE5, 0x85, 0x87, 0x4F, 0xE6,
        0x40, 0xBE, 0x4C, 0xE6, 0x36, 0xE6, 0xEF, 0x9E,
        0x3A, 0xDC, 0x27, 0x62, 0x0A, 0xA3, 0x22, 0x1F,
        0xDC, 0xF5, 0xC0, 0xA7, 0xC1, 0x1C, 0x6F, 0x67};
    if( memcmp(output_digest, output_expected, sizeof(output_digest)) != 0 ) {
        printf("output_digest mismatch!\n");
        return false;
    }

    // ----------------------------------------------------------------
    // Setup circuit to do full_output = SHA256(left, right)

    ProtoboardT pb;

    // split the input buffer into the right & left components
    digest_variable<FieldT> left(pb, SHA256_digest_size, "left");
    digest_variable<FieldT> right(pb, SHA256_digest_size, "right");

    const libff::bit_vector left_bv = bytes_to_bv(input_buffer, SHA256_digest_size_bytes);
    const libff::bit_vector right_bv = bytes_to_bv(&input_buffer[SHA256_digest_size_bytes], SHA256_digest_size_bytes);

    left.generate_r1cs_witness(left_bv);
    right.generate_r1cs_witness(right_bv);

    // Then run a full SHA256 round, via R1CS SNARK circuit
    block_variable<FieldT> full_input(pb, left, right, "full_input");
    digest_variable<FieldT> full_output(pb, SHA256_digest_size, "full_output");
    sha256_full_gadget_512 full_gadget(pb, full_input, full_output, "full_gadget");

    full_gadget.generate_r1cs_constraints();
    full_gadget.generate_r1cs_witness();

    // ----------------------------------------------------------------    

    // Binds circuit satisfiability to whether or not the full output
    // matches what was computed by OpenSSL's SHA256
    auto output_digest_bits = bytes_to_bv(output_digest, SHA256_digest_size_bytes);
	full_output.generate_r1cs_witness(output_digest_bits);

    // Verify the result matches what we computed
    auto full_output_bits = full_output.get_digest();
    uint8_t full_output_bytes[SHA256_digest_size_bytes];
    bv_to_bytes(full_output_bits, full_output_bytes);
    if( memcmp(full_output_bytes, output_digest, SHA256_digest_size_bytes) != 0 ) {
        std::cout << "full_output_bytes mismatch" << std::endl;
        print_bytes("Expected: ", SHA256_digest_size_bytes, output_digest);
        print_bytes("Actual: ", SHA256_digest_size_bytes, full_output_bytes);
        return false;
    }

	// Show the two, as bits, side-by-side
    print_bv("full (r1cs)", full_output_bits);
    print_bv("full (SHA2)", output_digest_bits);

    std::cout << "Constraints: " << pb.num_constraints() << "\n";
    std::cout << "Variables: " << pb.num_variables() << "\n";
    std::cout << "Inputs: " << pb.num_inputs() << "\n";

    for( auto& var : pb.primary_input() )
    {
        std::cout << "  var " << var << "\n";
    }

    uint8_t output_buffer[SHA256_digest_size_bytes];
    bv_to_bytes(full_output_bits, output_buffer);
    printf("Output digest bytes: ");
    for( uint8_t x : output_buffer )
    {
        printf("%02X", x);
    }
    printf("\n");

    return pb.is_satisfied();
}

// namespace ethsnarks
}

int main( int argc, char **argv )
{
	ppT::init_public_params();

	if( ! ethsnarks::test_sha256_full_gadget() )
	{
		std::cerr << "FAIL\n";
		return 1;
	}

	std::cout << "OK\n";
	return 0;
}
