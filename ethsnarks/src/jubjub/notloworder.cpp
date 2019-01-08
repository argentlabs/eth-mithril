#include "jubjub/notloworder.hpp"

namespace ethsnarks {
	
namespace jubjub {


NotLowOrder::NotLowOrder(
	ProtoboardT& in_pb,
	const Params& in_params,
	const VariableT in_X,
	const VariableT in_Y,
	const std::string& annotation_prefix
) :
	GadgetT(in_pb, annotation_prefix),
	m_doubler_2(in_pb, in_params, in_X, in_Y, FMT(this->annotation_prefix, ".doubler_2")),
	m_doubler_4(in_pb, in_params, m_doubler_2.result_x(), m_doubler_2.result_y(), FMT(this->annotation_prefix, ".doubler_4")),
	m_doubler_8(in_pb, in_params, m_doubler_4.result_x(), m_doubler_4.result_y(), FMT(this->annotation_prefix, ".doubler_8")),
	m_isnonzero(in_pb, m_doubler_8.result_x(), FMT(this->annotation_prefix, ".isnonzero"))
{

}


void NotLowOrder::generate_r1cs_constraints()
{
	m_doubler_2.generate_r1cs_constraints();
	m_doubler_4.generate_r1cs_constraints();
	m_doubler_8.generate_r1cs_constraints();
	m_isnonzero.generate_r1cs_constraints();

	pb.add_r1cs_constraint(
        ConstraintT(
            m_isnonzero.result(), 1, 1),
            FMT(annotation_prefix, ".isnonzero == 1"));
}


void NotLowOrder::generate_r1cs_witness()
{
	m_doubler_2.generate_r1cs_witness();
	m_doubler_4.generate_r1cs_witness();
	m_doubler_8.generate_r1cs_witness();
	m_isnonzero.generate_r1cs_witness();
}


// namespace jubjub
}

// namespace ethsnarks
}
