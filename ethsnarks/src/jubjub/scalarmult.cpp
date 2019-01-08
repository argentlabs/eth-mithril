#include "jubjub/scalarmult.hpp"


namespace ethsnarks {

namespace jubjub {


ScalarMult::ScalarMult(
	ProtoboardT& in_pb,
	const Params& in_params,
	const VariableT in_X1,
	const VariableT in_Y1,
	const VariableArrayT& in_scalar,
	const std::string& annotation_prefix
) :
	GadgetT(in_pb, annotation_prefix)
{
	assert( in_scalar.size() > 1 );

	conditionals.emplace_back(
		in_pb,
		in_X1, in_Y1,
		in_scalar[0],
		FMT(annotation_prefix, ".conditionals[0]"));

	for( unsigned int i = 1; i < in_scalar.size(); i++ )
	{
		if( i == 1 ) {
			doublers.emplace_back(
				in_pb, in_params,
				in_X1, in_Y1,
				FMT(this->annotation_prefix, ".doublers[%u]", i));
		}
		else {
			const auto& prev_dbl = doublers.back();
			doublers.emplace_back(
				in_pb, in_params,
				prev_dbl.result_x(), prev_dbl.result_y(),
				FMT(this->annotation_prefix, ".doublers[%u]", i));
		}

		const auto& cur_dbl = doublers.back();
		conditionals.emplace_back(
			in_pb,
			cur_dbl.result_x(), cur_dbl.result_y(),
			in_scalar[i],
			FMT(annotation_prefix, ".conditionals[%u]", i));

		if( i == 1 )
		{			
			const auto& cond_a = conditionals[i-1];
			const auto& cond_b = conditionals[i];
			adders.emplace_back(
				in_pb, in_params,
				cond_a.result_x(), cond_a.result_y(),
				cond_b.result_x(), cond_b.result_y(),
				FMT(this->annotation_prefix, ".adders[%u]", i));
		}
		else {
			const auto& cond = conditionals[i];
			const auto& adder = adders.back();
			adders.emplace_back(
				in_pb, in_params,
				adder.result_x(), adder.result_y(),
				cond.result_x(), cond.result_y(),
				FMT(this->annotation_prefix, ".adders[%u]", i));
		}
	}
}


const VariableT& ScalarMult::result_x() const
{
	return adders.back().result_x();
}


const VariableT& ScalarMult::result_y() const
{
	return adders.back().result_y();
}


void ScalarMult::generate_r1cs_constraints()
{
	for( auto& gadget : doublers )
		gadget.generate_r1cs_constraints();

	for( auto& gadget : conditionals )
		gadget.generate_r1cs_constraints();

	for( auto& gadget : adders )
		gadget.generate_r1cs_constraints();
}


void ScalarMult::generate_r1cs_witness()
{
	for( auto& gadget : doublers )
		gadget.generate_r1cs_witness();

	for( auto& gadget : conditionals )
		gadget.generate_r1cs_witness();

	for( auto& gadget : adders )
		gadget.generate_r1cs_witness();
}


// namespace jubjub
}

// namespace ethsnarks
}
