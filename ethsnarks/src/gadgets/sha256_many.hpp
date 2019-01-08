#ifndef ETHSNARKS_SHA256_MANY_HPP_
#define ETHSNARKS_SHA256_MANY_HPP_

// Copyright (c) 2018 HarryR
// License: LGPL-3.0+

#include "ethsnarks.hpp"


#include <libsnark/gadgetlib1/gadgets/hashes/hash_io.hpp>                   // digest_variable
#include <libsnark/gadgetlib1/gadgets/hashes/sha256/sha256_components.hpp>  // SHA256_default_IV
#include <libsnark/gadgetlib1/gadgets/hashes/sha256/sha256_gadget.hpp>      // sha256_compression_function_gadget


namespace ethsnarks {



/**
* This gadget hashes an arbitrary number of bits, in a way which is compatible
* with the Ethereum and Python SHA2-256 implementations. It accepts a VariableArrayT
* of bits as inputs, any number of bits can be provided, and provides one
* output digest.
*/
class sha256_many : public GadgetT
{
public:
	typedef libsnark::sha256_compression_function_gadget<FieldT> HashT;
	typedef libsnark::digest_variable<FieldT> DigestT;

	const std::vector<VariableArrayT> m_blocks;
	std::vector<HashT> m_hashers;
	std::vector<DigestT> m_outputs;

	sha256_many(
		ProtoboardT& in_pb,
		const VariableArrayT& in_bits,
		const std::string &annotation_prefix);

	const DigestT& result() const;

	void generate_r1cs_constraints();

	void generate_r1cs_witness();
};


// namespace
}


// ETHSNARKS_SHA256_MANY_HPP_
#endif