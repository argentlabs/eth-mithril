#ifndef JUBJUB_NOTLOWORDER_HPP_
#define JUBJUB_NOTLOWORDER_HPP_

// Copyright (c) 2018 @HarryR
// License: LGPL-3.0+

#include "ethsnarks.hpp"
#include "gadgets/isnonzero.hpp"
#include "jubjub/doubler.hpp"

namespace ethsnarks {

namespace jubjub {


/**
* Verifies that the point is not one of the low-order points.
*
* The low-order points on this curve are:
*
*	(0, 1),
*	(4342719913949491028786768530115087822524712248835451589697801404893164183326, 4826523245007015323400664741523384119579596407052839571721035538011798951543),
*	(17545522957889784193459637215142187266023652151580582754000402781682644312291, 17061719626832259898845741003733890968968767993363194771977168648564009544074),
*	(18930368022820495955728484915491405972470733850014661777449844430438130630919, 0),
*	(2957874849018779266517920829765869116077630550401372566248359756137677864698, 0),
*	(4342719913949491028786768530115087822524712248835451589697801404893164183326, 17061719626832259898845741003733890968968767993363194771977168648564009544074),
*	(0, 21888242871839275222246405745257275088548364400416034343698204186575808495616),
*	(17545522957889784193459637215142187266023652151580582754000402781682644312291, 4826523245007015323400664741523384119579596407052839571721035538011798951543)
*
* If any of the points are doubled 3 times (multiplied by the cofactor), the resulting point
* will be infinity (0,1). This gadget verifies that the resulting x coordinate is not zero.
*/
class NotLowOrder : public GadgetT {
public:
	PointDoubler m_doubler_2;
	PointDoubler m_doubler_4;
	PointDoubler m_doubler_8;
	IsNonZero m_isnonzero;

	NotLowOrder(
		ProtoboardT& in_pb,
		const Params& in_params,
		const VariableT in_X,
		const VariableT in_Y,
		const std::string& annotation_prefix);

    void generate_r1cs_constraints();

    void generate_r1cs_witness();
};


// namespace jubjub
}

// namespace ethsnarks
}

// JUBJUB_NOTLOWORDER_HPP_
#endif
