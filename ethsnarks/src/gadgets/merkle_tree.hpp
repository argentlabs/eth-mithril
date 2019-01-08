#ifndef ETHSNARKS_MERKLE_TREE_HPP_
#define ETHSNARKS_MERKLE_TREE_HPP_

#include "ethsnarks.hpp"

namespace ethsnarks {


/**
* Depending on the address bit, output the correct left/right inputs
* for the merkle path authentication hash
*
* 0 = left
* 1 = right
*
* There are two variables which make up each element of the path,
* the `input` and the `pathvar`, the input is the leaf or the
* output from the last hash, and the path var is part of the merkle
* tree path.
*
* The `is_right` parameter decides if the `input` is on the left or
* right of the hash. These are decided in-circuit using the following
* method:
*
* Left:
*  (is_right * input) + ((1 - is_right) * pathvar)
*
* Right:
*  ((1 - is_right) * input) + (is_right * pathvar)
*
* Each component is split into a & b sides, then added together
* so the correct variable ends up in the right or left hand side.
*/
class merkle_path_selector : public GadgetT
{
public:
    const VariableT m_input;
    const VariableT m_pathvar;
    const VariableT m_is_right;

    VariableT m_left_a;
    VariableT m_left_b;
    VariableT m_left;

    VariableT m_right_a;
    VariableT m_right_b;
    VariableT m_right;

    merkle_path_selector(
        ProtoboardT &in_pb,
        const VariableT in_input,
        const VariableT in_pathvar,
        const VariableT in_is_right,
        const std::string &in_annotation_prefix=""
    );

    void generate_r1cs_constraints();

    void generate_r1cs_witness();

    const VariableT& left() const;

    const VariableT& right() const;
};


const VariableArrayT merkle_tree_IVs (ProtoboardT &in_pb);


template<typename HashT>
class markle_path_compute : public GadgetT
{
public:
    const size_t m_depth;
    const VariableArrayT m_address_bits;
    const VariableT m_leaf;
    const VariableArrayT m_path;

    std::vector<merkle_path_selector> m_selectors;
    std::vector<HashT> m_hashers;

    markle_path_compute(
        ProtoboardT &in_pb,
        const size_t in_depth,
        const VariableArrayT in_address_bits,
        const VariableArrayT in_IVs,
        const VariableT in_leaf,
        const VariableArrayT in_path,
        const std::string &in_annotation_prefix = ""
    ) :
        GadgetT(in_pb, FMT(in_annotation_prefix, " merkle_path_authenticator")),
        m_depth(in_depth),
        m_address_bits(in_address_bits),
        m_leaf(in_leaf),
        m_path(in_path)
    {
        assert( in_depth > 0 );
        assert( in_address_bits.size() == in_depth );
        assert( in_IVs.size() >= in_depth );

        for( size_t i = 0; i < m_depth; i++ )
        {
            if( i == 0 )
            {
                m_selectors.push_back(
                    merkle_path_selector(
                        in_pb, in_leaf, in_path[i], in_address_bits[i],
                        FMT(this->annotation_prefix, ".selector_%zu", i)));
            }
            else {
                m_selectors.push_back(
                    merkle_path_selector(
                        in_pb, m_hashers.back().result(), in_path[i], in_address_bits[i],
                        FMT(this->annotation_prefix, ".selector_%zu", i)));
            }

            m_hashers.push_back(HashT(
                in_pb, in_IVs[i],
                {m_selectors[i].left(), m_selectors[i].right()},
                FMT(this->annotation_prefix, " hasher_%zu", i)));
        }
    }

    const VariableT result() const
    {
        assert( m_hashers.size() > 0 );

        return m_hashers.back().result();
    }

    void generate_r1cs_constraints()
    {
        size_t i;
        for( i = 0; i < m_hashers.size(); i++ )
        {
            m_selectors[i].generate_r1cs_constraints();
            m_hashers[i].generate_r1cs_constraints();
        }
    }

    void generate_r1cs_witness()
    {
        size_t i;
        for( i = 0; i < m_hashers.size(); i++ )
        {
            m_selectors[i].generate_r1cs_witness();
            m_hashers[i].generate_r1cs_witness();
        }
    }
};


/**
* Merkle path authenticator, verifies computed root matches expected result
*/
template<typename HashT>
class merkle_path_authenticator : public markle_path_compute<HashT>
{
public:
    const VariableT m_expected_root;

    merkle_path_authenticator(
        ProtoboardT &in_pb,
        const size_t in_depth,
        const VariableArrayT in_address_bits,
        const VariableArrayT in_IVs,
        const VariableT in_leaf,
        const VariableT in_expected_root,
        const VariableArrayT in_path,
        const std::string &in_annotation_prefix = ""
    ) :
        markle_path_compute<HashT>::markle_path_compute(in_pb, in_depth, in_address_bits, in_IVs, in_leaf, in_path, in_annotation_prefix),
        m_expected_root(in_expected_root)
    { }

    bool is_valid() const
    {
        return this->pb.val(markle_path_compute<HashT>::result()) == this->pb.val(m_expected_root);
    }

    void generate_r1cs_constraints()
    {
        markle_path_compute<HashT>::generate_r1cs_constraints();

        // Ensure root matches calculated path hash
        this->pb.add_r1cs_constraint(
            ConstraintT(1, markle_path_compute<HashT>::result(), m_expected_root),
            FMT(this->annotation_prefix, "expected_root matches"));
    }
};


// namespace ethsnarks
}

// ETHSNARKS_MERKLE_TREE_HPP_
#endif
