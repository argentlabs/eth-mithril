// Copyright (c) 2018 HarryR
// License: LGPL-3.0+

#include "gadgets/one_of_n.cpp"
#include "stubs.hpp"


namespace ethsnarks
{

bool test_one_of_n()
{
    ProtoboardT pb;

    const std::vector<FieldT> rand_items = {
        FieldT::random_element(), FieldT::random_element(),
        FieldT::random_element(), FieldT::random_element(),
        FieldT::random_element(), FieldT::random_element(),
        FieldT::random_element(), FieldT::random_element(),
        FieldT::random_element(), FieldT::random_element()
    };

    // Allocate items first
    VariableArrayT in_items;    
    in_items.allocate(pb, rand_items.size(), "in_items");
    in_items.fill_with_field_elements(pb, rand_items);

    // Our item comes afterwards, is a private input
    VariableT in_our_item;
    in_our_item.allocate(pb, "our_item");
    pb.val(in_our_item) = rand_items[3];

    // Setup gadget
    ethsnarks::one_of_n the_gadget(pb, in_our_item, in_items);
    the_gadget.generate_r1cs_witness();
    the_gadget.generate_r1cs_constraints();
    pb.set_input_sizes(rand_items.size());

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

    if( ! ethsnarks::test_one_of_n() )
    {
        std::cerr << "FAIL\n";
        return 1;
    }

    std::cout << "OK\n";
    return 0;
}
