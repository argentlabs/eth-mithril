#ifndef JUBJUB_VALIDATOR_HPP_
#define JUBJUB_VALIDATOR_HPP_

// Copyright (c) 2018 @HarryR
// License: LGPL-3.0+

#include "ethsnarks.hpp"
#include "jubjub/isoncurve.hpp"
#include "jubjub/notloworder.hpp"


namespace ethsnarks {
    
namespace jubjub {


/**
* Validates a curve point, ensures that it is:
*  - Is on the curve
*  - Not of low-order
*/
class PointValidator : public GadgetT {
public:
    NotLowOrder m_notloworder;
    IsOnCurve m_isoncurve;

    PointValidator(
        ProtoboardT& in_pb,
        const Params& in_params,
        const VariableT in_X,
        const VariableT in_Y,
        const std::string& annotation_prefix);

    void generate_r1cs_constraints();

    void generate_r1cs_witness();
};


// namespace jubjub
}

// namespace ethsnarks
}


// JUBJUB_POINTVALIDATOR_HPP_
#endif
