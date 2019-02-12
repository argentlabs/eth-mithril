/*    
    Mixer library used to generate Proof of Deposit
*/

#include "mixer.hpp"
#include "export.hpp"
#include "import.hpp"
#include "stubs.hpp"
#include "utils.hpp"

// handmade gadgets
#include "gadgets/sha256_ethereum.hpp"
#include "gadgets/sha256_eth_fields.hpp"

// ethsnarks gadgets
#include "gadgets/longsightl.cpp"
#include "gadgets/longsightl_constants.cpp"
#include "gadgets/merkle_tree.cpp"

using ethsnarks::FieldT;
using ethsnarks::ppT;
using ethsnarks::ProtoboardT;
using ethsnarks::ProvingKeyT;
using libff::convert_field_element_to_bit_vector;
using libsnark::generate_r1cs_equals_const_constraint;

const size_t MIXER_TREE_DEPTH = 29;

namespace ethsnarks
{

/**
* 
*/
class mod_mixer : public GadgetT
{
  public:
    typedef LongsightL12p5_MP_gadget HashT;      // MiMC - for merkle tree and nullifier
    typedef Sha256EthFields<FieldT> Sha256HashT; // SHA256 - for commitment
    // typedef LongsightL12p5_MP_gadget Sha256HashT; // MiMC - for commitment
    const size_t tree_depth = MIXER_TREE_DEPTH;

    // public inputs
    const VariableT root_var;
    const VariableT wallet_address_var;
    const VariableT nullifier_var;

    // public constants
    const VariableArrayT m_IVs; // merkle tree's IVs

    // constant inputs
    const VariableT nullifier_hash_IV;
    const VariableT leaf_hash_IV;

    // private (i.e. secret) inputs
    const VariableT nullifier_secret_var; // preimage of the nullifier
    const VariableArrayT address_bits;
    const VariableArrayT path_var;

    // logic gadgets
    HashT nullifier_hash;
    // HashT leaf_hash;
    Sha256HashT leaf_hash;
    merkle_path_authenticator<HashT> m_authenticator;

    mod_mixer(
        ProtoboardT &in_pb,
        const std::string &annotation_prefix) : GadgetT(in_pb, annotation_prefix),

                                                // public inputs
                                                root_var(make_variable(in_pb, FMT(annotation_prefix, ".root_var"))),
                                                wallet_address_var(make_variable(in_pb, FMT(annotation_prefix, ".wallet_address_var"))),
                                                nullifier_var(make_variable(in_pb, FMT(annotation_prefix, ".nullifier_var"))),

                                                // Initialisation vector for merkle tree
                                                // Hard-coded constants
                                                // Means that H('a', 'b') on level1 will have a different output than the same values on level2
                                                m_IVs(merkle_tree_IVs(in_pb)),

                                                // constant inputs
                                                nullifier_hash_IV(make_variable(in_pb, FMT(annotation_prefix, ".spend_hash_IV"))),
                                                leaf_hash_IV(make_variable(in_pb, FMT(annotation_prefix, ".leaf_hash_IV"))),

                                                // private inputs
                                                nullifier_secret_var(make_variable(in_pb, FMT(annotation_prefix, ".spend_preimage_var"))),
                                                address_bits(make_var_array(in_pb, tree_depth, FMT(annotation_prefix, ".address_bits"))),
                                                path_var(make_var_array(in_pb, tree_depth, FMT(annotation_prefix, ".path"))),

                                                // logic gadgets
                                                nullifier_hash(in_pb, nullifier_hash_IV, {nullifier_secret_var, nullifier_secret_var}, FMT(annotation_prefix, ".spend_hash")),
                                                // leaf_hash(in_pb, leaf_hash_IV, {nullifier_secret_var, wallet_address_var}, FMT(annotation_prefix, ".leaf_hash")),
                                                leaf_hash(in_pb, nullifier_secret_var, wallet_address_var),
                                                m_authenticator(in_pb, tree_depth, address_bits, m_IVs, leaf_hash.result(), root_var, path_var, FMT(annotation_prefix, ".authenticator"))
    {
        in_pb.set_input_sizes(3);

        // TODO: verify that inputs are expected publics
    }

    void generate_r1cs_constraints()
    {
        nullifier_hash.generate_r1cs_constraints();
        leaf_hash.generate_r1cs_constraints();
        m_authenticator.generate_r1cs_constraints();
        this->pb.add_r1cs_constraint(libsnark::r1cs_constraint<FieldT>(nullifier_var, 1, nullifier_hash.result()));
    }

