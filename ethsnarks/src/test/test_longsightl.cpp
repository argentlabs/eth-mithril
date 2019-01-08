// Copyright (c) 2018 HarryR
// License: LGPL-3.0+


#include "gadgets/longsightl.hpp"

using ethsnarks::ppT;
using ethsnarks::FieldT;
using ethsnarks::ProtoboardT;
using ethsnarks::VariableT;
using ethsnarks::LongsightL_gadget;
using ethsnarks::LongsightL12p5_constants_fill;

bool test_LongsightL()
{
    std::vector<FieldT> round_constants;
    LongsightL12p5_constants_fill(round_constants);

    ProtoboardT pb;

    VariableT in_x;
    VariableT in_k;

    in_x.allocate(pb, "in_x");
    pb.val(in_x) = FieldT("3703141493535563179657531719960160174296085208671919316200479060314459804651");

    in_k.allocate(pb, "in_k");
    pb.val(in_k) = FieldT("134551314051432487569247388144051420116740427803855572138106146683954151557");

    LongsightL_gadget the_gadget(pb, round_constants, in_x, in_k);
    the_gadget.generate_r1cs_witness();
    the_gadget.generate_r1cs_constraints();

    pb.set_input_sizes(2);

    auto result_expected = FieldT("14412061461933611701703094472891440142598479500786943729495502117590964244418");
    if( result_expected != pb.val(the_gadget.result()) ) {
        std::cerr << "Unexpected result!\n";
        return false;
    }

    std::cout << pb.num_constraints() << " constraints" << std::endl;

    return pb.is_satisfied();
}


int main( int argc, char **argv )
{
    // Types for board
    ppT::init_public_params();

    if( ! test_LongsightL() )
    {
        std::cerr << "FAIL\n";
        return 1;
    }

    std::cout << "OK\n";
    return 0;
}
