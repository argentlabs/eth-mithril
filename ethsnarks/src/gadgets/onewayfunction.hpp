#ifndef ETHSNARKS_ONEWAYFUNCTION_HPP_
#define ETHSNARKS_ONEWAYFUNCTION_HPP_

#include "ethsnarks.hpp"

namespace ethsnarks {

template<class CipherT>
class MiyaguchiPreneel_OWF : public GadgetT
{
public:
	std::vector<CipherT> m_ciphers;
	VariableArrayT m_outputs;
	std::vector<VariableT> m_messages;
	VariableT m_IV;

	MiyaguchiPreneel_OWF(
		ProtoboardT &in_pb,
		const VariableT &in_IV,
		const std::vector<VariableT> &in_messages,
		const std::string &in_annotation_prefix=""
	) :
		GadgetT(in_pb, in_annotation_prefix),
		m_messages(in_messages),
		m_IV(in_IV)
	{
		m_outputs.allocate(in_pb, in_messages.size(), FMT(this->annotation_prefix, ".outputs"));

		int i = 0;		
		for( auto& m_i : in_messages ) {
			if( i == 0 ) {
				m_ciphers.push_back( CipherT(in_pb, m_i, in_IV, FMT(in_annotation_prefix, " Cipher_%d", i)) );
			}
			else {
				m_ciphers.push_back( CipherT(in_pb, m_i, m_outputs[i - 1], FMT(in_annotation_prefix, " Cipher_%d", i)) );
			}
			i += 1;
		}
	}

	const VariableT& result() const {
		return m_outputs[ m_outputs.size() - 1 ];
	}

	void generate_r1cs_constraints ()
	{
		size_t i;
		for( i = 0; i < m_ciphers.size(); i++ )
		{
			m_ciphers[i++].generate_r1cs_constraints();

			if( i == 0 ) {
				this->pb.add_r1cs_constraint(
					libsnark::r1cs_constraint<ethsnarks::FieldT>(
						1,
						m_ciphers[i].result() + m_messages[i],
						m_outputs[i]
						), "E(m_i) + m_i = out");
			}
			else {
				this->pb.add_r1cs_constraint(
					libsnark::r1cs_constraint<ethsnarks::FieldT>(
						1,
						m_outputs[i-1] + m_ciphers[i].result() + m_messages[i],
						m_outputs[i]
						), "E(m_i) + H_i-1 + m_i");
			}
		}
	}

	void generate_r1cs_witness ()
	{
		size_t i;
		for( i = 0; i < m_ciphers.size(); i++ )
		{
			m_ciphers[i].generate_r1cs_witness();

			if( i == 0 ) {
				this->pb.val( m_outputs[i] ) = pb.val(m_ciphers[i].result()) + pb.val(m_messages[i]);
			}
			else {
				// H_{i-1} + m_i + k_i
				this->pb.val( m_outputs[i] ) = pb.val(m_outputs[i - 1]) + pb.val(m_ciphers[i].result()) + pb.val(m_messages[i]);
			}
		}
	}
};

// ethsnarks
}

// ETHSNARKS_ONEWAYFUNCTION_HPP_
#endif
