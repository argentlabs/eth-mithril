// Copyright (c) 2018 HarryR
// License: LGPL-3.0+

#include "lookup_2bit.hpp"

#include "utils.hpp"


namespace ethsnarks {


void lookup_2bit_constraints( ProtoboardT& pb, const std::vector<FieldT> c, const VariableArrayT b, const VariableT r, const std::string& annotation_prefix )
{
	// lhs = c[1] - c[0] + (b[1] * (c[3] - c[2] - c[1] + c[0]))
	LinearCombinationT lhs;
	lhs.assign(pb, LinearTermT(libsnark::ONE, c[1] - c[0]) +
				   LinearTermT(b[1], c[3] - c[2] - c[1] + c[0]));

	// rhs = -c[0] + r + (b[1] * (-c[2] + c[0]))
	LinearCombinationT rhs;
	rhs.assign(pb, LinearTermT(libsnark::ONE, -c[0]) +
				   LinearTermT(r, 1) +
				   LinearTermT(b[1], -c[2] + c[0]));

	// lhs * b[0] == rhs
    pb.add_r1cs_constraint(
        ConstraintT(lhs, b[0], rhs),
            FMT(annotation_prefix, ".result"));
}


lookup_2bit_gadget::lookup_2bit_gadget(
	ProtoboardT &in_pb,
	const std::vector<FieldT> in_constants,
	const VariableArrayT in_bits,
	const std::string& annotation_prefix
) :
	GadgetT(in_pb, annotation_prefix),
	c(in_constants),
	b(in_bits),
	r(make_variable(in_pb, FMT(this->annotation_prefix, ".r")))
{
	assert( in_constants.size() == 4 );
}


const VariableT& lookup_2bit_gadget::result()
{
	return r;
}


void lookup_2bit_gadget::generate_r1cs_constraints()
{
	lookup_2bit_constraints(this->pb, c, b, r, this->annotation_prefix);
}


void lookup_2bit_gadget::generate_r1cs_witness ()
{
    auto i = b.get_field_element_from_bits(this->pb).as_ulong();
    this->pb.val(r) = c[i];
}


// namespace ethsnarks
}
