#include "jubjub/fixed_base_mul_zcash.hpp"


namespace ethsnarks {

namespace jubjub {

// TODO: calculate these programmatically?
const static size_t CHUNK_SIZE_BITS = 3;
const static size_t LOOKUP_SIZE_BITS = 2;
const static size_t CHUNKS_PER_BASE_POINT = 62;


size_t fixed_base_mul_zcash::basepoints_required(size_t n_bits)
{
	return ceilf(n_bits / float(CHUNK_SIZE_BITS * CHUNKS_PER_BASE_POINT));
}


fixed_base_mul_zcash::fixed_base_mul_zcash(
	ProtoboardT &in_pb,
	const Params& in_params,
	const std::vector<EdwardsPoint>& base_points,
	const VariableArrayT& in_scalar,
	const std::string &annotation_prefix
) :
	GadgetT(in_pb, annotation_prefix)
{
	assert( in_scalar.size() > 0 );
	assert( (in_scalar.size() % CHUNK_SIZE_BITS) == 0 );
	assert( basepoints_required(in_scalar.size()) <= base_points.size());
	const int window_size_items = 1 << LOOKUP_SIZE_BITS;
	const int n_windows = in_scalar.size() / CHUNK_SIZE_BITS;

	EdwardsPoint start = base_points[0];
	// Precompute values for all lookup window tables
	for( int i = 0; i < n_windows; i++ )
	{
		std::vector<FieldT> lookup_x;
		std::vector<FieldT> lookup_y;

		if (i % CHUNKS_PER_BASE_POINT == 0) {
			start = base_points[ i / CHUNKS_PER_BASE_POINT ];
		}

		// For each window, generate 4 points, in little endian:
		// (0,0) = 0 = start = base*2^4i
		// (1,0) = 1 = 2*start
		// (0,1) = 2 = 3*start
		// (1,1) = 3 = 4*start
		EdwardsPoint current = start;
		for( int j = 0; j < window_size_items; j++ )
		{
			if (j != 0) {
				current = current.add(start, in_params);
			}
			const auto montgomery = current.as_montgomery(in_params);
			lookup_x.emplace_back(montgomery.x);
			lookup_y.emplace_back(montgomery.y);

#ifdef DEBUG
			const auto edward = montgomery.as_edwards(in_params);
			assert (edward.x == current.x);
			assert (edward.y == current.y);
#endif
		}

		const auto bits_begin = in_scalar.begin() + (i * CHUNK_SIZE_BITS);
		const VariableArrayT window_bits_x( bits_begin, bits_begin + LOOKUP_SIZE_BITS );
		const VariableArrayT window_bits_y( bits_begin, bits_begin + CHUNK_SIZE_BITS );
		// Debugging statement
		//std::cout << "window " << i << " = "; window_bits_y.get_field_element_from_bits(in_pb).print();
		m_windows_y.emplace_back(in_pb, lookup_y, window_bits_y, FMT(annotation_prefix, ".windows_y[%d]", i));		
		
		// Pass x lookup as a linear combination to avoid extra constraint.
		// x_lc = c[0] + b[0] * (c[1]-c0) + b[1] * (c[2]-c[0]) + b[0]&b[1] * (c[3] - c[2] - c[1] + c[0])
		LinearCombinationT x_lc;
		x_lc.assign(in_pb,
			LinearTermT(libsnark::ONE, lookup_x[0]) + 
			LinearTermT(window_bits_x[0], (lookup_x[1] - lookup_x[0])) +
			LinearTermT(window_bits_x[1], (lookup_x[2] - lookup_x[0])) +
			LinearTermT(m_windows_y.back().b0b1, (lookup_x[3] - lookup_x[2] - lookup_x[1] + lookup_x[0]))
		);
		m_windows_x.emplace_back(x_lc);

		// current is at 2^2 * start, for next iteration start needs to be 2^4
		start = current.dbl(in_params).dbl(in_params);
	}

	// Chain adders within one segment together via montgomery adders
	for( int i = 1; i < n_windows; i++ )
	{
		if (i % CHUNKS_PER_BASE_POINT == 0) {
			if (i + 1 < n_windows) {
				// 0th lookup will be used in the next iteration to connect
				// the first two adders of a new base point.
				continue;
			} else {
				// This is the last point. No need to add it to anything in its 
				// montgomery form, but we have to make sure it will be part of 
				// the final edwards addition at the end
				point_converters.emplace_back(
					in_pb, in_params,
					m_windows_x[i],
					m_windows_y[i].result(),
					FMT(this->annotation_prefix, ".point_conversion_segment_with_single_triplet"));
			}
		} else if( i % CHUNKS_PER_BASE_POINT == 1 ) {
			montgomery_adders.emplace_back(
				in_pb, in_params,
				m_windows_x[i-1],
				m_windows_y[i-1].result(),
				m_windows_x[i],
				m_windows_y[i].result(),
				FMT(this->annotation_prefix, ".mg_adders[%d]", i));
		}
		else {
			montgomery_adders.emplace_back(
				in_pb, in_params,
				montgomery_adders.back().result_x(),
				montgomery_adders.back().result_y(),
				m_windows_x[i],
				m_windows_y[i].result(),
				FMT(this->annotation_prefix, ".mg_adders[%d]", i));
		}
	}

	// Convert every point at the end of a segment back to edwards format
	const size_t segment_width = CHUNKS_PER_BASE_POINT - 1;
	for(size_t i = segment_width; i < montgomery_adders.size(); i += segment_width ) {
		point_converters.emplace_back(
			in_pb, in_params,
			montgomery_adders[i-1].result_x(),
			montgomery_adders[i-1].result_y(),
			FMT(this->annotation_prefix, ".point_conversion[%d]", i)
		);
	}
	// The last segment might be incomplete
	point_converters.emplace_back(
		in_pb, in_params,
		montgomery_adders.back().result_x(),
		montgomery_adders.back().result_y(),
		FMT(this->annotation_prefix, ".point_conversion_final")
	);

	// Chain adders of converted segment tails together
	for( size_t i = 1; i < point_converters.size(); i++ )
	{
		if (i == 1)
		{
			edward_adders.emplace_back(
				in_pb, in_params,
				point_converters[i-1].result_x(),
				point_converters[i-1].result_y(),
				point_converters[i].result_x(),
				point_converters[i].result_y(),
				FMT(this->annotation_prefix, ".edward_adder[%d]", i)
			);
		}
		else {
			edward_adders.emplace_back(
				in_pb, in_params,
				edward_adders[i-2].result_x(),
				edward_adders[i-2].result_y(),
				point_converters[i].result_x(),
				point_converters[i].result_y(),
				FMT(this->annotation_prefix, ".edward_adder[%d]", i)
			);
		}
	}
}

void fixed_base_mul_zcash::generate_r1cs_constraints ()
{
	for( auto& lut_y : m_windows_y ) {
		lut_y.generate_r1cs_constraints();
	}

	for( auto& adder : montgomery_adders ) {
		adder.generate_r1cs_constraints();
	}

	for( auto& converter : point_converters ) {
		converter.generate_r1cs_constraints();
	}

	for( auto& adder : edward_adders ) {
		adder.generate_r1cs_constraints();
	}
}

void fixed_base_mul_zcash::generate_r1cs_witness ()
{
	// y lookups have to be solved first, because
	// x depends on the `b0 && b1` constraint.
	for( auto& lut_y : m_windows_y ) {
		lut_y.generate_r1cs_witness();
	}

	for( auto& lut_x : m_windows_x ) {
		lut_x.evaluate(this->pb);
	}

	for( auto& adder : montgomery_adders ) {
		adder.generate_r1cs_witness();
	}

	for( auto& converter : point_converters ) {
		converter.generate_r1cs_witness();
	}

	for( auto& adder : edward_adders ) {
		adder.generate_r1cs_witness();
	}
}

const VariableT& fixed_base_mul_zcash::result_x() const {
	return edward_adders.size() ? edward_adders.back().result_x() : point_converters.back().result_x();
}

const VariableT& fixed_base_mul_zcash::result_y() const {
	return edward_adders.size() ? edward_adders.back().result_y() : point_converters.back().result_y();
}


// namespace jubjub
}

// namespace ethsnarks
}