#ifndef LONGSIGHTL_HPP_
#define LONGSIGHTL_HPP_

#include <libsnark/gadgetlib1/gadgets/basic_gadgets.hpp>

#include "ethsnarks.hpp"
#include "longsightl_constants.hpp"
#include "onewayfunction.hpp"

namespace ethsnarks {

class LongsightL_round : public GadgetT
{
public:
    const VariableT var_input_x;
    const VariableT var_input_k;
    const FieldT round_constant;

    VariableT var_sq2;      // n^2
    VariableT var_sq4;      // n^4
    VariableT var_output;   // n^5

    LongsightL_round(
        ProtoboardT &in_pb,
        const VariableT &in_x,
        const VariableT &in_k,
        const FieldT in_constant,
        const std::string &in_annotation_prefix=""
    );

    void generate_r1cs_constraints();

    void generate_r1cs_witness();

    const VariableT& result() const;
};


class LongsightL_gadget : public GadgetT
{
public:
    std::vector<LongsightL_round> m_rounds;
    const std::vector<FieldT> m_constants;

    const VariableT start_x;
    const VariableT key;
    VariableT output_y;

    LongsightL_gadget(
        ProtoboardT &in_pb,
        const std::vector<FieldT> &in_constants,
        const VariableT in_x,
        const VariableT in_k,
        const std::string &in_annotation_prefix=""
    );

    const VariableT& result() const;

    void generate_r1cs_constraints();

    void generate_r1cs_witness();
};


class LongsightL12p5_gadget : public LongsightL_gadget
{
public:
    LongsightL12p5_gadget(
        ProtoboardT &in_pb,
        const VariableT &in_x,
        const VariableT &in_k,
        const std::string &in_annotation_prefix=""
    ) :
        LongsightL_gadget(in_pb, LongsightL12p5_constants_assign(), in_x, in_k, in_annotation_prefix)
    {
    }
};


class LongsightL12p5_MP_gadget : public MiyaguchiPreneel_OWF<LongsightL12p5_gadget>
{
public:
    LongsightL12p5_MP_gadget(
        ProtoboardT &in_pb,
        VariableT in_IV,
        std::vector<VariableT> in_messages,
        const std::string &in_annotation_prefix=""
    ) :
        MiyaguchiPreneel_OWF(in_pb, in_IV, in_messages, FMT(in_annotation_prefix, ".MP_OWF"))
    {

    }
};

// ethsnarks
}


#endif
