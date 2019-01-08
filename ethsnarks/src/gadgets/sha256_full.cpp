// Copyright (c) 2018 HarryR
// License: LGPL-3.0+

#pragma once

#include <libsnark/gadgetlib1/gadget.hpp>
#include <libsnark/gadgetlib1/gadgets/basic_gadgets.hpp>
#include <libsnark/gadgetlib1/gadgets/hashes/hash_io.hpp>                   // digest_variable
#include <libsnark/gadgetlib1/gadgets/hashes/sha256/sha256_components.hpp>  // SHA256_default_IV
#include <libsnark/gadgetlib1/gadgets/hashes/sha256/sha256_gadget.hpp>      // sha256_compression_function_gadget

#include <openssl/sha.h>    // SHA256_CTX

#include "utils.hpp"

namespace ethsnarks {

static const size_t SHA256_digest_size_bytes = libsnark::SHA256_digest_size / 8;

static const size_t SHA256_block_size_bytes = libsnark::SHA256_block_size / 8;


/**
* begin with the original message of length L bits
* append a single '1' bit
* append K '0' bits, where K is the minimum number >= 0 such that L + 1 + K + 64 is a multiple of 512
* append L as a 64-bit big-endian integer, making the total post-processed length a multiple of 512 bits
*
* So given a 512bit message, the _final_padding_512 is another block of 512 bits
* which begins with a '1' bit, and ends with a 64bit big-endian number representing '512'
*/
static const libff::bit_vector _final_padding_512 = libff::int_list_to_bits({
    0x80, 0x00, 0x00, 0x00,    // 4
    0x00, 0x00, 0x00, 0x00,    // 8
    0x00, 0x00, 0x00, 0x00,    // 12
    0x00, 0x00, 0x00, 0x00,    // 16
    0x00, 0x00, 0x00, 0x00,    // 20
    0x00, 0x00, 0x00, 0x00,    // 24
    0x00, 0x00, 0x00, 0x00,    // 28
    0x00, 0x00, 0x00, 0x00,    // 32

    0x00, 0x00, 0x00, 0x00,    // 4
    0x00, 0x00, 0x00, 0x00,    // 8
    0x00, 0x00, 0x00, 0x00,    // 12
    0x00, 0x00, 0x00, 0x00,    // 16
    0x00, 0x00, 0x00, 0x00,    // 20
    0x00, 0x00, 0x00, 0x00,    // 24


    // Remaining 64 bits are the length specifier
    /*
    * bitlen >> 56, bitlen >> 48, bitlen >> 40, bitlen >> 32,
    * bitlen >> 24, bitlen >> 16, bitlen >> 8, bitlen
    */
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x02, 0x00}, 8);



/**
* Perform full round of SHA-256 on a 512 bit input
*/
class sha256_full_gadget_512 : public GadgetT
{
public:
    libsnark::digest_variable<FieldT> intermediate_hash;

    libsnark::block_variable<FieldT> input_block;

    libsnark::digest_variable<FieldT> output;

    libsnark::sha256_compression_function_gadget<FieldT> input_hasher;

    const VariableArrayT length_padding;

    libsnark::sha256_compression_function_gadget<FieldT> final_hasher;

    sha256_full_gadget_512(
        ProtoboardT &in_pb,
        const libsnark::block_variable<FieldT> &in_input_block,
        const libsnark::digest_variable<FieldT> &in_output,
        const std::string &annotation_prefix
    ) :
        GadgetT(in_pb, FMT(annotation_prefix, "sha256_full_gadget_512")),

        intermediate_hash(in_pb, libsnark::SHA256_digest_size, FMT(annotation_prefix, " intermediate_hash")),

        input_block(in_input_block),

        output(in_output),

        input_hasher(in_pb,
                     SHA256_default_IV(in_pb),  // prev_output
                     in_input_block.bits,       // new_block
                     intermediate_hash,         // output
                     FMT(annotation_prefix, " input_hasher")),

        length_padding(VariableArray_from_bits(in_pb, _final_padding_512, FMT(annotation_prefix, " length_padding"))),

        final_hasher(in_pb,
                     intermediate_hash.bits,    // prev_output
                     length_padding,            // new_block
                     in_output,                 // output
                     FMT(annotation_prefix, " final_hasher"))
    {
        assert( in_input_block.bits.size() == libsnark::SHA256_block_size );
    }

    void generate_r1cs_constraints(const bool ensure_output_bitness=false)
    {
        libff::UNUSED(ensure_output_bitness);
        input_hasher.generate_r1cs_constraints();
        final_hasher.generate_r1cs_constraints();
    }

    void generate_r1cs_witness() {
        input_hasher.generate_r1cs_witness();
        final_hasher.generate_r1cs_witness();
    }


    void generate_r1cs_witness(
        const libff::bit_vector &in_block,
        const libff::bit_vector &in_expected_bv
    ) {
        assert( in_block.size() == libsnark::SHA256_block_size );

        assert( in_expected_bv.size() == libsnark::SHA256_digest_size );

        input_block.generate_r1cs_witness(in_block);

        input_hasher.generate_r1cs_witness();

        output.generate_r1cs_witness(in_expected_bv);
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
};

// ethsnarks
}
