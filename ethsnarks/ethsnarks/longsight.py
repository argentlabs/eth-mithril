# Copyright (c) 2018 HarryR
# License: LGPL-3.0+

"""
https://eprint.iacr.org/2016/492.pdf
https://eprint.iacr.org/2016/542.pdf
https://github.com/zcash/zcash/issues/2233
https://keccak.team/files/SpongeIndifferentiability.pdf

Where the field F_p is prime, it needs to be assured that
the cubing in the round function creates a permutation.
For this is, it is sufficient to require gcd(n, p-1) = 1

p = curve_order = 21888242871839275222246405745257275088548364400416034343698204186575808495617
e = 5
gcd(e, p-1) = 1

The number of rounds for constructing the keyed permutation is

    r = int(log2(p)/log2(3)) + 1 = 161
    r = math.ceil(log(p, 3)) + 1 = 161
"""

from __future__ import print_function

import math
from binascii import unhexlify
from random import randint

from hashlib import sha256

from .field import SNARK_SCALAR_FIELD


def random_element():
    return randint(1, SNARK_SCALAR_FIELD-1)


def int_to_big_endian(lnum):
    if lnum == 0:
        return b'\0'
    s = hex(lnum)[2:].rstrip('L')
    if len(s) & 1:
        s = '0' + s
    return unhexlify(s)


def zpad(x, l):
    return (b'\0' * max(0, l - len(x))) + x


def uint256be(num):
    return zpad(int_to_big_endian(num), 32)


def make_constants(name, n):
    """
    Generate round constants for a prime field algorithm

        seed = int(sha256("$name$n"))
        for i in range(0, n):
            constant[i] = int(sha256(seed + i)) % p

    Bytes are converted to integers in big-endian format

    @param name Name of algorithm
    @param p Field modulus
    @param e Exponent used in the algorithm
    @param n Number of constants
    """
    output = []
    name = ("%s%d" % (name, n)).encode('ascii')
    seed = int.from_bytes(sha256(name).digest(), 'big')
    for i in range(0, n):
        round_bytes = sha256(uint256be(seed + i)).digest()
        output.append(int.from_bytes(round_bytes, 'big') % SNARK_SCALAR_FIELD)
    return name, output


def _constants_cxx_format(name, constants_list):
    """
    Convert constants into a C++ function which populates a vector with them
    """
    output = "template<typename FieldT>\nvoid %s_constants_fill( std::vector<FieldT> &round_constants )\n{\n" % (name,)
    output += "\tround_constants.resize(%d);\n" % (len(constants_list),)
    for i, constant in enumerate(constants_list):
        output += "\tround_constants[%d] = FieldT(\"%d\");\n" % (i, constant)
    output += "}\n"
    output += """
template<typename FieldT>
const std::vector<FieldT> %s_constants_assign( )
{
    std::vector<FieldT> round_constants;

    %s_constants_fill<FieldT>(round_constants);

    return round_constants;
}""" % (name, name,)
    return output


def make_constants_cxx(name, n):
    return _constants_cxx_format(*make_constants(name, n))


def LongsightL(x, k, C, R, e, p):
    """
    @param x input
    @param k key
    @param C constants
    @param R number of rounds
    @param e exponent
    @param p field prime
    """
    assert math.gcd(p-1, e) == 1       # XXX: is a bijection required?
    assert len(C) == R - 2
    assert x >= 0 and x < (p-1)
    if k != 0:
        assert k > 0 and k < (p-1)

    x_i = x

    for i, C_i in enumerate([0] + C):
        t = (x_i + k + C_i) % p
        x_i = pow(t, e, p)

    y = (x_i + k) % p

    return y


def LongsightL12p5(x, k):
    p = SNARK_SCALAR_FIELD
    e = 5
    r = 12
    _, C = make_constants("LongsightL", r-2)
    return LongsightL(x, k, C, r, e, p)


def MiyaguchiPreneel_OWF(M, IV, fn, p):
    """
    The Miyaguchi–Preneel single-block-length one-way compression
    function is an extended variant of Matyas–Meyer–Oseas. It was
    independently proposed by Shoji Miyaguchi and Bart Preneel.

    H_i = E_{H_{i-1}}(m_i) + {H_{i-1}} + m_i

    or..

                 m_i
                  |
                  |----,
                  |    |
                  v    |
    H_{i-1}--,-->[E]   |
             |    |    |
             `-->(+)<--'
                  |
                  v
                 H_i

    @param M list of inputs
    @param IV initial key
    @param C constants
    @param fn Keyed hash function or block cipher
    """
    assert isinstance(M, (list, tuple))
    assert len(M) > 1
    k_i = IV
    H_i = 0
    for m_i in M:
        k_i = fn(m_i, k_i)
        H_i = (H_i + m_i + k_i) % p
        k_i = H_i
    return H_i


def LongsightL12p5_MP(M, IV):
    return MiyaguchiPreneel_OWF(M, IV, LongsightL12p5, SNARK_SCALAR_FIELD)


if __name__ == "__main__":
    print(make_constants_cxx("LongsightL", 12))
