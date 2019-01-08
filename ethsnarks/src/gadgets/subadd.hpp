#ifndef GADGET_SAFE_SUBADD_
#define GADGET_SAFE_SUBADD_

#include "ethsnarks.hpp"
#include <libsnark/gadgetlib1/gadgets/basic_gadgets.hpp>

namespace ethsnarks {

/**
* Subtract N from A, then adds to B
*
*   X = A-N
*   Y = B+N
*
* Prevents underflows and overflows, within an `n_bit` range
*
* e.g. A = 128, N=128, B=128 = overflow for 8 bits
*      A = 0, N=128, B=0 = underflow for 8 bits
*/
class subadd_gadget : public GadgetT {
public:
    const VariableT A;
    const VariableT B;
    const VariableT N;
    const VariableT X;
    const VariableT Y;

    const VariableT N_lt_A;
    const VariableT N_leq_A;
    libsnark::comparison_gadget<FieldT> cmp_N_A;

    const VariableT Y_overflow_lt;
    const VariableT Y_overflow_leq;
    libsnark::comparison_gadget<FieldT> cmp_Y_overflow;

    subadd_gadget(
        ProtoboardT &in_pb,
        const size_t n_bits,
        const VariableT in_A,
        const VariableT in_B,
        const VariableT in_N,
        const std::string& annotation_prefix
    );

    void generate_r1cs_constraints ();

    void generate_r1cs_witness ();
};


// namespace ethsnarks
}

// GADGET_SAFE_SUBADD_
#endif
