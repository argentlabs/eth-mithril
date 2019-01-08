#include "gadgets/isnonzero.hpp"
#include "utils.hpp"

using namespace ethsnarks;


bool test_zerop(FieldT value, FieldT expected_result)
{
    ProtoboardT pb;
    VariableT X(make_variable(pb, value, "X"));

    IsNonZero the_gadget(pb, X, "ZeroP");
    the_gadget.generate_r1cs_constraints();
    the_gadget.generate_r1cs_witness();

    const auto result = pb.val(the_gadget.result());

    if( result != expected_result ) {
        std::cerr << "Expected result not actual result" << std::endl;
        return false;
    }

    return pb.is_satisfied();
}


int main( void )
{
    ppT::init_public_params();

    if( ! test_zerop(FieldT::zero(), FieldT::zero()) ) {
        std::cerr << "ZeroP(0) != 1" << std::endl;
        return 1;
    }

    if( ! test_zerop(FieldT::one(), FieldT::one()) ) {
        std::cerr << "ZeroP(1) != 0" << std::endl;
        return 1;
    }

    if( ! test_zerop(FieldT::zero() - FieldT::one(), FieldT::one()) ) {
        std::cerr << "ZeroP(-1) != 0" << std::endl;
        return 1;
    }

    std::cout << "OK" << std::endl;
    return 0;
}
