#ifndef ETHSNARKS_LOOKUP_3BIT_HPP_
#define ETHSNARKS_LOOKUP_3BIT_HPP_

// Copyright (c) 2018 HarryR
// License: LGPL-3.0+

#include "ethsnarks.hpp"

namespace ethsnarks {


class lookup_3bit_gadget : public GadgetT
{
public:
    const std::vector<FieldT> c;
    const VariableArrayT b;
    VariableT r;

    // Bit-field selectors
    const VariableT precomp01;
    const VariableT precomp02;
    const VariableT precomp12;;
    const VariableT precomp012;

    lookup_3bit_gadget(
        ProtoboardT &in_pb,
        const std::vector<FieldT> in_constants,
        const VariableArrayT in_bits,
        const std::string& annotation_prefix
    );

    const VariableT& result();

    void generate_r1cs_constraints();

    void generate_r1cs_witness ();
};


// namespace ethsnarks
}

// ETHSNARKS_LOOKUP_3BIT_HPP_
#endif
