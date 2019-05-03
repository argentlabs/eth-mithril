// This is an open source non-commercial project. Dear PVS-Studio, please check it.
// PVS-Studio Static Code Analyzer for C, C++ and C#: http://www.viva64.com

#ifndef ETHSNARKS_ONEWAYFUNCTION_HPP_
#define ETHSNARKS_ONEWAYFUNCTION_HPP_

#include "ethsnarks.hpp"
#include "utils.hpp"

namespace ethsnarks
{

/**
* Implements the Merkle-Damgard scheme for turning a cipher into a
* one-way compression function. The output of the previous cipher is
* used as the key for the next message.
*/
template <class CipherT>
class MerkleDamgard_OWF : public GadgetT
{
  public:
	std::vector<CipherT> m_ciphers;
	const std::vector<VariableT> m_messages;

	MerkleDamgard_OWF(
		ProtoboardT &in_pb,
		const VariableT &in_IV,
		const std::vector<VariableT> &in_messages,
		const std::string &in_annotation_prefix) : GadgetT(in_pb, in_annotation_prefix),
												   m_messages(in_messages)
	{
		for (size_t i = 0; i < in_messages.size(); i++)
		{
			const auto &m_i = in_messages[i];

			const VariableT &round_key = (i == 0 ? in_IV : m_ciphers[i - 1].result());

			m_ciphers.emplace_back(in_pb, m_i, round_key, FMT(in_annotation_prefix, ".cipher[%d]", i));
		}
	}

	const VariableT &result() const
	{
		return m_ciphers.back();
	}

	void generate_r1cs_constraints()
	{
		for (auto &gadget : m_ciphers)
		{
			gadget.generate_r1cs_constraints();
		}
	}

	void generate_r1cs_witness() const
	{
		for (auto &gadget : m_ciphers)
		{
			gadget.generate_r1cs_witness();
		}
	}
};

template <class CipherT>
class MiyaguchiPreneel_OWF : public GadgetT
{
  public:
	std::vector<CipherT> m_ciphers;
	const std::vector<VariableT> m_messages;
	const VariableArrayT m_outputs;
	const VariableT m_IV;

	MiyaguchiPreneel_OWF(
		ProtoboardT &in_pb,
		const VariableT in_IV,
		const std::vector<VariableT> &in_messages,
		const std::string &in_annotation_prefix) : GadgetT(in_pb, in_annotation_prefix),
												   m_messages(in_messages),
												   m_outputs(make_var_array(in_pb, in_messages.size(), FMT(in_annotation_prefix, ".outputs"))),
												   m_IV(in_IV)
	{
		for (size_t i = 0; i < in_messages.size(); i++)
		{
			const auto &m_i = in_messages[i];

			const VariableT &round_key = (i == 0 ? in_IV : m_outputs[i - 1]);

			m_ciphers.emplace_back(in_pb, m_i, round_key, FMT(in_annotation_prefix, ".cipher[%d]", i));
		}
	}

	const VariableT &result() const
	{
		return m_outputs[m_outputs.size() - 1];
	}

	void generate_r1cs_constraints()
	{
		for (size_t i = 0; i < m_ciphers.size(); i++)
		{
			m_ciphers[i].generate_r1cs_constraints();
			const VariableT &round_key = (i == 0 ? m_IV : m_outputs[i - 1]);

			this->pb.add_r1cs_constraint(
				ConstraintT(
					round_key + m_ciphers[i].result() + m_messages[i],
					1,
					m_outputs[i]),
				".out = k + E_k(m_i) + m_i");
		}
	}

	void generate_r1cs_witness() const
	{
		for (size_t i = 0; i < m_ciphers.size(); i++)
		{
			m_ciphers[i].generate_r1cs_witness();

			const FieldT round_key = i == 0 ? pb.val(m_IV) : pb.val(m_outputs[i - 1]);

			this->pb.val(m_outputs[i]) = round_key + pb.val(m_ciphers[i].result()) + pb.val(m_messages[i]);
		}
	}
};

// ethsnarks
} // namespace ethsnarks

// ETHSNARKS_ONEWAYFUNCTION_HPP_
#endif
