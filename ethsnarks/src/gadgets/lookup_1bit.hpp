#ifndef ETHSNARKS_LOOKUP_1BIT_HPP_
#define ETHSNARKS_LOOKUP_1BIT_HPP_

// Copyright (c) 2018 HarryR
// License: LGPL-3.0+

#include "ethsnarks.hpp"

namespace ethsnarks {


void lookup_1bit_constraints( ProtoboardT& pb, const std::vector<FieldT> c, const VariableT bit, const VariableT r, const std::string& annotation_prefix );


/**
* One-bit window lookup table using one constraint
*/
class lookup_1bit_gadget : public GadgetT
{
public:
    const std::vector<FieldT> c;
    const VariableT b;
    VariableT r;

    lookup_1bit_gadget(
        ProtoboardT &in_pb,
        const std::vector<FieldT> in_constants,
        const VariableT in_bit,
        const std::string& annotation_prefix
    );

    const VariableT& result();

    void generate_r1cs_constraints();

    void generate_r1cs_witness ();
};

// namespace ethsnarks
}

// ETHSNARKS_LOOKUP_1BIT_HPP_
#endif
