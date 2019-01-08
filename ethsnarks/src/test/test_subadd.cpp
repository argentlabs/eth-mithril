#include "gadgets/subadd.hpp"
#include "utils.hpp"

using namespace ethsnarks;


bool test_subadd( FieldT A, FieldT B, FieldT N, size_t n_bits, bool expected, const std::string& test_name )
{
	ProtoboardT pb;

	VariableT v_A = make_variable(pb, A, "A");
	VariableT v_B = make_variable(pb, B, "B");
	VariableT v_N = make_variable(pb, N, "N");

	subadd_gadget the_gadget(pb, n_bits, v_A, v_B, v_N, test_name);
	the_gadget.generate_r1cs_constraints();
	the_gadget.generate_r1cs_witness();

	std::cout << test_name << " = " << pb.num_constraints() << " constraints" << std::endl;

	if( pb.is_satisfied() != expected ) {
		std::cerr << "FAIL " << test_name << std::endl;
		return false;
	}

	return true;
}


int main( void )
{
	bool result = true;

	// Types for board
    ppT::init_public_params();

	result &= test_subadd(1, 0, 1, 1, true, "1-bit good");
	result &= test_subadd(0, 0, 1, 1, false, "1-bit bad (underflow)");

	result &= test_subadd(255, 0, 0, 8, true, "8-bit good");
	result &= test_subadd(255, 128, 128, 8, false, "8-bit bad (overflow)");
	result &= test_subadd(255, 128, 127, 8, true, "8-bit good (max)");
	result &= test_subadd(127, 0, 127, 8, true, "8-bit good (zero)");
	result &= test_subadd(127, 0, 128, 8, false, "8-bit bad (underflow)");

	for( size_t i = 8; i < 253; i++ ) {
		result &= test_subadd(110, 100, 105, i, true, FMT("", "%zubit good", i));
	}

	if( ! result ) {
		return 1;
	}
	return 0;
}
