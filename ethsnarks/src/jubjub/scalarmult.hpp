#ifndef JUBJUB_SCALARMULT_HPP_
#define JUBJUB_SCALARMULT_HPP_

// Copyright (c) 2018 @HarryR
// License: LGPL-3.0+

#include "jubjub/adder.hpp"
#include "jubjub/doubler.hpp"
#include "jubjub/conditional_point.hpp"


namespace ethsnarks {

namespace jubjub {


/**
* Multiply a point by a scalar value
*
* 	P^n = [n]P = P + P + P ...
*
* An example of the circuit for 4 bits:
*
*    i=0           i=1          i=2          i=3
*
* -------------------------------------------------------
*
*  +-------+    +-----+      +-----+      +-----+
*  | Point |--->| DBL |----->| DBL |----->| DBL |
*  +-------+    +-----+      +-----+      +-----+
*     |            |            |            |
*     v            v            v            v
*  +------+     +------+     +------+     +------+
*  | COND |--,  | COND |--,  | COND |--,  | COND |--,
*  +------+  |  +------+  |  +------+  |  +------+  |
*     ^      |     ^      |     ^      |     ^      |
*     |      |     |      |     |      |     |      |
*  +------+  |  +------+  |  +------+  |  +------+  |
*  | Bit0 |  |  | Bit1 |  |  | Bit2 |  |  | Bit3 |  |
*  +------+  |  +------+  |  +------+  |  +------+  |
*            |            v            v            v
*            |        +-------+    +-------+    +-------+     
*            `------->| ADDER |--->| ADDER |--->| ADDER |---> Result
*                     +-------+    +-------+    +-------+
*
* -------------------------------------------------------
*
*  i=0		P*bit
*  i=1		(P*2*bit) + (P*bit)
*  i=2		(P*4*bit) + ((P*2*bit) + (P*bit))
*  etc..
*/
class ScalarMult : public GadgetT 
{
public:
	std::vector<PointDoubler> doublers;
	std::vector<ConditionalPoint> conditionals;
	std::vector<PointAdder> adders;

	ScalarMult(
		ProtoboardT& in_pb,
		const Params &in_params,
		const VariableT in_X1,
		const VariableT in_Y1,
		const VariableArrayT& in_scalar,
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
