#include "jubjub/conditional_point.hpp"

#include "utils.hpp"

namespace ethsnarks {

namespace jubjub {


ConditionalPoint::ConditionalPoint(
	ProtoboardT& in_pb,
	const VariableT in_x1,
	const VariableT in_y1,
	const VariableT in_bit,
	const std::string& annotation_prefix
) :
	GadgetT(in_pb, annotation_prefix),
	m_x1(in_x1),
	m_y1(in_y1),
	m_x2(make_variable(in_pb, FMT(annotation_prefix, ".x2"))),
	m_y2(make_variable(in_pb, FMT(annotation_prefix, ".y2"))),
	m_bit(in_bit)
{

}


const VariableT& ConditionalPoint::result_x() const {
	return m_x2;
}


const VariableT& ConditionalPoint::result_y() const {
	return m_y2;
}


void ConditionalPoint::generate_r1cs_constraints()
{
	this->pb.add_r1cs_constraint(
		ConstraintT(m_x1, m_bit, m_x2),
		FMT(this->annotation_prefix, ".x2 = x1 * bit"));

	this->pb.add_r1cs_constraint(
		ConstraintT(m_y1, m_bit, m_y2 - 1 + m_bit),
		FMT(this->annotation_prefix, ".y1 * bit == (y2 - 1) + bit"));
}


void ConditionalPoint::generate_r1cs_witness()
{
	auto bit_val = this->pb.val(m_bit);

	this->pb.val(m_x2) = bit_val * this->pb.val(m_x1);

	if( bit_val == FieldT::zero() )
	{
		this->pb.val(m_y2) = FieldT::one();
	}
	else {
		this->pb.val(m_y2) = this->pb.val(m_y1);
	}
}


// namespace jubjub
}

// namespace ethsnarks
}