// This is an open source non-commercial project. Dear PVS-Studio, please check it.
// PVS-Studio Static Code Analyzer for C, C++ and C#: http://www.viva64.com

#ifndef ETHSNARKS_MIMC_HPP_
#define ETHSNARKS_MIMC_HPP_

#include "ethsnarks.hpp"
#include "utils.hpp"
#include "gadgets/onewayfunction.hpp"
#include "sha3.h"
#include <mutex>

namespace ethsnarks
{

/*
* First round
*
*            x    k
*            |    |
*            |    |
*           (+)---|     X[0] = x + k
*            |    |
*    C[0] --(+)   |     Y[0] = X[0] + C[0]
*            |    |
*          (n^7)  |     Z[0] = Y[0]^7
*            |    |
******************************************
* i'th round
*            |    |
*           (+)---|     X[i] = Z[i-1] + k  
*            |    |
*    C[i] --(+)   |     Y[i] = X[i] + C[i]
*            |    |
*          (n^7)  |     Z[i] = Y[i]^7
*            |    |
******************************************
* Last round
*            |    |
*           (+)---'     result = Z.back() + k
*            |
*          result
*/

#define MIMC_ROUNDS 91
#define MIMC_SEED "mimc"

class MiMCe7_round : public GadgetT
{
  public:
    const VariableT x;
    const VariableT k;
    const FieldT &C;
    const bool add_k_to_result;
    const VariableT a;
    const VariableT b;
    const VariableT c;
    const VariableT d;

  public:
    MiMCe7_round(
        ProtoboardT &pb,
        const VariableT in_x,
        const VariableT in_k,
        const FieldT &in_C,
        const bool in_add_k_to_result,
        const std::string &annotation_prefix) : GadgetT(pb, annotation_prefix),
                                                x(in_x), k(in_k), C(in_C),
                                                add_k_to_result(in_add_k_to_result),
                                                a(make_variable(pb, FMT(annotation_prefix, ".a"))),
                                                b(make_variable(pb, FMT(annotation_prefix, ".b"))),
                                                c(make_variable(pb, FMT(annotation_prefix, ".c"))),
                                                d(make_variable(pb, FMT(annotation_prefix, ".d")))
    {
    }

    const VariableT &result() const
    {
        return d;
    }

    void generate_r1cs_constraints()
    {
        auto t = x + k + C;
        this->pb.add_r1cs_constraint(ConstraintT(t, t, a), ".a = t*t"); // x^2
        this->pb.add_r1cs_constraint(ConstraintT(a, a, b), ".b = a*a"); // x^4
        this->pb.add_r1cs_constraint(ConstraintT(a, b, c), ".c = a*b"); // x^6

        if (add_k_to_result)
        {
            this->pb.add_r1cs_constraint(ConstraintT(t, c, d - k), ".d = (c*t) + k"); // x^7
        }
        else
        {
            this->pb.add_r1cs_constraint(ConstraintT(t, c, d), ".d = c*t"); // x^7
        }
    }

    void generate_r1cs_witness() const
    {
        const auto val_k = this->pb.val(k);
        const auto t = this->pb.val(x) + val_k + C;

        const auto val_a = t * t;
        this->pb.val(a) = val_a;

        const auto val_b = val_a * val_a;
        this->pb.val(b) = val_b;

        const auto val_c = val_a * val_b;
        this->pb.val(c) = val_c;

        const FieldT result = (val_c * t) + (add_k_to_result ? val_k : FieldT::zero());
        this->pb.val(d) = result;
    }
};

class MiMCe7_gadget : public GadgetT
{
  public:
    std::vector<MiMCe7_round> m_rounds;
    const VariableT k;

    void _setup_gadgets(
        const VariableT in_x,
        const VariableT in_k,
        const std::vector<FieldT> &in_round_constants)
    {
        m_rounds.reserve(in_round_constants.size());

        for (size_t i = 0; i < in_round_constants.size(); i++)
        {
            const auto &round_x = (i == 0 ? in_x : m_rounds.back().result());

            bool is_last = (i == (in_round_constants.size() - 1));

            m_rounds.emplace_back(this->pb, round_x, in_k, in_round_constants[i], is_last, FMT(annotation_prefix, ".round[%d]", i));
        }
    }

  public:
    MiMCe7_gadget(
        ProtoboardT &pb,
        const VariableT in_x,
        const VariableT in_k,
        const std::vector<FieldT> &in_round_constants,
        const std::string &annotation_prefix) : GadgetT(pb, annotation_prefix),
                                                k(in_k)
    {
        _setup_gadgets(in_x, in_k, in_round_constants);
    }

    MiMCe7_gadget(
        ProtoboardT &pb,
        const VariableT in_x,
        const VariableT in_k,
        const std::string &annotation_prefix) : GadgetT(pb, annotation_prefix),
                                                k(in_k)
    {
        _setup_gadgets(in_x, in_k, static_constants());
    }

    const VariableT &result() const
    {
        return m_rounds.back().result();
    }

    void generate_r1cs_constraints()
    {
        for (auto &gadget : m_rounds)
        {
            gadget.generate_r1cs_constraints();
        }
    }

