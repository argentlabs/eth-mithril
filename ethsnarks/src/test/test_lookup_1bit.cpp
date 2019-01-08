#include "ethsnarks.hpp"
#include "utils.hpp"
#include "stubs.hpp"
#include "gadgets/lookup_1bit.hpp"

namespace ethsnarks {

bool test_lookup_1bit()
{
    ProtoboardT pb;

    const std::vector<FieldT> rand_items = {
        FieldT::random_element(), FieldT::random_element()
    };

    std::vector<VariableT> items;
    std::vector<lookup_1bit_gadget> gadgets;

    for( size_t i = 0; i < rand_items.size(); i++ )
    {
        items.emplace_back( );
        items[i].allocate(pb, FMT("items.", "%d", i));
        pb.val(items[i]) = FieldT(i);

        gadgets.emplace_back( pb, rand_items, items[i], FMT("the_gadget.", "%d", i) );
        gadgets[i].generate_r1cs_witness();
        gadgets[i].generate_r1cs_constraints();

        if( ! pb.is_satisfied() ) {
            std::cerr << "Not satisfied " << i << std::endl;
        }
    }

    if( ! pb.is_satisfied() ) {
        std::cerr << "Not satisfied!\n";
        return false;
    }

    return stub_test_proof_verify(pb);
}

// namespace ethsnarks
}


int main( int argc, char **argv )
{
    // Types for board
    ethsnarks::ppT::init_public_params();

    if( ! ethsnarks::test_lookup_1bit() )
    {
        std::cerr << "FAIL\n";
        return 1;
    }

    std::cout << "OK\n";
    return 0;
}