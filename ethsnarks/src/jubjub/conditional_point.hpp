#ifndef JUBJUB_CONDITIONAL_POINT_HPP_
#define JUBJUB_CONDITIONAL_POINT_HPP_

// Copyright (c) 2018 @HarryR
// License: LGPL-3.0+

#include "ethsnarks.hpp"


namespace ethsnarks {

namespace jubjub {


/**
* Conditional point, depends on a bit
*
* 	If bit is zero, return infinity
* 	If bit is 1, return the given point
*
*	P2 = f(P1,b) = P1 if bit == 1 else Infinity
*/
class ConditionalPoint : public GadgetT
{
public:
	const VariableT m_x1;
	const VariableT m_y1;
	const VariableT m_x2;
	const VariableT m_y2;
	const VariableT m_bit;

	ConditionalPoint(
		ProtoboardT& in_pb,
		const VariableT in_x1,
		const VariableT in_y1,
		const VariableT in_bit,
		const std::string& annotation_prefix
	);

	const VariableT& result_x() const;

	const VariableT& result_y() const;

	void generate_r1cs_constraints();

	void generate_r1cs_witness();
};


// namespace jubjub
}

// namespace ethsnarks
}

#endif
