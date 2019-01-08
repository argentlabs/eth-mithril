#ifndef ETHSNARKS_LOOKUP_2BIT_HPP_
#define ETHSNARKS_LOOKUP_2BIT_HPP_

// Copyright (c) 2018 HarryR
// License: LGPL-3.0+

#include "ethsnarks.hpp"

namespace ethsnarks {


void lookup_2bit_constraints( ProtoboardT& pb, const std::vector<FieldT> c, const VariableArrayT b, const VariableT r, const std::string& annotation_prefix );


/**
* Two-bit window lookup table using one constraint
* Maps the bits `b` to a list of constants `c`
*/
class lookup_2bit_gadget : public GadgetT
{
public:
    const std::vector<FieldT> c;
    const VariableArrayT b;
    VariableT r;

    lookup_2bit_gadget(
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

// ETHSNARKS_LOOKUP_2BIT_HPP_
#endif
