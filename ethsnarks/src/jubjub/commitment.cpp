#include "jubjub/commitment.hpp"

namespace ethsnarks {

namespace jubjub {


Commitment::Commitment(
	ProtoboardT& in_pb,
	const Params& in_params,
	const std::vector<EdwardsPoint> in_points,
	const std::vector<VariableArrayT> in_scalars,
	const std::string& annotation_prefix
) :
	GadgetT(in_pb, annotation_prefix),
	m_points(in_points),
	m_scalars(in_scalars)
{
	assert( in_points.size() > 1 );
	assert( in_points.size() == in_scalars.size() );

	size_t i = 0;
	for( const auto& point : m_points )
	{
		m_multipliers.emplace_back(
			in_pb,
			in_params,
			point.x, point.y,
			m_scalars[i],
			FMT(this->annotation_prefix, ".multiplier[%zu]", i));

		if( i == 1 )
		{
			const auto& mult_a = m_multipliers[i-1];
			const auto& mult_b = m_multipliers[i];

			m_adders.emplace_back(
				in_pb,
				in_params,
				mult_a.result_x(), mult_a.result_y(),
				mult_b.result_x(), mult_b.result_y(),
				FMT(this->annotation_prefix, ".adder[%zu]", i - 1));
		}
		else if( i > 1 )
		{
			const auto& adder = m_adders[i-2];
			const auto& mult = m_multipliers[i];

			m_adders.emplace_back(
				in_pb,
				in_params,
				adder.result_x(), adder.result_y(),
				mult.result_x(), mult.result_y(),
				FMT(this->annotation_prefix, ".adder[%zu]", i - 1));
		}

		i += 1;
	}
}


const VariableT& Commitment::result_x() const
{
	return m_adders.back().result_x();
}


const VariableT& Commitment::result_y() const
{
	return m_adders.back().result_y();
}


void Commitment::generate_r1cs_constraints()
{
	for( auto& gadget : m_multipliers ) {
		gadget.generate_r1cs_constraints();
	}

	for( auto& gadget : m_adders ) {
		gadget.generate_r1cs_constraints();
	}
}


void Commitment::generate_r1cs_witness()
{
	for( auto& gadget : m_multipliers ) {
		gadget.generate_r1cs_witness();
	}

	for( auto& gadget : m_adders ) {
		gadget.generate_r1cs_witness();
	}
}


// namespace jubjub
}

// namespace ethsnarks
}
