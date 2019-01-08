#ifndef JUBJUB_EDDSA_HPP_
#define JUBJUB_EDDSA_HPP_

// Copyright (c) 2018 @HarryR
// License: LGPL-3.0+

#include "ethsnarks.hpp"

#include "gadgets/field2bits_strict.hpp"

#include "jubjub/params.hpp"
#include "jubjub/validator.hpp"
#include "jubjub/point.hpp"
#include "jubjub/pedersen_hash.hpp"
#include "jubjub/scalarmult.hpp"
#include "jubjub/fixed_base_mul.hpp"
#include "jubjub/adder.hpp"

#include <libsnark/gadgetlib1/gadgets/basic_gadgets.hpp>


namespace ethsnarks {

namespace jubjub {


class EdDSA_HashRAM_gadget : public GadgetT
{
public:
    field2bits_strict m_R_x_bits;           // R_x_bits = BITS(R.x)
    field2bits_strict m_A_x_bits;           // A_x_bits = BITS(A.x)
    const VariableArrayT m_RAM_bits;
    PedersenHashToBits m_hash_RAM;          // hash_RAM = H(R, A, M)

    EdDSA_HashRAM_gadget(
        ProtoboardT& in_pb,
        const Params& in_params,
        const VariablePointT& in_R,
        const VariablePointT& in_A,
        const VariableArrayT& in_M,
        const std::string& annotation_prefix
    );

    void generate_r1cs_constraints();

    void generate_r1cs_witness();

    const VariableArrayT& result();
};


class PureEdDSA_Verify : public GadgetT
{
public:
    PointValidator m_validator_R;           // IsValid(R)
    fixed_base_mul m_lhs;                   // lhs = B*s
    EdDSA_HashRAM_gadget m_hash_RAM;        // hash_RAM = H(R,A,M)
    ScalarMult m_At;                        // A*hash_RAM
    PointAdder m_rhs;                       // rhs = R + (A*hash_RAM)

    PureEdDSA_Verify(
        ProtoboardT& in_pb,
        const Params& in_params,
        const EdwardsPoint& in_base,    // B
        const VariablePointT& in_A,      // A
        const VariablePointT& in_R,      // R
        const VariableArrayT& in_s,      // s
        const VariableArrayT& in_msg,    // m
        const std::string& annotation_prefix);

    void generate_r1cs_constraints();

    void generate_r1cs_witness();
};


class EdDSA_Verify
{
public:
    PedersenHashToBits m_msg_hashed;        // M = H(m)

    PureEdDSA_Verify m_verifier;

    EdDSA_Verify(
        ProtoboardT& in_pb,
        const Params& in_params,
        const EdwardsPoint& in_base,    // B
        const VariablePointT& in_A,      // A
        const VariablePointT& in_R,      // R
        const VariableArrayT& in_s,      // s
        const VariableArrayT& in_msg,    // m
        const std::string& annotation_prefix);

    void generate_r1cs_constraints();

    void generate_r1cs_witness();
};


// namespace jubjub
}

// namespace ethsnarks
}

// JUBJUB_EDDSA_HPP_
#endif
