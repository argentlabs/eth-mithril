// Copyright (c) 2018 HarryR
// License: LGPL-3.0+

#pragma once

#include <libsnark/gadgetlib1/gadget.hpp>
#include <libsnark/gadgetlib1/gadgets/basic_gadgets.hpp>

using libsnark::gadget;
using libsnark::pb_variable;
using libsnark::pb_variable_array;
using libsnark::protoboard;
using libsnark::linear_combination;
using libsnark::r1cs_constraint;

/**
* Implements the polynomial from Shamir's secret-sharing scheme
*
*   f(x) = a_0 + \sum_{i=1}^{k-1} a_i x^i
*
* See: https://en.wikipedia.org/wiki/Shamir%27s_Secret_Sharing
*/
template<typename FieldT>
class shamir_poly : public gadget<FieldT>
{
public:
    protoboard<FieldT> &pb;

    const pb_variable<FieldT> &input;
    const pb_variable_array<FieldT> &alpha;

    pb_variable_array<FieldT> intermediate_squares;
    pb_variable_array<FieldT> intermediate_total;

    shamir_poly(
        protoboard<FieldT> &in_pb,
        const pb_variable<FieldT> &in_input,
        const pb_variable_array<FieldT> &in_alpha,
        const std::string &annotation_prefix=""
    ) :
        gadget<FieldT>(in_pb, FMT(annotation_prefix, " shamir_poly")),
        pb(in_pb),

        input(in_input),
        alpha(in_alpha),

        intermediate_squares(),
        intermediate_total()
    {
        assert( in_alpha.size() >= 2 );

        intermediate_squares.allocate( pb, in_alpha.size(), FMT(annotation_prefix, " intermediate_squares") );

        intermediate_total.allocate( pb, in_alpha.size(), FMT(annotation_prefix, " intermediate_total") );
    }

    const pb_variable<FieldT>
    result()
    {
        return intermediate_total[alpha.size() - 1];
    }
    
    /**
    * Constraints are:
    *
    *   A * B - C = 0
    *
    * For the intermediate squares:
    *
    *   (1     * S[0])  - 1      = 0
    *   (input * input) - S[2 ]  = 0
    *   (S[i]  * S[i])  - S[i+1] = 0
    *   ...
    *
    * For the totals:
    *
    *   (A[0] * S[0]) - T[0]            = 0
    *   (A[i] * S[i]) - (T[i] - T[i-1]) = 0
    *   ...
    *
    * For `k` rounds there are `(2*k)-1` constraints
    */
    void generate_r1cs_constraints()
    {
        linear_combination<FieldT> a1, b1, c1;

        for( size_t i = 0; i < alpha.size(); i++ )
        {            
            // Intermediate squares
            if( i == 0 ) {
                pb.add_r1cs_constraint(
                    r1cs_constraint<FieldT>(
                        FieldT::one(),
                        intermediate_squares[i],
                        FieldT::one()),
                    FMT(this->annotation_prefix, "1 * squares[%zu] = 1", i));
            }
            else if( i == 1 ) {
                // (input * input) - S[2] = 0
                pb.add_r1cs_constraint(
                    r1cs_constraint<FieldT>(
                        input,
                        input,
                        intermediate_squares[i+1]),
                    FMT(this->annotation_prefix, "input * input = squares[%zu]", i));
            }
            else if( i < (alpha.size() - 1) ) {
                // (I * S[i]) - S[i+1] = 0
                pb.add_r1cs_constraint(
                    r1cs_constraint<FieldT>(
                        input,
                        intermediate_squares[i],
                        intermediate_squares[i+1]),
                    FMT(this->annotation_prefix, "input * squares[%zu] = squares[%zu]", i, i+1));
            }

            // Totals
            if( i == 0 ) {
                // (A[0] * S[0]) - T[0] = 0
                pb.add_r1cs_constraint(
                    r1cs_constraint<FieldT>(
                        alpha[i],
                        intermediate_squares[i],
                        intermediate_total[i]),
                    FMT(this->annotation_prefix, "alpha[%zu] * squares[%zu] = total[%zu]", i, i, i));
            }
            else {
                // (A[i] * S[i]) - (T[i] - T[i-1]) = 0
                pb.add_r1cs_constraint(
                    r1cs_constraint<FieldT>(
                        alpha[i],
                        intermediate_squares[i],
                        (intermediate_total[i] - intermediate_total[i-1])),
                    FMT(this->annotation_prefix, "alpha[%zu] * squares[%zu] = (total[%zu] - total[%zu])", i, i, i, i-1));
            }
        }
    }

    /**
    * f(x) = a_0 + \sum_{i=1}^{k-1} a_i x^i
    *
    *   S[0] = 1
    *   S[1...k] = input^i
    *   T[i] = A[i] * S[i]
    *
    * Which becomes:
    *
    *   T[0] = A[0] * S[0] = A[0] * 1 = A[0]
    *   T[1] = T[0] + (A[1] * S[1]) = T[0] + (A[i] * input)
    *   T[2] = T[1] + (A[2] * S[2]) = T[1] + (A[i] * input^2)
    *   etc.
    *
    * Where
    *
    *   T = totals (intermediates)
    *   A = alpha (secret input)
    *   S = intermediate squares, used to multiply alpha to get total
    */
    void generate_r1cs_witness()
    {
        FieldT total = FieldT::zero();

        for( size_t i = 0; i < alpha.size(); i++ )
        {
            if( i == 0 ) {
                pb.val(intermediate_squares[i]) = FieldT::one();
            }
            else {
                pb.val(intermediate_squares[i]) = pb.lc_val(input)^i;
            }

            total += pb.val(alpha[i]) * pb.val(intermediate_squares[i]);

            pb.val(intermediate_total[i]) = total;
        }

    }

    void generate_r1cs_witness( const FieldT &in_input )
    {
        pb.val(input) = in_input;

        this->generate_r1cs_witness();
    }
};
