#ifndef SHA256_ETH_FIELDS_HPP_
#define SHA256_ETH_FIELDS_HPP_

#include "ethsnarks.hpp"
#include "gadgets/sha256_full.hpp"
#include "utils.hpp"

namespace ethsnarks
{

class Sha256EthFields : public GadgetT
{
public:
    const VariableT left;
    const VariableT right;

    libsnark::digest_variable<FieldT> left_bits;
    const VariableArrayT left_bits_reversed;
    libsnark::packing_gadget<FieldT> left_packer;

    libsnark::digest_variable<FieldT> right_bits;
    const VariableArrayT right_bits_reversed;
    libsnark::packing_gadget<FieldT> right_packer;

    const std::vector<VariableArrayT> input_block_slice;
    libsnark::block_variable<FieldT> input_block;
    libsnark::digest_variable<FieldT> output_digest;
    sha256_full_gadget_512 hasher;

    const VariableT output;
    libsnark::pb_variable_array<FieldT> output_bits_slice;
    libsnark::packing_gadget<FieldT> output_packer;

    Sha256EthFields(
        ProtoboardT &in_pb,
        const VariableT &in_left,
        const VariableT &in_right,
        const std::string &in_annotation_prefix) : GadgetT(in_pb, in_annotation_prefix),

                                                   left(in_left),
                                                   right(in_right),

                                                   left_bits(in_pb, libsnark::SHA256_digest_size, FMT(annotation_prefix, ".left_bits")),
                                                   left_bits_reversed(left_bits.bits.rbegin(), left_bits.bits.rend()),
                                                   left_packer(in_pb, left_bits.bits, in_left, FMT(annotation_prefix, ".left_packer")),

                                                   right_bits(in_pb, libsnark::SHA256_digest_size, FMT(annotation_prefix, ".right_bits")),
                                                   right_bits_reversed(right_bits.bits.rbegin(), right_bits.bits.rend()),
                                                   right_packer(in_pb, right_bits.bits, in_right, FMT(annotation_prefix, ".right_packer")),

                                                   // Python uses big-endian bitwise representation of the input integers, so reverse each left & right individually
                                                   //input_block_slice({VariableArrayT(left_bits.bits.rbegin(), left_bits.bits.rend()), VariableArrayT(right_bits.bits.rbegin(), right_bits.bits.rend())}),
                                                   input_block_slice({left_bits_reversed, right_bits_reversed}),
                                                   input_block(in_pb, input_block_slice, FMT(in_annotation_prefix, ".input_block")),
                                                   output_digest(in_pb, libsnark::SHA256_digest_size, FMT(in_annotation_prefix, ".output_digest")),
                                                   hasher(in_pb, input_block, output_digest, FMT(in_annotation_prefix, ".hasher")),

                                                   // Again, python uses big-endian bitwise representation, so reverse the output bits
                                                   output(make_variable(in_pb, FMT(annotation_prefix, ".output"))),
                                                   output_bits_slice(output_digest.bits.rbegin(), output_digest.bits.rend() - 4),
                                                   output_packer(in_pb, output_bits_slice, output, FMT(in_annotation_prefix, ".output_packer"))
    {
        assert(right_bits_reversed.size() == libsnark::SHA256_digest_size);
    }

    const VariableT &result() const
    {
        return output;
    }

    void generate_r1cs_constraints()
    {
        left_bits.generate_r1cs_constraints();
        left_packer.generate_r1cs_constraints(false);

        right_bits.generate_r1cs_constraints();
        right_packer.generate_r1cs_constraints(true);

        hasher.generate_r1cs_constraints();

        output_digest.generate_r1cs_constraints();
        output_packer.generate_r1cs_constraints(false); // Result comes from SHA256 function, no bitness checks required
    }

    void generate_r1cs_witness()
    {
        left_packer.generate_r1cs_witness_from_packed();
        right_packer.generate_r1cs_witness_from_packed();
        hasher.generate_r1cs_witness();
        output_packer.generate_r1cs_witness_from_bits();
    }
};

} // namespace ethsnarks

#endif // SHA256_ETH_FIELDS_HPP_