    void generate_r1cs_witness() const
    {
        for (auto &gadget : m_rounds)
        {
            gadget.generate_r1cs_witness();
        }
    }

    /**
    * Caches the default round constants using a static variable
    *
    * It is thread safe due to mutex lock, but must be initialised
    * after libff's number system.
    */
    static const std::vector<FieldT> &static_constants()
    {
        static bool filled = false;
        static std::vector<FieldT> round_constants;
        static std::mutex fill_lock;

        if (!filled)
        {
            fill_lock.lock();
            constants_fill(round_constants);
            filled = true;
            fill_lock.unlock();
        }

        return round_constants;
    }

    /**
    * Generate a sequence of round constants from an initial seed value.
    */
    static void constants_fill(std::vector<FieldT> &round_constants, const char *seed = MIMC_SEED, int round_count = MIMC_ROUNDS)
    {
        // XXX: replace '32' with digest size in bytes
        const size_t DIGEST_SIZE_BYTES = 32;

        round_constants.reserve(round_count);

        unsigned char output_digest[DIGEST_SIZE_BYTES];

        // Hash the initial seed
        sha3_context ctx;
        sha3_Init256(&ctx);
        sha3_Update(&ctx, seed, strlen(seed));
        memcpy(output_digest, sha3_Finalize(&ctx), DIGEST_SIZE_BYTES);

        for (int i = 0; i < round_count; i++)
        {
            // Derive a sequence of hashes to use as round constants
            sha3_Init256(&ctx);
            sha3_Update(&ctx, output_digest, DIGEST_SIZE_BYTES);
            memcpy(output_digest, sha3_Finalize(&ctx), DIGEST_SIZE_BYTES);

            // Import bytes as big-endian
            mpz_t result_as_num;
            mpz_init(result_as_num);
            mpz_import(result_as_num,     // rop
                       DIGEST_SIZE_BYTES, // count
                       1,                 // order
                       1,                 // size
                       0,                 // endian
                       0,                 // nails
                       output_digest);    // op

            // Convert to bigint, within F_p
            libff::bigint<FieldT::num_limbs> item(result_as_num);
            assert(sizeof(item.data) == DIGEST_SIZE_BYTES);
            mpz_clear(result_as_num);

            round_constants.emplace_back(item);
        }
    }

    static const std::vector<FieldT> constants(const char *seed = MIMC_SEED, int round_count = MIMC_ROUNDS)
    {
        std::vector<FieldT> round_constants;

        constants_fill(round_constants, seed, round_count);

        return round_constants;
    }
};

using MiMC_gadget = MiMCe7_gadget;

class MiMC_hash_MiyaguchiPreneel_gadget : public MiyaguchiPreneel_OWF<MiMC_gadget>
{
  public:
    using MiyaguchiPreneel_OWF<MiMC_gadget>::MiyaguchiPreneel_OWF;
};

// generic aliases for 'MiMC', masks specific implementation
using MiMC_hash_gadget = MiMC_hash_MiyaguchiPreneel_gadget;

const FieldT mimc(const std::vector<FieldT> &round_constants, const FieldT &x, const FieldT &k)
{
    ProtoboardT pb;

    const VariableT var_x = make_variable(pb, x, "x");
    const VariableT var_k = make_variable(pb, k, "k");
    pb.set_input_sizes(2);

    MiMC_gadget the_gadget(pb, var_x, var_k, round_constants, "the_gadget");
    the_gadget.generate_r1cs_witness();
    the_gadget.generate_r1cs_constraints();

    return pb.val(the_gadget.result());
}

const FieldT mimc(const FieldT &x, const FieldT &k)
{
    return mimc(MiMC_gadget::static_constants(), x, k);
}

const FieldT mimc_hash(const std::vector<FieldT> &m, const FieldT &k)
{
    ProtoboardT pb;

    std::vector<VariableT> var_m;
    var_m.reserve(m.size());
    for (const auto &m_i : m)
    {
        var_m.emplace_back(make_variable(pb, m_i, "k"));
    }

    const auto var_k = make_variable(pb, k, "k");
    pb.set_input_sizes(m.size() + 1);

    MiMC_hash_gadget the_gadget(pb, var_k, var_m, "the_gadget");
    the_gadget.generate_r1cs_witness();
    the_gadget.generate_r1cs_constraints();

    // Debug internal state of one-way-function
    /*
    int i = 0;
    for( const auto& c : the_gadget.m_ciphers )
    {
        std::cout << "k "; pb.val(c.k).print();
        std::cout << "x_i "; pb.val(c.m_rounds[0].x).print();
        std::cout << "r "; pb.val(c.m_rounds.back().result()).print();
        std::cout << "= "; pb.val(the_gadget.m_outputs[i]).print();
        std::cout << std::endl;
        i += 1;
    }
    */

    return pb.val(the_gadget.result());
}

const FieldT mimc_hash(const std::vector<FieldT> &m)
{
    return mimc_hash(m, FieldT::zero());
}

// namespace ethsnarks
} // namespace ethsnarks

// ETHSNARKS_MIMC_HPP_
#endif
