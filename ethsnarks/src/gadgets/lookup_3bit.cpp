// Copyright (c) 2018 HarryR
// License: LGPL-3.0+

#include "lookup_3bit.hpp"
#include "utils.hpp"


namespace ethsnarks {


lookup_3bit_gadget::lookup_3bit_gadget(
    ProtoboardT &in_pb,
    const std::vector<FieldT> in_constants,
    const VariableArrayT in_bits,
    const std::string& annotation_prefix
) :
    GadgetT(in_pb, annotation_prefix),
    c(in_constants),
    b(in_bits),
    r(make_variable(in_pb, FMT(this->annotation_prefix, ".r"))),
    precomp01(make_variable(in_pb, FMT(this->annotation_prefix, ".precomp01"))),
    precomp02(make_variable(in_pb, FMT(this->annotation_prefix, ".precomp02"))),
    precomp12(make_variable(in_pb, FMT(this->annotation_prefix, ".precomp12"))),
    precomp012(make_variable(in_pb, FMT(this->annotation_prefix, ".precomp012")))
{
    assert( in_constants.size() == 8 );
}


const VariableT& lookup_3bit_gadget::result()
{
    return r;
}


void lookup_3bit_gadget::generate_r1cs_constraints()
{
    this->pb.add_r1cs_constraint(
        ConstraintT(
            b[0], b[1], precomp01
        ), FMT(this->annotation_prefix, ".precomp01"));

    this->pb.add_r1cs_constraint(
        ConstraintT(
            b[0], b[2], precomp02
        ), FMT(this->annotation_prefix, ".precomp02"));

    this->pb.add_r1cs_constraint(
        ConstraintT(
            b[1], b[2], precomp12
        ), FMT(this->annotation_prefix, ".precomp12"));

    this->pb.add_r1cs_constraint(
        ConstraintT(
            precomp01, b[2], precomp012
        ), FMT(this->annotation_prefix, ".precomp012"));

    // Verify 
    this->pb.add_r1cs_constraint(
        ConstraintT(
            // All bits off
            c[0] +

            // Bit 0 is on
            (b[0] * -c[0]) +
            (b[0] * c[1]) +

            // Bit 1 is on
            (b[1] * -c[0]) +
            (b[1] * c[2]) +

            // Bit 0 and 1 are on
            (precomp01 * (-c[1] + -c[2] + c[0] + c[3])) +

            // Bit 2 is 1
            (b[2] * (-c[0] + c[4])) +

            // Bit 0 and 2 are on
            (precomp02 * (c[0] - c[1] -c[4] + c[5])) +

            // Bit 1 and 2 are on
            (precomp12 * (c[0] - c[2] - c[4] + c[6])) +

            // Bits 0, 1 and 2 are on
            (precomp012 * (-c[0] + c[1] + c[2] - c[3] + c[4] - c[5] -c[6] + c[7]))
        , FieldT::one(), r),
        FMT(this->annotation_prefix, ".result"));
}


void lookup_3bit_gadget::generate_r1cs_witness ()
{
    auto b0 = this->pb.val(b[0]);
    auto b1 = this->pb.val(b[1]);
    auto b2 = this->pb.val(b[2]);

    this->pb.val(precomp01) = b0 * b1;
    this->pb.val(precomp02) = b0 * b2;
    this->pb.val(precomp12) = b1 * b2;
    this->pb.val(precomp012) = b0 * b1 * b2;

    auto i = b.get_field_element_from_bits(this->pb).as_ulong();
    this->pb.val(r) = c[i];
}


// namespace ethsnarks
}
