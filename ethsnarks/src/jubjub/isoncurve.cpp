#include "utils.hpp"
#include "jubjub/isoncurve.hpp"


namespace ethsnarks {

namespace jubjub {


IsOnCurve::IsOnCurve(
    ProtoboardT& in_pb,
    const Params& in_params,
    const VariableT in_X,
    const VariableT in_Y,
    const std::string& annotation_prefix
) :
	GadgetT(in_pb, annotation_prefix),
	m_params(in_params),
	m_X(in_X),
	m_Y(in_Y),
	m_xx(make_variable(in_pb, FMT(this->annotation_prefix, ".xx"))),
	m_yy(make_variable(in_pb, FMT(this->annotation_prefix, ".yy")))
{

}


void IsOnCurve::generate_r1cs_constraints()
{
	// xx == X*X
	this->pb.add_r1cs_constraint(
		ConstraintT(m_X, m_X, m_xx),
		FMT(this->annotation_prefix, ".xx"));

	// yy == Y * Y
	this->pb.add_r1cs_constraint(
		ConstraintT(m_Y, m_Y, m_yy),
		FMT(this->annotation_prefix, ".yy"));

	// d*xx * yy == a*xx + yy - 1
	this->pb.add_r1cs_constraint(
		ConstraintT(m_params.d*m_xx, m_yy, m_params.a*m_xx + m_yy - 1),
		FMT(this->annotation_prefix, ".is_on_curve"));
}


void IsOnCurve::generate_r1cs_witness()
{
	auto x = this->pb.val(m_X);
	auto y = this->pb.val(m_Y);

	this->pb.val(m_xx) = x * x;
	this->pb.val(m_yy) = y * y;
}


// namespace jubjub
}

// namespace ethsnarks
}
