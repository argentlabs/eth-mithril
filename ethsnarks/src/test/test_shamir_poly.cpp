// Copyright (c) 2018 HarryR
// License: LGPL-3.0+

#include <libff/algebra/curves/alt_bn128/alt_bn128_pp.hpp>

#include "gadgets/shamir_poly.cpp"

#include "r1cs_gg_ppzksnark_zok/r1cs_gg_ppzksnark_zok.hpp"


using libsnark::r1cs_gg_ppzksnark_zok_generator;
using libsnark::r1cs_gg_ppzksnark_zok_prover;
using libsnark::r1cs_gg_ppzksnark_zok_verifier_strong_IC;


template<typename ppT>
bool test_shamirs_poly()
{
    typedef libff::Fr<ppT> FieldT;

    protoboard<FieldT> pb;

    auto rand_input = FieldT::random_element();
    std::vector<FieldT> rand_alpha = {
        FieldT::random_element(), FieldT::random_element(),
        FieldT::random_element(), FieldT::random_element()
    };

    pb_variable<FieldT> in_input;
    pb_variable_array<FieldT> in_alpha;

    in_input.allocate(pb, "in_input");
    pb.val(in_input) = rand_input;

    in_alpha.allocate(pb, rand_alpha.size(), "in_alpha");
    in_alpha.fill_with_field_elements(pb, rand_alpha);

    shamir_poly<FieldT> the_gadget(pb, in_input, in_alpha);

    the_gadget.generate_r1cs_witness();

    the_gadget.generate_r1cs_constraints();

    pb.set_input_sizes(1);

    if( ! pb.is_satisfied() ) {
        std::cerr << "Not satisfied!\n";
        return false;
    }

    auto constraints = pb.get_constraint_system();

    std::cout << "Setup keypair\n";
    auto keypair = r1cs_gg_ppzksnark_zok_generator<ppT>(constraints);

    auto primary_input = pb.primary_input();
    auto auxiliary_input = pb.auxiliary_input();
    auto proof = r1cs_gg_ppzksnark_zok_prover<ppT>(keypair.pk, primary_input, auxiliary_input);
    return r1cs_gg_ppzksnark_zok_verifier_strong_IC <ppT> (keypair.vk, primary_input, proof);
}


int main( int argc, char **argv )
{
    // Types for board
    typedef libff::alt_bn128_pp ppT;    
    ppT::init_public_params();

    if( ! test_shamirs_poly<ppT>() )
    {
        std::cerr << "FAIL\n";
        return 1;
    }

    std::cout << "OK\n";
    return 0;
}
