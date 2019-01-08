// Copyright (c) 2018 HarryR
// License: LGPL-3.0+

#include "hashpreimage.hpp"

#include "ethsnarks.hpp"

#include "gadgets/sha256_full.cpp"
#include "utils.hpp"
#include "export.hpp"
#include "import.hpp"
#include "stubs.hpp"

#include <libff/algebra/fields/field_utils.hpp>

#include <openssl/sha.h>

namespace ethsnarks {


/**
* Verify that SHA256(private<512bit_block>) == public<output>
*/
class mod_hashpreimage : public GadgetT
{
public:
    static const size_t SHA256_digest_size_bytes = libsnark::SHA256_digest_size / 8;

    static const size_t SHA256_block_size_bytes = libsnark::SHA256_block_size / 8;

    const size_t input_size_in_bits = libsnark::SHA256_digest_size;

    const size_t input_size_in_fields;

    const VariableArrayT input_as_field_elements;

    libsnark::digest_variable<FieldT> expected_digest;

    const VariableArrayT input_as_bits;

    libsnark::multipacking_gadget<FieldT> unpacker;

    libsnark::block_variable<FieldT> input_block;

    libsnark::digest_variable<FieldT> output;

    sha256_full_gadget_512 full_hasher;


    mod_hashpreimage(
        ProtoboardT &in_pb,
        const std::string &annotation_prefix
    ) :
        GadgetT(in_pb, annotation_prefix),

        // number of field packed elements as input
        input_size_in_fields( libff::div_ceil(input_size_in_bits, FieldT::capacity()) ),

        // packed input, given to prover/verifier
        input_as_field_elements( make_var_array(in_pb, input_size_in_fields, FMT(annotation_prefix, " input_as_field_elements")) ),

        // public input digest, must match output
        expected_digest(in_pb, libsnark::SHA256_digest_size, FMT(annotation_prefix, " expected_digest")),

        // unpacked input bits, mapped to the input digest
        input_as_bits(expected_digest.bits.begin(), expected_digest.bits.end()),

        // unpack from field elements (packed bits)
        unpacker(in_pb, input_as_bits, input_as_field_elements, FieldT::capacity(), "unpacker"),

        // private input block for hashing, 512 bits
        input_block(in_pb, libsnark::SHA256_block_size, FMT(annotation_prefix, " input_block")),

        // output digest variable, 256 bits
        output(in_pb, libsnark::SHA256_digest_size, FMT(annotation_prefix, " output")),

        // HASH(input_block) -> output
        full_hasher(in_pb, input_block, output, FMT(annotation_prefix, " full_hasher"))
    {
        in_pb.set_input_sizes( input_size_in_fields );
    }


    void generate_r1cs_constraints()
    {
        unpacker.generate_r1cs_constraints(true);

        full_hasher.generate_r1cs_constraints();
    }


    void generate_r1cs_witness(
        const libff::bit_vector &in_block,
        const libff::bit_vector &in_expected_bv
    ) {
        assert( in_block.size() == libsnark::SHA256_block_size );

        assert( in_expected_bv.size() == libsnark::SHA256_digest_size );

        input_block.generate_r1cs_witness(in_block);

        full_hasher.generate_r1cs_witness();

        expected_digest.generate_r1cs_witness(in_expected_bv);

        output.generate_r1cs_witness(in_expected_bv);

        unpacker.generate_r1cs_witness_from_bits();
    }


    /**
    * Given input bytes of SHA256 block size, generate the witness for the expected output
    */
    void generate_r1cs_witness(
        const uint8_t in_bytes[SHA256_block_size_bytes]
    ) {
        SHA256_CTX ctx;
        uint8_t output_digest[SHA256_digest_size_bytes];

        SHA256_Init(&ctx);
        SHA256_Update(&ctx, in_bytes, SHA256_block_size_bytes);
        SHA256_Final(output_digest, &ctx);

        const auto input_bv = bytes_to_bv(in_bytes, SHA256_block_size_bytes);

        const auto output_bv = bytes_to_bv(output_digest, SHA256_digest_size_bytes);

        this->generate_r1cs_witness( input_bv, output_bv );
    }


    static PrimaryInputT make_primary_input(const libff::bit_vector &in_block_bv)
    {
        assert( in_block_bv.size() == libsnark::SHA256_block_size );

        return libff::pack_bit_vector_into_field_element_vector<FieldT>(in_block_bv);
    }
};

// ethsnarks
}


char *hashpreimage_prove( const char *pk_file, const uint8_t *preimage_bytes64 )
{
    ethsnarks::ppT::init_public_params();

    ethsnarks::ProtoboardT pb;
    ethsnarks::mod_hashpreimage mod(pb, "module");
    mod.generate_r1cs_constraints();
    mod.generate_r1cs_witness(preimage_bytes64);

    if( ! pb.is_satisfied() )
    {
        return nullptr;
    }

    auto json = ethsnarks::stub_prove_from_pb(pb, pk_file);

    return ::strdup(json.c_str());
}


int hashpreimage_genkeys( const char *pk_file, const char *vk_file )
{
    return ethsnarks::stub_genkeys<ethsnarks::mod_hashpreimage>(pk_file, vk_file);
}


bool hashpreimage_verify( const char *vk_json, const char *proof_json )
{
    return ethsnarks::stub_verify( vk_json, proof_json );
}
