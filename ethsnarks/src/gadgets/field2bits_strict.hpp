#ifndef ETHSNARKS_FIELD2BITS_STRICT_HPP_
#define ETHSNARKS_FIELD2BITS_STRICT_HPP_

#include "ethsnarks.hpp"
#include "gadgets/lookup_1bit.hpp"
#include <libsnark/gadgetlib1/gadgets/basic_gadgets.hpp>

namespace ethsnarks {


/**
* Converts a field element to bits, with strict validation that
* ensures it's less than the (hard-coded) field modulus.
*
* This allows the 254th bit to be decoded.
*
* Given an array of variable bits and an equal length array of fixed bits
* verify that the variable bits are lower than the fixed bits.
*
* Starting with the MSB, continuing to the LSB, for each pair of bits:
*
* 	If fixed bit is 1 and variable bit is 1, state is 'equal'
*   If fixed bit is 0 and variable bit is 0, state is 'equal'
*   If fixed bit is 1 and variable bit is 0, state is 'less'
*   If fixed bit is 0 and variable bit is 1, state is 'greater'
*
* The comparison continues until the state 'less' or 'greater' occurs
* any further comparisons are ignored and don't affect the result.
* The first differing bit determines the result, the default is 'equal'.
*
* The result must be 'less' for success to ensure congruency between
* the bits and the field element.
*
* f = fixed bit
* v = variable bit
*
* F(f,v) = LUT [f v] -> [equal, greater, less, equal]
*
*  0 0 -> equal 
*  0 1 -> greater
*  1 0 -> less
*  1 1 -> equal
*
* This gives us the bit-by-bit comparison, but what's necessary is
* to terminate the comparison upon the less or greater states.
* One constraint at the end must enforce the final result being 'less' or 'equal'
*
* When the desired result is less or equal to `q-1`, then 3 states can be merged
* into one, where the 'greater' state zeros any further states. This makes an
* accumulator of sorts, where the result of the next comparison is AND'd by the
* previous result. This means the current result can be multiplied by the previous
* assuming the state `greater` maps to zero, and all others are mapped to `1`.
*
* The final state will be `1` if it's less or equal than `F_q`, otherwise 0.
* The constraints necessary for this are:
*
*  current * previous = result
*
* Where if `previous` is 0 then `result` will be 0, and all following results
* will be zero.
*/
class field2bits_strict : public GadgetT
{
public:
	// Output bits
	VariableArrayT m_bits;

	// Intermediate variables & gadgets
	libsnark::packing_gadget<FieldT> m_packer;
	VariableArrayT m_results;
	std::vector<lookup_1bit_gadget> m_comparisons;

	field2bits_strict(
		ProtoboardT& in_pb,
		const VariableT in_field_element,
		const std::string& annotation_prefix
	);

	void generate_r1cs_constraints ();

    void generate_r1cs_witness ();

    /**
    * Bits of the field element
    */
    const VariableArrayT& result() const;
};


// namespace ethsnarks
}

// ETHSNARKS_FIELD2BITS_STRICT_HPP_
#endif
