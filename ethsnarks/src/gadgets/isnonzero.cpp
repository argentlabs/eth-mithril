#include "gadgets/isnonzero.hpp"
#include "utils.hpp"
#include <libsnark/gadgetlib1/gadgets/basic_gadgets.hpp>

using libsnark::generate_boolean_r1cs_constraint;

namespace ethsnarks {


IsNonZero::IsNonZero(
	ProtoboardT& in_pb,
    const VariableT& in_var,
    const std::string &annotation_prefix
) :
	GadgetT(in_pb, annotation_prefix),
	m_X(in_var),
	m_Y(make_variable(in_pb, FMT(this->annotation_prefix, ".Y"))),
	m_M(make_variable(in_pb, FMT(this->annotation_prefix, ".M")))
{

}


const VariableT& IsNonZero::result() const
{
	return this->m_Y;
}


void IsNonZero::generate_r1cs_constraints()
{
	generate_boolean_r1cs_constraint<FieldT>(pb, m_Y);

	this->pb.add_r1cs_constraint(
		ConstraintT(m_X, 1 - m_Y, 0),
		FMT(this->annotation_prefix, " X * (1 - Y) = 0"));

	this->pb.add_r1cs_constraint(
		ConstraintT(m_X, m_M, m_Y),
		FMT(this->annotation_prefix, " X * (1/X) = Y"));
}


void IsNonZero::generate_r1cs_witness()
{
	const auto X = this->pb.val(m_X);

	if( X.is_zero() ) {
		this->pb.val(m_M) = FieldT::zero();
		this->pb.val(m_Y) = FieldT::zero();
	}
	else {
		this->pb.val(m_M) = X.inverse();
		this->pb.val(m_Y) = FieldT::one();
	}
}

	
// namespace ethsnarks
}
