#ifndef JUBJUB_DOUBLER_HPP_
#define JUBJUB_DOUBLER_HPP_

// Copyright (c) 2018 @HarryR
// License: LGPL-3.0+

#include "jubjub/params.hpp"


namespace ethsnarks {

namespace jubjub {


/**
*
* Affine doubling formulas: 2(x1,y1)=(x3,y3) where
*
*   x3 = (x1*y1+y1*x1)/(1+d*x1*x1*y1*y1)
*   y3 = (y1*y1-a*x1*x1)/(1-d*x1*x1*y1*y1)
*
* Rough guidance taken from Maxima:
*
* (%i2) factor( [x3 = (x1*y1+y1*x1)/(1+d*x1*x1*y1*y1), y3 = (y1*y1-a*x1*x1)/(1-d*x1*x1*y1*y1) ] );
*
*                                                 2       2
*                           2 x1 y1             y1  - a x1
* (%o2)             [x3 = -------------, y3 = - -------------]
*                             2   2                 2   2
*                         d x1  y1  + 1         d x1  y1  - 1
*
* (%i3) fullratsimp(optimize(%));
*
*                                  2         2
* (%o3) block([%1, %2, %3], %1 : x1 , %2 : y1 , %3 : %1 %2 d, 
*
*              2 x1 y1       %1 a - %2
*        [x3 = -------, y3 = ---------])
*              %3 + 1         %3 - 1
*
* Which translates into 6 constraints, saving one versus point addition:
*
*  alpha = x1 * x1
*  beta = y1 * y1
*  gamma = d*alpha * beta
*  delta = 2*x1 * y1
*  x3 * (gamma + 1) == delta
*  y3 * (gamma - 1) == (a*alpha - beta)
*
* Where %1 = alpha
*       %2 = beta
*       %3 = gamma
*/
class PointDoubler : public GadgetT {
public:
    const Params& m_params;

    // First input point
    const VariableT m_X1;
    const VariableT m_Y1;

    // Intermediate variables
    const VariableT m_alpha;
    const VariableT m_beta;
    const VariableT m_gamma;
    const VariableT m_delta;
    const VariableT m_X3;
    const VariableT m_Y3;

    PointDoubler(
        ProtoboardT& in_pb,
        const Params& in_params,
        const VariableT in_X,
        const VariableT in_Y,
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

// JUBJUB_ADDER_HPP_
#endif
