#include "gadgets/field2bits_strict.hpp"
#include "utils.hpp"

namespace ethsnarks {


field2bits_strict::field2bits_strict(
    ProtoboardT& in_pb,
    const VariableT in_field_element,
    const std::string& annotation_prefix
) :
    GadgetT(in_pb, annotation_prefix),
    m_bits(make_var_array(in_pb, FieldT::size_in_bits(), FMT(this->annotation_prefix, ".result"))),
    m_packer(in_pb, m_bits, in_field_element, FMT(this->annotation_prefix, ".packer")),
    m_results(make_var_array(in_pb, FieldT::size_in_bits() - 1, FMT(this->annotation_prefix, ".results")))
{
    // Constant bit is 0
    const std::vector<FieldT> table_cmp_0 = {
        FieldT("0"),    // 0, equal
        FieldT("1"),    // 1, greater
    };

    // Constant bit is 1
    const std::vector<FieldT> table_cmp_1 = {
        FieldT("1"),    // 0, less
        FieldT("1"),    // 1, equal
    };

    const auto largest_value = (FieldT(FieldT::mod) - 1).as_bigint();

    for( size_t i = 0; i < FieldT::size_in_bits(); i++ )
    {
        if( largest_value.test_bit(i) )
        {
            m_comparisons.emplace_back(in_pb, table_cmp_1, m_bits[i], FMT(this->annotation_prefix, ".comparisons[%zu]", i));
        }
        else {
            m_comparisons.emplace_back(in_pb, table_cmp_0, m_bits[i], FMT(this->annotation_prefix, ".comparisons[%zu]", i));
        }
    }
}


void field2bits_strict::generate_r1cs_constraints ()
{
    m_packer.generate_r1cs_constraints(true);

    for( auto& gadget: m_comparisons )
    {
        gadget.generate_r1cs_constraints();
    }

    // AND all of the comparisons
    auto last_bit = int(FieldT::size_in_bits() - 1);
    for( int i = last_bit; i > 0; i-- )
    {
        if( i == last_bit )
        {
            pb.add_r1cs_constraint(
                ConstraintT(m_comparisons[i-1].result(), m_comparisons[i].result(), m_results[i-1]),
                FMT(this->annotation_prefix, ".results[%zu] = comparisons[%zu] * comparisons[%zu]", i-1, i-1, i));
        }
        else {
            pb.add_r1cs_constraint(
                ConstraintT(m_comparisons[i-1].result(), m_results[i], m_results[i-1]),
                FMT(this->annotation_prefix, ".results[%zu] = comparisons[%zu] * results[%zu]", i-1, i-1, i));
        }
    }
}


void field2bits_strict::generate_r1cs_witness ()
{
    m_packer.generate_r1cs_witness_from_packed();

    for( auto& gadget: m_comparisons )
    {
        gadget.generate_r1cs_witness();
    }

    // Iterate from MSB to LSB
    auto last_bit = (FieldT::size_in_bits() - 1);
    for( size_t i = last_bit; i > 0; i-- )
    {
        // current * previous = result
        if( i == last_bit )
        {
            this->pb.val(m_results[i-1]) = this->pb.val(m_comparisons[i-1].result()) * this->pb.val(m_comparisons[i].result());
        }
        else
        {
            this->pb.val(m_results[i-1]) = this->pb.val(m_results[i]) * this->pb.val(m_comparisons[i-1].result());
        }
    }
}


const VariableArrayT& field2bits_strict::result() const
{
    return m_bits;
}


// namespace ethsnarks
}
