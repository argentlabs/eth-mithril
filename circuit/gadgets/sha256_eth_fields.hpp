#ifndef SHA256_ETH_FIELDS_HPP_
#define SHA256_ETH_FIELDS_HPP_

#include "sha256_ethereum.hpp"
#include "ethsnarks.hpp"

namespace ethsnarks
{

template <typename FieldT>
void fill_vararray_with_padded_bits_of_field_element(protoboard<FieldT> &pb, VariableArrayT arr, const FieldT &r)
{
    const libff::bigint<FieldT::num_limbs> rint = r.as_bigint();
    for (size_t i = 0; i < arr.size(); ++i)
    {
        pb.val(arr[arr.size() - 1 - i]) = rint.test_bit(i) ? FieldT::one() : FieldT::zero();
    }
}

template <typename FieldT>
FieldT bitarray_to_field(const protoboard<FieldT> &pb, VariableArrayT arr, size_t droppedBits = 4)
{
    FieldT result = FieldT::zero();

    for (size_t i = droppedBits; i < arr.size(); ++i)
    {
        const FieldT v = pb.lc_val(arr[i]);
        assert(v == FieldT::zero() || v == FieldT::one());
        result += result + v;
    }

    return result;
}

template <class FieldT>
class Sha256EthFields : public GadgetT
{

  private:
    VariableT ZERO;
    VariableArrayT left_bits;
    VariableArrayT right_bits;
    std::shared_ptr<digest_variable<FieldT>> output_digest;
    std::shared_ptr<ethereum_sha256<FieldT>> hasher;

  public:
    VariableT left;
    VariableT right;
    VariableT output;

    Sha256EthFields(
        ProtoboardT &in_pb,
        const VariableT &in_left,
        const VariableT &in_right,
        const std::string &in_annotation_prefix = "") : GadgetT(in_pb, in_annotation_prefix),
                                                        left(in_left),
                                                        right(in_right),
                                                        output(make_variable(in_pb, FMT(annotation_prefix, ".output"))),
                                                        ZERO(make_variable(in_pb, FMT(annotation_prefix, ".ZERO"))),
                                                        left_bits(make_var_array(in_pb, 256, FMT(annotation_prefix, ".left_bits"))),
                                                        right_bits(make_var_array(in_pb, 256, FMT(annotation_prefix, ".right_bits")))
    {
        output_digest.reset(new digest_variable<FieldT>(in_pb, 256, "output_digest"));
        hasher.reset(new ethereum_sha256<FieldT>(in_pb, ZERO, left_bits, right_bits, output_digest));
    }

    const VariableT &result() const
    {
        return output;
    }

    void generate_r1cs_constraints()
    {
        hasher->generate_r1cs_constraints();
    }

    void generate_r1cs_witness()
    {
        this->pb.val(ZERO) = 0;

        fill_vararray_with_padded_bits_of_field_element(this->pb, left_bits, this->pb.val(left));
        fill_vararray_with_padded_bits_of_field_element(this->pb, right_bits, this->pb.val(right));

        hasher->generate_r1cs_witness();

        this->pb.val(output) = bitarray_to_field(this->pb, output_digest->bits);
    }
};

} // namespace ethsnarks

#endif // SHA256_ETH_FIELDS_HPP_