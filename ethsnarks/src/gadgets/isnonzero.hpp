#ifndef ETHSNARKS_ZEROP_HPP_
#define ETHSNARKS_ZEROP_HPP_

#include "ethsnarks.hpp"


namespace ethsnarks {

/**
* Generalised boolean, returns true if number is non-zero, otherwise false
*/
class IsNonZero : public GadgetT {
public:
    // Input variable
    const VariableT m_X;

    // Result variable
    const VariableT m_Y;

    // 1/X
    const VariableT m_M;

    IsNonZero(
        ProtoboardT& in_pb,
        const VariableT& in_var,
        const std::string &annotation_prefix);

    const VariableT& result() const;

    void generate_r1cs_constraints();

    void generate_r1cs_witness();
};

// namespace ethsnarks
}

// ETHSNARKS_ZEROP_HPP_
#endif
