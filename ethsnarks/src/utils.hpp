#ifndef ETHSNARKS_UTILS_HPP_
#define ETHSNARKS_UTILS_HPP_

#include <fstream>

#include "ethsnarks.hpp"

#include <libsnark/gadgetlib1/pb_variable.hpp>

namespace ethsnarks {


void print_bytes( const char *prefix, const size_t n_bytes, const uint8_t *in_bytes );

void print_bv( const char *prefix, const libff::bit_vector &vec );

void bv_to_bytes(const libff::bit_vector &in_bits, uint8_t *out_bytes);

bool hex_to_bytes( const char *in_hex, uint8_t *out_bytes, size_t out_sz );

int char2int( const char input );

const VariableArrayT flatten( const std::vector<VariableArrayT> &in_scalars );

std::vector<unsigned long> bit_list_to_ints(std::vector<bool> bit_list, const size_t wordsize);

/**
* Convert a sequence of integers into a sequence of bits
* You can specify the word-length for every integer separately.
*
* Usage example: int_list_to_bits({10, 238923}, {8, 16});
*/
libff::bit_vector int_list_to_bits(const std::initializer_list<unsigned long> &l, const std::initializer_list<unsigned long> &wordsizes);

/**
* Convert a sequence of bytes into a sequence of bits
*/
libff::bit_vector bytes_to_bv(const uint8_t *in_bytes, const size_t in_count);

/**
* The following document was used as reference:
* http://www.iwar.org.uk/comsec/resources/cipher/sha256-384-512.pdf
*
* 1. Pad the message in the usual way: Suppose the length of the message M,
* in bits, is L. Append the bit "1" to the end of the message, and then K
* zero bits, where K is the smallest non-negative solution to the equation
*
*   L + 1 + K ≡ 448 mod 512
*
* To this append the 64-bit block which is equal to the number L written
* in binary. For example, the (8-bit ASCII) message "abc" has length
*
*   8 * 3 = 24
*
* So it is padded with a one, then `448-(24+1) = 423` zero bits, and then
* its length to become the 512-bit padded message:
*
*   01100001 01100010 01100011 1 {00...0} {00...011000}
*                                   423        64
*
* The length of the padded message should now be a multiple of 512 bits.
*/
const std::vector<VariableArrayT> bits2blocks_padded(ProtoboardT& in_pb, const VariableArrayT& in_bits, size_t block_size);

VariableArrayT VariableArray_from_bits( ProtoboardT &in_pb, const libff::bit_vector& bits, const std::string& annotation_prefix);

void dump_pb_r1cs_constraints(const ProtoboardT& pb);


inline const VariableArrayT make_var_array( ProtoboardT &in_pb, size_t n, const std::string &annotation )
{
    VariableArrayT x;
    x.allocate(in_pb, n, annotation);
    return x;
}


/* `allocate_var_index` is private, must use this workaround... */
inline const VariableT make_variable( ProtoboardT &in_pb, const std::string &annotation )
{
    VariableT x;
    x.allocate(in_pb, annotation);
    return x;
}


/* `allocate_var_index` is private, must use this workaround... */
inline const VariableT make_variable( ProtoboardT &in_pb, const FieldT value, const std::string &annotation )
{
    VariableT x;
    x.allocate(in_pb, annotation);
    in_pb.val(x) = value;
    return x;
}


/* Multiply a variable by a static number, as a linear combination term */
inline const libsnark::pb_linear_combination<FieldT> make_linear_term( ProtoboardT &in_pb, VariableT var, FieldT coeff )
{
    libsnark::pb_linear_combination<FieldT> lc;
    lc.assign(in_pb, var * coeff);
    return lc;
}


/**
* Returns true if the value is less than its modulo negative
*/
bool is_negative( const FieldT& value );


template<typename T>
void writeToFile(std::string path, T& obj) {
    std::stringstream ss;
    ss << obj;
    std::ofstream fh;
    fh.open(path, std::ios::binary);
    ss.rdbuf()->pubseekpos(0, std::ios_base::out);
    fh << ss.rdbuf();
    fh.flush();
    fh.close();
}


template<typename T>
T loadFromFile(std::string path) {
    std::stringstream ss;
    std::ifstream fh(path, std::ios::binary);

    // TODO: more useful error if file not found
    assert(fh.is_open());

    ss << fh.rdbuf();
    fh.close();

    ss.rdbuf()->pubseekpos(0, std::ios_base::in);

    T obj;
    ss >> obj;

    return obj;
}


// namespace ethsnarks
}

#endif
