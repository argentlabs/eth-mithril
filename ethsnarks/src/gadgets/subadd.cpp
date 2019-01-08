#include "ethsnarks.hpp"

#include "utils.hpp"

#include "gadgets/subadd.hpp"

namespace ethsnarks {

subadd_gadget::subadd_gadget(
	ProtoboardT &in_pb,
	const size_t n_bits,
	const VariableT in_A,
	const VariableT in_B,
	const VariableT in_N,
	const std::string& annotation_prefix
) :
	GadgetT(in_pb, annotation_prefix),
	A(in_A),
	B(in_B),
	N(in_N),

	// Results
	X(make_variable(in_pb, FMT(this->annotation_prefix, ".X"))),
	Y(make_variable(in_pb, FMT(this->annotation_prefix, ".Y"))),

	// A-N underflow check, A>=N
	N_lt_A(make_variable(in_pb, FMT(this->annotation_prefix, ".N < A"))),
	N_leq_A(make_variable(in_pb, FMT(this->annotation_prefix, ".N <= A"))),
	cmp_N_A(in_pb, n_bits, N, A, N_lt_A, N_leq_A, FMT(this->annotation_prefix, ".cmp_N_A")),

	// B+N overflow check, B+N < (1<<n_bits)
	Y_overflow_lt(make_variable(in_pb, FMT(this->annotation_prefix, ".Y < (1<<%zu)", n_bits))),
	Y_overflow_leq(make_variable(in_pb, FMT(this->annotation_prefix, ".Y <= (1<<%zu)", n_bits))),
	cmp_Y_overflow(in_pb, n_bits+1, Y, make_linear_term(in_pb, libsnark::ONE, FieldT("2")^n_bits), Y_overflow_lt, Y_overflow_leq, FMT(this->annotation_prefix, ".cmp_Y_overflow"))
{
	assert( (n_bits+1) <= FieldT::capacity() );
}


void subadd_gadget::generate_r1cs_constraints ()
{
	cmp_N_A.generate_r1cs_constraints();

	cmp_Y_overflow.generate_r1cs_constraints();

	this->pb.add_r1cs_constraint(
		ConstraintT(A - N, FieldT::one(), X),
			FMT(this->annotation_prefix, ".A - N == X"));

	this->pb.add_r1cs_constraint(
		ConstraintT(B + N, FieldT::one(), Y),
			FMT(this->annotation_prefix, ".B + N == Y"));

	// N <= A (or, balance >= amount)
	this->pb.add_r1cs_constraint(
		ConstraintT(N_leq_A, FieldT::one(), FieldT::one()),
			FMT(this->annotation_prefix, ".N_leq_A == 1"));

	// Y < (1<<bits), prevents overflowing a fixed-bit size
	this->pb.add_r1cs_constraint(
		ConstraintT(Y_overflow_lt, FieldT::one(), FieldT::one()),
			FMT(this->annotation_prefix, ".Y_overflow_lt == 1"));
}


void subadd_gadget::generate_r1cs_witness ()
{
	this->pb.val(X) = this->pb.val(A) - this->pb.val(N);

	this->pb.val(Y) = this->pb.val(B) + this->pb.val(N);

	cmp_N_A.generate_r1cs_witness();

	cmp_Y_overflow.generate_r1cs_witness();
}


// namespace ethsnarks
}
