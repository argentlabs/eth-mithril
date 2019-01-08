// Copyright (c) 2018 HarryR
// License: LGPL-3.0+

pragma solidity ^0.4.24;

library SnarkUtils
{
    function _bits(uint self, uint index, uint numBits)
        internal pure returns (uint)
    {
        require( index + numBits <= 256 );
        return (self / 2**index) & (2**numBits - 1);
    }


    /**
    * Given N input words of 256 bits each, output N words of 253 bits each
    * This works similarly to `libff::pack_int_vector_into_field_element_vector`
    *
    * Input:
    *   - D294F6E585874FE640BE4CE636E6EF9E3ADC27620AA3221FDCF5C0A7C11C6F67
    *    (1101001010010100111101101110010110000101100001110100111111100110
          0100000010111110010011001110011000110110111001101110111110011110
          0011101011011100001001110110001000001010101000110010001000011111
          1101110011110101110000001010011111000001000111000110111101100111)
    *
    * Output:
    *   - 3148911523101545054735209199478325155464765444384556179543606818372573931851
    *    (1101111011000111000100000111110010100000011101011110011101111111
          0000100010011000101010100000100011011100100001110110101110001111
          0011111011101100111011011000110011100110010011111010000001001100
          11111110010111000011010000110100111011011110010100101001011)
    *   - 7
    *    (111)
    */
    function PackWords (uint256[] in_words, uint256[] out_words)
        internal pure
    {
        uint i = 0;
        uint o;

        uint source = ReverseBits(in_words[i]);
        uint source_offset = 0;
        uint256 dest = 0;
        uint dest_offset = 0;

        for (o = 0; o < out_words.length; o++)
        {
            while (dest_offset < 253)
            {                
                uint bits_needed = 253 - dest_offset;
                uint bits_avail = 256 - source_offset;
                uint bits_to_copy;

                if (bits_needed < bits_avail)
                {
                    bits_to_copy = bits_needed;
                } else
                {
                    bits_to_copy = bits_avail;
                }

                dest |= _bits(source, source_offset, bits_to_copy) * (2**dest_offset);

                source_offset += bits_to_copy;
                dest_offset += bits_to_copy;

                // When all bits in source have been read, go to next source
                if (source_offset >= 256)
                {
                    i += 1;
                    if (i >= in_words.length) {
                        break;
                    }
                    source = ReverseBits(in_words[i]);
                    source_offset = 0;
                }
            }

            out_words[o] = dest;
            dest = 0;
            dest_offset = 0;
        }
    }


    /**
    * Reverse an N-bit quantity in parallel with 5 * lg(N) operations
    * Taken from http://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel
    */
    function ReverseBits( uint256 v )
        internal pure returns (uint256)
    {
        uint256 s = 256;
        uint256 mask = ~uint(0);

        while ((s >>= 1) > 0)
        {
            mask ^= (mask << s);
            v = ((v >> s) & mask) | ((v << s) & ~mask);
        }

        return v;
    }
}