    void generate_r1cs_witness(
        FieldT in_root,             // merkle tree root
        FieldT in_wallet_address,   // wallet address
        FieldT in_nullifier,        // unique linkable tag
        FieldT in_nullifier_secret, // nullifier preimage
        libff::bit_vector in_address,
        std::vector<FieldT> &in_path)
    {
        // public inputs
        this->pb.val(root_var) = in_root;
        this->pb.val(wallet_address_var) = in_wallet_address;
        this->pb.val(nullifier_var) = in_nullifier;

        // private inputs
        this->pb.val(nullifier_secret_var) = in_nullifier_secret;
        address_bits.fill_with_bits(this->pb, in_address);

        for (size_t i = 0; i < tree_depth; i++)
        {
            this->pb.val(path_var[i]) = in_path[i];
        }

        // gadgets
        nullifier_hash.generate_r1cs_witness();
        leaf_hash.generate_r1cs_witness();
        m_authenticator.generate_r1cs_witness();
    }
};

// namespace ethsnarks
} // namespace ethsnarks

size_t mixer_tree_depth(void)
{
    return MIXER_TREE_DEPTH;
}

char *mixer_prove(
    const char *pk_file,
    const char *in_root,
    const char *in_wallet_address,
    const char *in_nullifier,
    const char *in_nullifier_secret,
    const char *in_address, // [LSB...MSB] with regard to bits of index
    const char **in_path)
{
    // std::cout << "ENTERING mixer_prove" << std::endl;
    // std::cout << "pk_file: " << pk_file << std::endl;
    // std::cout << "in_root: " << in_root << std::endl;
    // std::cout << "in_wallet_address: " << in_wallet_address << std::endl;
    // std::cout << "in_nullifier: " << in_nullifier << std::endl;
    // std::cout << "in_nullifier_secret: " << in_nullifier_secret << std::endl;
    // std::cout << "in_address: " << in_address << std::endl;
    // std::cout << "in_path: " << std::endl
    //           << "[";
    // for (size_t j = 0; in_path[j] != nullptr; j++)
    // {
    //     std::cout << " \"" << in_path[j];
    //     if (in_path[j + 1] == nullptr)
    //     {
    //         std::cout << "\"]" << std::endl;
    //     }
    //     else
    //     {
    //         std::cout << "\"," << std::endl;
    //     }
    // }

    ppT::init_public_params();

    FieldT arg_root(in_root);
    FieldT arg_wallet_address(in_wallet_address);
    FieldT arg_nullifier(in_nullifier);
    FieldT arg_nullifier_secret(in_nullifier_secret);

    // Fill address bits with 0s and 1s from str
    libff::bit_vector address_bits;
    address_bits.resize(MIXER_TREE_DEPTH);
    if (strlen(in_address) != MIXER_TREE_DEPTH)
    {
        std::cerr << "Address length doesnt match depth" << std::endl;
        return nullptr;
    }
    for (size_t i = 0; i < MIXER_TREE_DEPTH; i++)
    {
        if (in_address[i] != '0' and in_address[i] != '1')
        {
            std::cerr << "Address bit " << i << " invalid, unknown: " << in_address[i] << std::endl;
            return nullptr;
        }
        address_bits[i] = '0' - in_address[i];
    }

    // Fill path from field elements from in_path
    std::vector<FieldT> arg_path;
    arg_path.resize(MIXER_TREE_DEPTH);
    for (size_t i = 0; i < MIXER_TREE_DEPTH; i++)
    {
        assert(in_path[i] != nullptr);
        arg_path[i] = FieldT(in_path[i]);
    }

    ProtoboardT pb;
    ethsnarks::mod_mixer mod(pb, "module");
    mod.generate_r1cs_constraints();
    std::cout << "Number of constraints for Argent Mixer: " << pb.num_constraints() << std::endl;

    mod.generate_r1cs_witness(arg_root, arg_wallet_address, arg_nullifier, arg_nullifier_secret, address_bits, arg_path);

    if (!pb.is_satisfied())
    {
        std::cerr << "Not Satisfied!" << std::endl;
        return nullptr;
    }

    auto json = ethsnarks::stub_prove_from_pb(pb, pk_file);

    return ::strdup(json.c_str());
}

int mixer_genkeys(const char *pk_file, const char *vk_file)
{
    return ethsnarks::stub_genkeys<ethsnarks::mod_mixer>(pk_file, vk_file);
}

bool mixer_verify(const char *vk_json, const char *proof_json)
{
    return ethsnarks::stub_verify(vk_json, proof_json);
}
