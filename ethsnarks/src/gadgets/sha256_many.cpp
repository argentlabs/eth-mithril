// Copyright (c) 2018 HarryR
// License: LGPL-3.0+

#include "gadgets/sha256_many.hpp"
#include "utils.hpp"

using libsnark::SHA256_block_size;
using libsnark::SHA256_digest_size;


namespace ethsnarks {


sha256_many::sha256_many(
        ProtoboardT& in_pb,
        const VariableArrayT& in_bits,
        const std::string &annotation_prefix
) :
    GadgetT(in_pb, annotation_prefix),
    m_blocks(bits2blocks_padded(in_pb, in_bits, SHA256_block_size))
{
    // Construct hashers, inputs and outputs
    for( size_t i = 0; i < m_blocks.size(); i++ )
    {
        // Allocate output digests
        m_outputs.emplace_back(
            in_pb,
            SHA256_digest_size,
            FMT(annotation_prefix, ".outputs[%zu]", i));

        // First round includes IV as input
        // Further rounds include previous digest as input
        m_hashers.emplace_back(
            in_pb,
            i == 0 ? SHA256_default_IV(in_pb) : m_outputs[i - 1].bits,
            m_blocks[i],
            m_outputs[i],
            FMT(annotation_prefix, ".hasher[%zu]", i));
    }
}


const sha256_many::DigestT& sha256_many::result() const
{
    return m_outputs[ m_outputs.size() - 1 ];
}


void sha256_many::generate_r1cs_constraints()
{
    for( size_t i = 0; i < m_hashers.size(); i++ )
    {
        m_hashers[i].generate_r1cs_constraints();

        m_outputs[i].generate_r1cs_constraints();
    }
}


void sha256_many::generate_r1cs_witness()
{
    for( size_t i = 0; i < m_hashers.size(); i++ )
    {
        auto is_last = i == (m_hashers.size() - 1);

        m_hashers[i].generate_r1cs_witness();
    }
}


// namespace ethsnarks
}
