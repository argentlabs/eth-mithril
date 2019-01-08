#include "jubjub/montgomery.hpp"
#include "utils.hpp"


namespace ethsnarks {

namespace jubjub {


MontgomeryAdder::MontgomeryAdder(
    ProtoboardT& in_pb,
    const Params& in_params,
    const LinearCombinationT in_X1,
    const VariableT in_Y1,
    const LinearCombinationT in_X2,
    const VariableT in_Y2,
    const std::string &annotation_prefix
) :
    GadgetT(in_pb, annotation_prefix),
    m_params(in_params),
    m_X1(in_X1), m_Y1(in_Y1),
    m_X2(in_X2), m_Y2(in_Y2),
    lambda(make_variable(in_pb, FMT(annotation_prefix, ".lambda"))),
    m_X3(make_variable(in_pb, FMT(annotation_prefix, ".X3"))),
    m_Y3(make_variable(in_pb, FMT(annotation_prefix, ".Y3")))
{}

void MontgomeryAdder::generate_r1cs_constraints()
{
    this->pb.add_r1cs_constraint(
        ConstraintT({m_X2 - m_X1}, lambda, {m_Y2 - m_Y1}),
            FMT(annotation_prefix, ".lambda = (y' - y) / (x' - x)"));
    this->pb.add_r1cs_constraint(
        ConstraintT(lambda, lambda, {m_params.A + m_X1 + m_X2 + m_X3}),
            FMT(annotation_prefix, ".(lambda) * (lambda) = (A + x + x' + x'')"));
    this->pb.add_r1cs_constraint(
        ConstraintT({m_X1 - m_X3}, lambda, {m_Y3 + m_Y1}),
            FMT(annotation_prefix, ".y'' = -(y + lambda(x'' - x))"));
}

const VariableT& MontgomeryAdder::result_x() const
{
    return m_X3;
}

const VariableT& MontgomeryAdder::result_y() const
{
    return m_Y3;
}

void MontgomeryAdder::generate_r1cs_witness()
{
    this->pb.val(lambda) = (this->pb.val(m_Y2) - this->pb.val(m_Y1)) * (this->pb.lc_val(m_X2) - this->pb.lc_val(m_X1)).inverse();
    this->pb.val(m_X3) = this->pb.val(lambda).squared() - m_params.A - this->pb.lc_val(m_X1) - this->pb.lc_val(m_X2);
    this->pb.val(m_Y3) = -(this->pb.val(m_Y1) + (this->pb.val(lambda)*(this->pb.val(m_X3) - this->pb.lc_val(m_X1))));
}


// --------------------------------------------------------------------


MontgomeryToEdwards::MontgomeryToEdwards(
    ProtoboardT &in_pb,
    const Params& in_params,
    const LinearCombinationT in_X,
    const VariableT in_Y,
    const std::string &annotation_prefix
) :
    GadgetT(in_pb, annotation_prefix),
    m_params(in_params),
    m_X1(in_X), m_Y1(in_Y),
    m_X2(make_variable(in_pb, FMT(annotation_prefix, ".result_x"))),
    m_Y2(make_variable(in_pb, FMT(annotation_prefix, ".result_y")))
{}

void MontgomeryToEdwards::generate_r1cs_constraints()
{
    this->pb.add_r1cs_constraint(
        ConstraintT(m_Y1, m_X2, m_X1 * m_params.scale),
            FMT(annotation_prefix, ".x_result' = (scale*x) / y"));
    this->pb.add_r1cs_constraint(
        ConstraintT({m_X1 + FieldT::one()}, m_Y2, { m_X1 - FieldT::one() }),
            FMT(annotation_prefix, ".y_result' = (x - 1) / (x + 1)"));
}

void MontgomeryToEdwards::generate_r1cs_witness()
{
    this->pb.val(m_X2) = m_params.scale * this->pb.lc_val(m_X1) * this->pb.val(m_Y1).inverse();
    this->pb.val(m_Y2) = (this->pb.lc_val(m_X1) - FieldT::one()) * (this->pb.lc_val(m_X1) + FieldT::one()).inverse();
}

const VariableT& MontgomeryToEdwards::result_x() const
{
    return m_X2;
}

const VariableT& MontgomeryToEdwards::result_y() const
{
    return m_Y2;
}


// namespace jubjub
}

// namespace ethsnarks
}
