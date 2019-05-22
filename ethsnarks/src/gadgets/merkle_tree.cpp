// This is an open source non-commercial project. Dear PVS-Studio, please check it.
// PVS-Studio Static Code Analyzer for C, C++ and C#: http://www.viva64.com

#include "ethsnarks.hpp"
#include "gadgets/merkle_tree.hpp"
#include "utils.hpp"

namespace ethsnarks
{

merkle_path_selector::merkle_path_selector(
    ProtoboardT &in_pb,
    const VariableT &in_input,
    const VariableT &in_pathvar,
    const VariableT &in_is_right,
    const std::string &in_annotation_prefix) : GadgetT(in_pb, in_annotation_prefix),
                                               m_input(in_input),
                                               m_pathvar(in_pathvar),
                                               m_is_right(in_is_right)
{
    m_left_a.allocate(in_pb, FMT(this->annotation_prefix, ".left_a"));
    m_left_b.allocate(in_pb, FMT(this->annotation_prefix, ".left_b"));
    m_left.allocate(in_pb, FMT(this->annotation_prefix, ".left"));

    m_right_a.allocate(in_pb, FMT(this->annotation_prefix, ".right_a"));
    m_right_b.allocate(in_pb, FMT(this->annotation_prefix, ".right_b"));
    m_right.allocate(in_pb, FMT(this->annotation_prefix, ".right"));
}

void merkle_path_selector::generate_r1cs_constraints()
{
    this->pb.add_r1cs_constraint(
        ConstraintT(1 - m_is_right, m_input, m_left_a),
        FMT(this->annotation_prefix, "1-is_right * input = left_a"));

    this->pb.add_r1cs_constraint(ConstraintT(m_is_right, m_pathvar, m_left_b),
                                 FMT(this->annotation_prefix, "is_right * pathvar = left_b"));

    this->pb.add_r1cs_constraint(ConstraintT(m_left_a + m_left_b, 1, m_left),
                                 FMT(this->annotation_prefix, "1 * left_a + left_b = left"));

    this->pb.add_r1cs_constraint(ConstraintT(m_is_right, m_input, m_right_a),
                                 FMT(this->annotation_prefix, "is_right * input = right_a"));

    this->pb.add_r1cs_constraint(ConstraintT(1 - m_is_right, m_pathvar, m_right_b),
                                 FMT(this->annotation_prefix, "1-is_right * pathvar = right_b"));

    this->pb.add_r1cs_constraint(ConstraintT(m_right_a + m_right_b, 1, m_right),
                                 FMT(this->annotation_prefix, "1 * right_a + right_b = right"));
}

void merkle_path_selector::generate_r1cs_witness() const
{
    this->pb.val(m_left_a) = (FieldT::one() - this->pb.val(m_is_right)) * this->pb.val(m_input);
    this->pb.val(m_left_b) = this->pb.val(m_is_right) * this->pb.val(m_pathvar);
    this->pb.val(m_left) = this->pb.val(m_left_a) + this->pb.val(m_left_b);

    this->pb.val(m_right_a) = this->pb.val(m_is_right) * this->pb.val(m_input);
    this->pb.val(m_right_b) = (FieldT::one() - this->pb.val(m_is_right)) * this->pb.val(m_pathvar);
    this->pb.val(m_right) = this->pb.val(m_right_a) + this->pb.val(m_right_b);
}

const VariableT &merkle_path_selector::left() const
{
    return m_left;
}

const VariableT &merkle_path_selector::right() const
{
    return m_right;
}

const VariableArrayT merkle_tree_IVs(ProtoboardT &in_pb)
{
    // TODO: replace with auto-generated constants
    // or remove the merkle tree IVs entirely...
    auto x = make_var_array(in_pb, 15, "IVs");
    std::vector<FieldT> level_IVs = {
        FieldT("149674538925118052205057075966660054952481571156186698930522557832224430770"),
        FieldT("9670701465464311903249220692483401938888498641874948577387207195814981706974"),
        FieldT("18318710344500308168304415114839554107298291987930233567781901093928276468271"),
        FieldT("6597209388525824933845812104623007130464197923269180086306970975123437805179"),
        FieldT("21720956803147356712695575768577036859892220417043839172295094119877855004262"),
        FieldT("10330261616520855230513677034606076056972336573153777401182178891807369896722"),
        FieldT("17466547730316258748333298168566143799241073466140136663575045164199607937939"),
        FieldT("18881017304615283094648494495339883533502299318365959655029893746755475886610"),
        FieldT("21580915712563378725413940003372103925756594604076607277692074507345076595494"),
        FieldT("12316305934357579015754723412431647910012873427291630993042374701002287130550"),
        FieldT("18905410889238873726515380969411495891004493295170115920825550288019118582494"),
        FieldT("12819107342879320352602391015489840916114959026915005817918724958237245903353"),
        FieldT("8245796392944118634696709403074300923517437202166861682117022548371601758802"),
        FieldT("16953062784314687781686527153155644849196472783922227794465158787843281909585"),
        FieldT("19346880451250915556764413197424554385509847473349107460608536657852472800734")};
    x.fill_with_field_elements(in_pb, level_IVs);

    return x;
}

// ethsnarks
} // namespace ethsnarks
