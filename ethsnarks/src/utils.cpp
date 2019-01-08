#include <fstream>
#include <iomanip>

#include "utils.hpp"

namespace ethsnarks {


// Copied from `int_list_to_bits`
libff::bit_vector bytes_to_bv(const uint8_t *in_bytes, const size_t in_count)
{
    libff::bit_vector res(in_count * 8);
    for( size_t i = 0; i < in_count; i++ )
    {
        for( size_t j = 0; j < 8; j++ ) {
            res[i * 8 + j] = (in_bytes[i] & (1 << (8 - 1 - j))) ? 1 : 0;
        }
    }
    return res;
}


libff::bit_vector int_list_to_bits(const std::initializer_list<unsigned long> &l, const std::initializer_list<unsigned long> &wordsizes)
{
    size_t total_bits = 0;
    for( const auto& ws : wordsizes )
    {
        total_bits += ws;
    }

    libff::bit_vector res(total_bits);
    for (size_t i = 0; i < l.size(); ++i)
    {
        const auto wordsize = *(wordsizes.begin());
        for (size_t j = 0; j < wordsize + i; ++j)
        {
            res[i*wordsize + j] = (*(l.begin()+i) & (1ul<<(wordsize-1-j)));
        }
    }
    return res;
}


std::vector<unsigned long> bit_list_to_ints(std::vector<bool> bit_list, const size_t wordsize)
{
    std::vector<unsigned long> res;
    size_t iterations = bit_list.size()/wordsize;

    for (size_t i = 0; i < iterations; ++i)
    {
        unsigned long current = 0;
        for (size_t j = 0; j < wordsize; ++j)
        {
            if (bit_list.size() == (i*wordsize+j)) {
                break;
            }

            current += (bit_list[i*wordsize+j] * (1ul<<(wordsize-1-j)));
      }

      res.push_back(current);
    }

    return res;
}



/*
* begin with the original message of length L bits
* append a single '1' bit
* append K '0' bits, where K is the minimum number >= 0 such that L + 1 + K + 64 is a multiple of 512
* append L as a 64-bit big-endian integer, making the total post-processed length a multiple of 512 bits
* So given a 512bit message, the _final_padding_512 is another block of 512 bits
* which begins with a '1' bit, and ends with a 64bit big-endian number representing '512'
*/
const std::vector<VariableArrayT> bits2blocks_padded(ProtoboardT& in_pb, const VariableArrayT& in_bits, size_t block_size)
{
    assert( (in_bits.size() % 8) == 0 );
    assert( in_bits.size() > 0 );

    size_t length_bits = 64;    // Number of bits used to append the length to the end
    std::vector<VariableArrayT> out_blocks;

    size_t total_bits = in_bits.size() + 1 + length_bits;
    if( total_bits % block_size != 0 ) {
        // Number of padding bits (K), to fill the block
        total_bits += (block_size - (total_bits % block_size));
    }
    size_t n_blocks = total_bits / block_size;

    size_t in_bits_offset = 0;
    for( size_t i = 0; i < n_blocks; i++ )
    {
        out_blocks.emplace_back();
        auto& block = out_blocks[out_blocks.size() - 1];
        block.resize(block_size);

        size_t block_end = (in_bits_offset + block_size);
        size_t bits_end = block_end;
        if( bits_end > in_bits.size() ) {
            bits_end = in_bits.size();
        }

        size_t j = 0;
        if( in_bits_offset < in_bits.size() ) {
            while( in_bits_offset < bits_end ) {
                block[j++].index = in_bits[in_bits_offset++].index;
            }
        }

        // Allocate remaining bits in the block
        while( in_bits_offset < block_end )
        {
            block[j].allocate(in_pb, FMT("padding", "[%zu]", in_bits_offset));

            // Set the bit immediately after the input bits to 1
            if( in_bits_offset == in_bits.size() ) {
                in_pb.val(block[j]) = FieldT::one();
            }

            j += 1;
            in_bits_offset += 1;
        }
    }

    auto& last_block = out_blocks[out_blocks.size() - 1];

    // Add 64bit big-endian length specifier to the end
    size_t bitlen = in_bits.size();
    const libff::bit_vector bitlen_bits = libff::int_list_to_bits({
        (bitlen >> 56) & 0xFF,
        (bitlen >> 48) & 0xFF,
        (bitlen >> 40) & 0xFF,
        (bitlen >> 32) & 0xFF,
        (bitlen >> 24) & 0xFF,
        (bitlen >> 16) & 0xFF,
        (bitlen >> 8) & 0xFF,
        bitlen & 0xFF,
    }, 8);
    size_t k = 0;
    for( size_t j = (block_size - length_bits); j < block_size; j++ )
    {
        in_pb.val(last_block[j]) = FieldT(bitlen_bits[k++]);
    }

    return out_blocks;
}


/**
* Convert a bit vector to a pb_variable_array
*/
VariableArrayT VariableArray_from_bits(
    ProtoboardT &in_pb,
    const libff::bit_vector& bits,
    const std::string& annotation_prefix )
{
    VariableArrayT out;
    out.allocate(in_pb, bits.size(), annotation_prefix);
    out.fill_with_bits(in_pb, bits);
    return out;
}


/**
* Returns true if the value is less than its modulo negative
*/
bool is_negative( const FieldT& value )
{
    // XXX: why doesn't libsnark's bigint have a comparison operator...

    mpz_t a;
    mpz_init(a);
    value.as_bigint().to_mpz(a);

    mpz_t b;
    mpz_init(b);
    const auto negated_value = -value;
    negated_value.as_bigint().to_mpz(b);

    int res = mpz_cmp(a, b);

    mpz_clear(a);
    mpz_clear(b);

    return res < 0;
}


/**
* Convert an array of variable arrays into a flat contiguous array of variables
*/
const VariableArrayT flatten( const std::vector<VariableArrayT> &in_scalars )
{
    size_t total_sz = 0;
    for( const auto& scalar : in_scalars )
        total_sz += scalar.size();

    VariableArrayT result;
    result.resize(total_sz);

    size_t offset = 0;
    for( const auto& scalar : in_scalars )
    {
        for( size_t i = 0; i < scalar.size(); i++ )
        {
            result[offset++].index = scalar[i].index;
        }
    }

    return result;
}



int char2int( const char input )
{
    if( input >= '0' && input <= '9' )
        return input - '0';

    if( input >= 'A' && input <= 'F')
        return input - 'A' + 10;

    if( input >= 'a' && input <= 'f')
        return input - 'a' + 10;

    throw std::invalid_argument("Invalid hex");
}


/**
* Decode a hexadecimal string `in_hex` representing `out_sz` bytes into `out_bytes`
* The hex string can, optionally, be prefixed with '0x'
*/
bool hex_to_bytes( const char *in_hex, uint8_t *out_bytes, size_t out_sz )
{
    if( ::strlen(in_hex) < 2 )
        return false;

    if( 0 == ::strncmp(in_hex, "0x", 2) )
        in_hex = &in_hex[2];

    size_t hex_sz = strlen(in_hex);

    if( hex_sz % 2 != 0 || (hex_sz / 2) != out_sz )
        return false;

    while( *in_hex ) {
        const char hex0 = in_hex[0];
        const char hex1 = in_hex[1];
        *out_bytes = (uint8_t)( (char2int(hex0) << 4) | char2int(hex1) );
        out_bytes += 1;
        in_hex += 2;
    }

    return true;
}


void bv_to_bytes(const libff::bit_vector &in_bits, uint8_t *out_bytes)
{
    for( auto& b : bit_list_to_ints(in_bits, 8) ) {
        *out_bytes++ = (uint8_t)b;
    }
}


void print_bv( const char *prefix, const libff::bit_vector &vec )
{
    std::cout << prefix << ": ";
    for (size_t i = 0; i < vec.size(); ++i)
    {
        std::cout << vec[i];
        if( i > 0 && i % 8 == 0 ) {
            std::cout << " ";
        }
    }
    std::cout << "\n";
}


void print_bytes( const char *prefix, const size_t n_bytes, const uint8_t *in_bytes )
{
    printf("%s: ", prefix);
    for (size_t i = 0; i < n_bytes; i++)
    {
       printf("%02X", in_bytes[i]);
    }
    printf("\n");
}


void dump_pb_r1cs_constraints(const ProtoboardT& pb)
{
#ifdef DEBUG
    auto full_variable_assignment = pb.primary_input();
    const auto auxiliary_input = pb.auxiliary_input();
    full_variable_assignment.insert(full_variable_assignment.end(), auxiliary_input.begin(), auxiliary_input.end());

    const auto cs = pb.get_constraint_system();

    unsigned int i = 0;
    for( auto& constraint : cs.constraints )
    {
        const FieldT ares = constraint.a.evaluate(full_variable_assignment);
        const FieldT bres = constraint.b.evaluate(full_variable_assignment);
        const FieldT cres = constraint.c.evaluate(full_variable_assignment);

        auto it = cs.constraint_annotations.find(i);
        printf("constraint %u (%s)\n", i++, (it == cs.constraint_annotations.end() ? "no annotation" : it->second.c_str()));
        printf("\t<a,(1,x)> = "); ares.print();
        printf("\t<b,(1,x)> = "); bres.print();
        printf("\t<c,(1,x)> = "); cres.print();
        printf("constraint was:\n");
        dump_r1cs_constraint(constraint, full_variable_assignment, cs.variable_annotations);
        printf("\n");
    }
#endif
}


// ethsnarks
}
