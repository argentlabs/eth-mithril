#include "jubjub/fixed_base_mul.hpp"

namespace ethsnarks {

namespace jubjub {


fixed_base_mul::fixed_base_mul(
	ProtoboardT &in_pb,
	const Params& in_params,
	const FieldT& in_base_x,
	const FieldT& in_base_y,
	const VariableArrayT& in_scalar,
	const std::string &annotation_prefix
) :
	GadgetT(in_pb, annotation_prefix)
{
	int window_size_bits = 2;
	assert( (in_scalar.size() % window_size_bits) == 0 );
	int window_size_items = 1 << window_size_bits;
	int n_windows = in_scalar.size() / window_size_bits;

	FieldT start_x = in_base_x;
	FieldT start_y = in_base_y;
	FieldT x = in_base_x;
	FieldT y = in_base_y;

	// Precompute values for all lookup window tables
	for( int i = 0; i < n_windows; i++ )
	{
		std::vector<FieldT> lookup_x;
		std::vector<FieldT> lookup_y;

		// For each window, generate 4 points, in little endian:
		// (0,0) = 0 = 0
		// (1,0) = 1 = start 		# add
		// (0,1) = 2 = start+start	# double
		// (1,1) = 3 = 2+start 		# double and add
		for( int j = 0; j < window_size_items; j++ )
		{
			// When both bits are zero, add infinity (equivalent to zero)
			if( j == 0 ) {
				lookup_x.emplace_back(0);
				lookup_y.emplace_back(1);
				continue;
			}
			else {
				lookup_x.emplace_back(x);
				lookup_y.emplace_back(y);
			}

			// Affine addition
			// TODO: move into library
			const FieldT x1y2 = start_x * y;
			const FieldT y1x2 = start_y * x;
			const FieldT y1y2 = start_y * y;
			const FieldT x1x2 = start_x * x;
			const FieldT dx1x2y1y2 = in_params.d * x1x2 * y1y2;

			x = (x1y2 + y1x2) * (FieldT::one() + dx1x2y1y2).inverse();
			y = (y1y2 - (in_params.a * x1x2)) * (FieldT::one() - dx1x2y1y2).inverse();
		}

		const auto bits_begin = in_scalar.begin() + (i * window_size_bits);
		const VariableArrayT window_bits( bits_begin, bits_begin + window_size_bits );
		m_windows_x.emplace_back(in_pb, lookup_x, window_bits, FMT(annotation_prefix, ".windows_x[%d]", i));
		m_windows_y.emplace_back(in_pb, lookup_y, window_bits, FMT(annotation_prefix, ".windows_y[%d]", i));

		start_x = x;
		start_y = y;
	}

	// Chain adders together, adding output of previous adder with current window
	// First adder ads the first two windows together as there is no previous adder
	for( int i = 1; i < n_windows; i++ )
	{
		if( i == 1 ) {				
			m_adders.emplace_back(
				in_pb, in_params,
				m_windows_x[i-1].result(),
				m_windows_y[i-1].result(),
				m_windows_x[i].result(),
				m_windows_y[i].result(),
				FMT(this->annotation_prefix, ".adders[%d]", i));
		}
		else {
			m_adders.emplace_back(
				in_pb, in_params,
				m_adders[i-2].result_x(),
				m_adders[i-2].result_y(),
				m_windows_x[i].result(),
				m_windows_y[i].result(),
				FMT(this->annotation_prefix, ".adders[%d]", i));
		}
	}
}

void fixed_base_mul::generate_r1cs_constraints ()
{
	for( auto& lut_x : m_windows_x ) {
		lut_x.generate_r1cs_constraints();
	}

	for( auto& lut_y : m_windows_y ) {
		lut_y.generate_r1cs_constraints();
	}

	for( auto& adder : m_adders ) {
		adder.generate_r1cs_constraints();
	}
}

void fixed_base_mul::generate_r1cs_witness ()
{
	for( auto& lut_x : m_windows_x ) {
		lut_x.generate_r1cs_witness();
	}

	for( auto& lut_y : m_windows_y ) {
		lut_y.generate_r1cs_witness();
	}

	for( auto& adder : m_adders ) {
		adder.generate_r1cs_witness();
	}
}

const VariableT& fixed_base_mul::result_x() const {
	return m_adders.back().result_x();
}

const VariableT& fixed_base_mul::result_y() const {
	return m_adders.back().result_y();
}


// namespace jubjub
}

// namespace ethsnarks
}
