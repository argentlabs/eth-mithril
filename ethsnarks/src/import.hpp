#ifndef ETHSNARKS_IMPORT_HPP_
#define ETHSNARKS_IMPORT_HPP_

#include "ethsnarks.hpp"

#include <boost/property_tree/ptree.hpp>

#include "r1cs_gg_ppzksnark_zok/r1cs_gg_ppzksnark_zok.hpp"


namespace ethsnarks {

using PropertyTreeT = boost::property_tree::ptree;


/**
* Loads a ppT::Fq_type from a string, allows for integer, hex or binary encoding
* Prefix with 0x for hex and 0b for binary
*/
template<typename T>
T parse_bigint(std::string &input)
{
    mpz_t value;
    int value_error;

    ::mpz_init(value);

    // the '0' flag means auto-detect, e.g. '0x' or '0b' prefix for hex/binary
    value_error = ::mpz_set_str(value, input.c_str(), 0);
    if( value_error ) {
        throw std::invalid_argument("Invalid field element");
    }

    T out(value);
    ::mpz_clear(value);

    return out;
}

FqT parse_Fq(std::string &input);
FieldT parse_FieldT(std::string &input);


std::vector<FieldT> create_F_list_from_ptree( PropertyTreeT &in_tree, const char *in_key );

/**
* Pair which represents a proof and its inputs
*/
using InputProofPairType = std::pair< PrimaryInputT, ProofT >;

VerificationKeyT vk_from_json( std::stringstream &in_json );

VerificationKeyT vk_from_tree( PropertyTreeT &in_tree );

InputProofPairType proof_from_json( std::stringstream &in_json );

InputProofPairType proof_from_tree( PropertyTreeT &in_tree );

G2T create_G2_from_ptree( PropertyTreeT &in_tree, const char *in_key );

std::vector<G1T> create_G1_list_from_ptree( PropertyTreeT &in_tree, const char *in_key );

G1T create_G1_from_ptree( PropertyTreeT &in_tree, const char *in_key );

G2T create_G2(std::string &in_X_c1, std::string &in_X_c0, std::string &in_Y_c1, std::string &in_Y_c0);

G1T create_G1(std::string &in_X, std::string &in_Y);

std::vector<FieldT> create_F_list_from_ptree( PropertyTreeT &in_tree, const char *in_key );

// ethsnarks
}

// ETHSNARKS_IMPORT_HPP_
#endif
