#include "ethsnarks.hpp"

using namespace libsnark;
using namespace libff;

int main( )
{
	bigint<alt_bn128_r_limbs> number_a;
	bigint<alt_bn128_r_limbs> number_b; 

	number_a.randomize();
	number_b.randomize();

	mpz_t result;
	mpz_init(result);

	mpz_t number_a_mpz;
	mpz_init(number_a_mpz);
	number_a.to_mpz(number_a_mpz);

	mpz_t number_b_mpz;
	mpz_init(number_b_mpz);
	number_b.to_mpz(number_b_mpz);

	enter_block("Multiplying with MPZ, 1 million times");

	for( int i = 0; i < 100000000; i++ ) {
		mpz_mul(result, number_a_mpz, number_b_mpz);
	}

	leave_block("Multiplying with MPZ, 1 million times");

	mpz_clear(number_a_mpz);
	mpz_clear(number_b_mpz);
	mpz_clear(result);
}