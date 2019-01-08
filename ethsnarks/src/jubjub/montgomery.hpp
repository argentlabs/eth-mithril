#ifndef JUBJUB_MONTGOMERY_HPP_
#define JUBJUB_MONTGOMERY_HPP_

// Copyright (c) 2018 @fleupold
// License: LGPL-3.0+

#include "ethsnarks.hpp"
#include "jubjub/params.hpp"


namespace ethsnarks {

namespace jubjub {


class MontgomeryAdder : public GadgetT {
public:
    const Params& m_params;

    // First input point
    const LinearCombinationT m_X1;
    const VariableT m_Y1;

    // Second input point
    const LinearCombinationT m_X2;
    const VariableT m_Y2;

    // Intermediate variables
    const VariableT lambda;
    const VariableT m_X3;
    const VariableT m_Y3;

    MontgomeryAdder(
        ProtoboardT& in_pb,
        const Params& in_params,
        const LinearCombinationT in_X1,
        const VariableT in_Y1,
        const LinearCombinationT in_X2,
        const VariableT in_Y2,
        const std::string& annotation_prefix
    );

    const VariableT& result_x() const;

    const VariableT& result_y() const;

    void generate_r1cs_constraints();

    void generate_r1cs_witness();
};


/**
* Gadget to verify the conversion between the Montgomery form 
* of a point and its twisted Edwards form.
*/
class MontgomeryToEdwards : public GadgetT {
public:
    const Params& m_params;
    
    // Input point
    const LinearCombinationT m_X1;
    const VariableT m_Y1;

    // Output point
    const VariableT m_X2;
    const VariableT m_Y2;

    MontgomeryToEdwards(
        ProtoboardT &in_pb,
        const Params& in_params,
        const LinearCombinationT in_X,
        const VariableT in_Y,
        const std::string &annotation_prefix
    );

    const VariableT& result_x() const;
    const VariableT& result_y() const;

    void generate_r1cs_constraints();
    void generate_r1cs_witness();
}; 


// namespace jubjub
}

// namespace ethsnarks
}

// JUBJUB_MONTGOMERY_ADDER_HPP_
#endif
