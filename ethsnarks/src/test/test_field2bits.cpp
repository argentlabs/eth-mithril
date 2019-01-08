#include "gadgets/field2bits_strict.hpp"
#include "utils.hpp"


namespace ethsnarks
{

bool test_field2bits( const FieldT& value, const bool expected_result )
{
	ProtoboardT pb;
	const auto var = make_variable(pb, value, "var");

	field2bits_strict the_gadget(pb, var, "the_gadget");
	the_gadget.generate_r1cs_constraints();
	the_gadget.generate_r1cs_witness();

	return pb.is_satisfied() == expected_result;
}


bool testcases_field2bits( void )
{
	struct Field2BitsTestCase {
		FieldT value;
		bool expected;
	};

	const std::vector<Field2BitsTestCase> test_cases = {
		{FieldT::zero(), true},
		{FieldT::one(), true},
		{FieldT::zero() - FieldT::one(), true}
	};

	size_t i = 0;
	for( const auto& test_case : test_cases )
	{
		if( ! test_field2bits(test_case.value, test_case.expected) ) {
			std::cerr << "Test case " << i << std::endl;
			return false;
		}
		i += 1;
	}

	return true;
}


// namespace ethsnarks
}


int main( int argc, char **argv )
{
    // Types for board
    ethsnarks::ppT::init_public_params();

    if( ! ethsnarks::testcases_field2bits() )
    {
        std::cerr << "FAIL" << std::endl;
        return 1;
    }

    std::cout << "OK\n";
    return 0;
}
