#ifndef JUBJUB_COMMITMENT_HPP_
#define JUBJUB_COMMITMENT_HPP_

// Copyright (c) 2018 @HarryR
// License: LGPL-3.0+

#include "ethsnarks.hpp"
#include "jubjub/adder.hpp"
#include "jubjub/point.hpp"
#include "jubjub/fixed_base_mul.hpp"


namespace ethsnarks {

namespace jubjub {


/**
* Perform multiple scalar multiplications and add the results together
* Requires at least two pairs of base point & scalar.
* Accepts any number of pairs
*
*               +--------+       +--------+      +--------+
* Base Points:  | Base 0 |       | Base 1 |      | Base 2 |
*               +--------+       +--------+      +--------+
*                   |                |                |
*     Scalars:      |  +----------+  |  +----------+  |  +----------+
*                   |  | Scalar 0 |  |  | Scalar 1 |  |  | Scalar 2 |
*                   |  +----------+  |  +----------+  |  +----------+
*                   |    |           |    |           |    |
*                   v    v           v    v           v    v
*                 +--------+       +--------+       +--------+
* Multipliers:    | Mult 0 |       | Mult 1 |       | Mult 2 |
*                 +--------+       +--------+       +--------+
*                       `----,   ,-----'                |
*                            |   |                      |
*                            v   v                      v
*                       +--------------+           +---------+
*      Adders:          |    Adder 0   |---------->| Adder 1 |---,
*                       +--------------+           +---------+   |
*                                                                 `--> Result
*/
class Commitment : public GadgetT
{
public:
	std::vector<EdwardsPoint> m_points;
	std::vector<VariableArrayT> m_scalars;
	std::vector<fixed_base_mul> m_multipliers;
	std::vector<PointAdder> m_adders;

	Commitment(
		ProtoboardT& in_pb,
		const Params& in_params,
		const std::vector<EdwardsPoint> in_points,
		const std::vector<VariableArrayT> in_scalars,
		const std::string &annotation_prefix );

	const VariableT& result_x() const;

	const VariableT& result_y() const;

    void generate_r1cs_constraints();

    void generate_r1cs_witness();
};


// namespace jubjub
}

// namespace ethsnarks
}

// JUBJUB_COMMITMENT_HPP_
#endif
