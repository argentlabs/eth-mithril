#include "jubjub/doubler.hpp"
#include "utils.hpp"

namespace ethsnarks {

namespace jubjub {


PointDoubler::PointDoubler(
    ProtoboardT& in_pb,
    const Params& in_params,
    const VariableT in_X1,
    const VariableT in_Y1,
    const std::string& annotation_prefix
) :
    GadgetT(in_pb, annotation_prefix),
    m_params(in_params),
    m_X1(in_X1), m_Y1(in_Y1),
    m_alpha(make_variable(in_pb, FMT(annotation_prefix, ".alpha"))),
    m_beta(make_variable(in_pb, FMT(annotation_prefix, ".beta"))),
    m_gamma(make_variable(in_pb, FMT(annotation_prefix, ".gamma"))),
    m_delta(make_variable(in_pb, FMT(annotation_prefix, ".delta"))),
    m_X3(make_variable(in_pb, FMT(annotation_prefix, ".X3"))),
    m_Y3(make_variable(in_pb, FMT(annotation_prefix, ".Y3")))
{

}


void PointDoubler::generate_r1cs_constraints()
{
    this->pb.add_r1cs_constraint(
        ConstraintT(m_X1, m_X1, m_alpha),
            FMT(annotation_prefix, ".alpha = X1 * X1"));

    this->pb.add_r1cs_constraint(
        ConstraintT(m_Y1, m_Y1, m_beta),
            FMT(annotation_prefix, ".beta = Y1 * Y1"));

    this->pb.add_r1cs_constraint(
        ConstraintT(m_params.d * m_alpha, m_beta, m_gamma),
            FMT(annotation_prefix, ".gamma = d*alpha * beta"));

    this->pb.add_r1cs_constraint(
        ConstraintT(2*m_X1, m_Y1, m_delta),
            FMT(annotation_prefix, ".delta = 2*X1 * Y1"));

    this->pb.add_r1cs_constraint(
        ConstraintT(m_gamma + 1, m_X3, m_delta),
            FMT(annotation_prefix, ".x3 * (gamma + 1) == delta"));

    this->pb.add_r1cs_constraint(
        ConstraintT(m_gamma - 1, m_Y3, m_params.a*m_alpha - m_beta),
            FMT(annotation_prefix, ".y3 * (gamma - 1) == a*alpha - beta"));
}


const VariableT& PointDoubler::result_x() const
{
    return m_X3;
}


const VariableT& PointDoubler::result_y() const
{
    return m_Y3;
}


void PointDoubler::generate_r1cs_witness()
{
    this->pb.val(m_alpha) = this->pb.val(m_X1) * this->pb.val(m_X1);

    this->pb.val(m_beta) = this->pb.val(m_Y1) * this->pb.val(m_Y1);

    this->pb.val(m_gamma) = m_params.d*this->pb.val(m_alpha) * this->pb.val(m_beta);

    this->pb.val(m_delta) = this->pb.val(m_X1) * this->pb.val(m_Y1) * 2;

    const auto x3_rhs = this->pb.val(m_gamma) + 1;
    this->pb.val(m_X3) = this->pb.val(m_delta) * x3_rhs.inverse();

    const auto y3_lhs = ((this->pb.val(m_alpha)*m_params.a) - this->pb.val(m_beta));
    const auto y3_rhs = this->pb.val(m_gamma) - 1;
    this->pb.val(m_Y3) = y3_lhs * y3_rhs.inverse();
}


// namespace jubjub
}

// namespace ethsnarks
}
