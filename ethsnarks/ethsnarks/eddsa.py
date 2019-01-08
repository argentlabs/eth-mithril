import math
import bitstring
from collections import namedtuple
from hashlib import sha512
from .field import FQ, SNARK_SCALAR_FIELD
from .jubjub import Point, JUBJUB_L, JUBJUB_Q, JUBJUB_E
from .pedersen import pedersen_hash_zcash_bytes, pedersen_hash_zcash_bits

"""
Implements Pure-EdDSA and Hash-EdDSA

The signer has two secret values:

    * k = Secret key
    * r = Per-(message,key) nonce

The signer provides a signature consiting of two values:

    * R = Point, image of `r*B`
    * s = Image of `r + (k*t)`

The signer provides the verifier with their public key:

    * A = k*B

Both the verifier and the signer calculate the common reference string:

    * t = H(R, A, M)

The nonce `r` is secret, and protects the value `s` from revealing the
signers secret key.

For Hash-EdDSA, the message `M` is compressed before H(R,A,M)

For further information see: https://ed2519.cr.yp.to/eddsa-20150704.pdf
"""


P13N_EDDSA_VERIFY_M = 'EdDSA_Verify.M'
P13N_EDDSA_VERIFY_RAM = 'EdDSA_Verify.RAM'


class Signature(object):
    __slots__ = ('R', 's')
    def __init__(self, R, s):
        self.R = R if isinstance(R, Point) else Point(*R)
        self.s = s if isinstance(s, FQ) else FQ(s)
        assert self.s.m == JUBJUB_Q

    def __iter__(self):
        return iter([self.R, self.s])

    def __str__(self):
        return ' '.join(str(_) for _ in [self.R.x, self.R.y, self.s])


class SignedMessage(namedtuple('_SignedMessage', ('A', 'sig', 'msg'))):
    pass


class _SignatureScheme(object):
    @classmethod
    def to_bytes(cls, *args):
        # TODO: move to ethsnarks.utils ?
        result = b''
        for M in args:
            if isinstance(M, list):
                result += b''.join(cls.to_bytes(_) for _ in M)
            if isinstance(M, Point):
                result += M.x.n.to_bytes(32, 'little')
            elif isinstance(M, FQ):
                result += M.n.to_bytes(32, 'little')
            elif isinstance(M, bitstring.BitArray):
                result += M.tobytes()
            elif isinstance(M, bytes):
                result += M
            else:
                raise TypeError("Bad type for M: " + str(type(M)))
        return result

    @classmethod
    def to_bits(cls, *args):
        # TODO: move to ethsnarks.utils ?
        result = bitstring.BitArray()
        for M in args:
            if isinstance(M, list):
                for _ in cls.to_bits(M):
                    result.append(_)
            if isinstance(M, Point):
                result.append(M.x.bits())
            elif isinstance(M, FQ):
                result.append(M.bits())
            elif isinstance(M, bytes):
                result.append(M)
            elif isinstance(M, bitstring.BitArray):
                result.append(M)
            else:
                raise TypeError("Bad type for M: " + str(type(M)))
        return result

    @classmethod
    def prehash_message(cls, M):
        """
        Identity function for message

        Can be used to truncate the message before hashing it
        as part of the public parameters.
        """
        return M

    @classmethod
    def hash_public(cls, R, A, M):
        """
        Identity function for public parameters:

            R, A, M

        Is used to multiply the resulting point
        """
        raise NotImplementedError()

    @classmethod
    def hash_secret(cls, k, *args):
        """
        Hash the key and message to create `r`, the blinding factor for this signature.

        If the same `r` value is used more than once, the key for the signature is revealed.

        From: https://eprint.iacr.org/2015/677.pdf (EdDSA for more curves)

        Page 3:

            (Implementation detail: To save time in the computation of `rB`, the signer
            can replace `r` with `r mod L` before computing `rB`.)
        """
        assert isinstance(k, FQ)
        data = b''.join(cls.to_bytes(_) for _ in (k,) + args)
        return int.from_bytes(sha512(data).digest(), 'little') % JUBJUB_L

    @classmethod
    def B(cls):
        return Point.generator()

    @classmethod
    def random_keypair(cls, B=None):
        B = B or cls.B()
        k = FQ.random(JUBJUB_L)
        A = B * k
        return k, A

    @classmethod
    def sign(cls, msg, key, B=None):
        if not isinstance(key, FQ):
            raise TypeError("Invalid type for parameter k")
        # Strict parsing ensures key is in the prime-order group
        if key.n >= JUBJUB_L or key.n <= 0:
            raise RuntimeError("Strict parsing of k failed")

        B = B or cls.B()
        A = B * key                       # A = kB

        M = cls.prehash_message(msg)
        r = cls.hash_secret(key, M)       # r = H(k,M) mod L
        R = B * r                         # R = rB

        t = cls.hash_public(R, A, M)      # Bind the message to the nonce, public key and message
        S = (r + (key.n*t)) % JUBJUB_E    # r + (H(R,A,M) * k)

        return SignedMessage(A, Signature(R, S), msg)

    @classmethod
    def verify(cls, A, sig, msg, B=None):
        if not isinstance(A, Point):
            A = Point(*A)

        if not isinstance(sig, Signature):
            sig = Signature(*sig)

        R, S = sig
        B = B or cls.B()
        lhs = B * S

        M = cls.prehash_message(msg)
        rhs = R + (A * cls.hash_public(R, A, M))
        return lhs == rhs


class PureEdDSA(_SignatureScheme):
    @classmethod
    def hash_public(cls, *args, p13n=P13N_EDDSA_VERIFY_RAM):
        """
        Hash used for the public parameters.

            hash_RAM = H(R,A,M)

        @returns X coordinate of point
        """
        return pedersen_hash_zcash_bits(p13n, cls.to_bits(*args)).x.n


class EdDSA(PureEdDSA):
    @classmethod
    def prehash_message(cls, M, p13n=P13N_EDDSA_VERIFY_M):
        return pedersen_hash_zcash_bytes(p13n, M)


def eddsa_tobits(*args):
    return PureEdDSA.to_bits(*args)


def eddsa_tobytes(*args):
    return PureEdDSA.to_bytes(*args)


def eddsa_random_keypair():
    return EdDSA.random_keypair()


def pureeddsa_verify(*args, **kwa):
    return PureEdDSA.verify(*args, **kwa)


def pureeddsa_sign(*args, **kwa):
    return PureEdDSA.sign(*args, **kwa)


def eddsa_verify(*args, **kwa):
    return EdDSA.verify(*args, **kwa)


def eddsa_sign(*args, **kwa):
    return EdDSA.sign(*args, **kwa)
