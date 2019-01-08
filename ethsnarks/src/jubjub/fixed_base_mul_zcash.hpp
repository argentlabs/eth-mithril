#ifndef JUBJUB_FIXEDMULT_ZCASH_HPP_
#define JUBJUB_FIXEDMULT_ZCASH_HPP_

// Copyright (c) 2018 fleupold
// License: LGPL-3.0+

#include "gadgets/lookup_signed_3bit.hpp"
#include "jubjub/adder.hpp"
#include "jubjub/point.hpp"
#include "jubjub/montgomery.hpp"

namespace ethsnarks {

namespace jubjub {


class fixed_base_mul_zcash : public GadgetT {
public:
	std::vector<MontgomeryAdder> montgomery_adders;
	std::vector<MontgomeryToEdwards> point_converters;
	std::vector<PointAdder> edward_adders;
	std::vector<LinearCombinationT> m_windows_x;
	std::vector<lookup_signed_3bit_gadget> m_windows_y;

	fixed_base_mul_zcash(
		ProtoboardT &in_pb,
		const Params& in_params,
		const std::vector<EdwardsPoint>& base_points,
		const VariableArrayT& in_scalar,
		const std::string& annotation_prefix
	);

	void generate_r1cs_constraints ();

	void generate_r1cs_witness ();

	const VariableT& result_x() const;

	const VariableT& result_y() const;

	static size_t basepoints_required(size_t n_bits);
};


// namespace jubjub
}

// namespace ethsnarks
}

// JUBJUB_FIXEDMULT_ZCASH_HPP_
#endif