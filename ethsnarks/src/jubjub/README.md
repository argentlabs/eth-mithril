# (Baby) JubJub gadgets

## Gadgets

 * [adder.hpp](adder.hpp) - affine twisted Edwards point addition
 * [commitment.hpp](commitment.hpp) - Point Commitment (for Schnorr etc.)
 * [conditional_point.hpp](conditional_point.hpp) - Conditional point, if bit is 0 return Inifnity, otherwise the point
 * [doubler.hpp](doubler.hpp) - Twisted Edwards affine doubling
 * [eddsa.hpp](eddsa.hpp) - EdDSA signature verification
 * [fixed_base_mul.hpp](fixed_base_mul.hpp) - Multiply a fixed point by a variable scalar (affine twisted Edwards coordinates)
 * [fixed_base_mul_zcash.hpp](fixed_base_mul_zcash.hpp) - Multiply a fixed point by a variable scalar (ZCash scheme, for 'Pedersen Hash') 
 * [isoncurve.hpp](isoncurve.hpp) - Verify if a point is on the curve (is it valid?)
 * [montgomery.hpp](montgomery.hpp) - Montgomery point operations: `MontgomeryAdder`, `MontgomeryToEdwards`
 * [notloworder.hpp](notloworder.hpp) - Verify that point isn't a low-order point
 * [pedersen_hash.cpp](pedersen_hash.cpp) - Pedersen Hash, using ZCash scheme
 * [scalarmult.hpp](scalarmult.hpp) - Affine scalar multiplication, variable point and variable scalar
 * [validator.hpp](validator.hpp) - Point validation (IsOnCurve and NotLowOrder)


## EdDSA parameters

See: [EdDSA for more curves](https://ed25519.cr.yp.to/eddsa-20150704.pdf)

* q = 21888242871839275222246405745257275088548364400416034343698204186575808495617
* b = 255
* Encoding GF\(p\): 254-bit little-endian encoding of {0..q-1} for Fq elements
* `H` : with 2b-bit output, can be implementation specific
* c = 3 (cofactor is `2^c`, aka `8`)
* n = 254
* a = 168700
* d = 168696
* `ℓ` = 21888242871839275222246405745257275088614511777268538073601725287587578984328
* B (base point)
  * x = 16540640123574156134436876038791482806971768689494387082833631921987005038935
  *  y = 20819045374670962167435360035096875258406992893633759881276124905556507972311
* Prehash function `H'` : *"ZCash Pedersen Hash"* scheme for `M = H(m)` and `H(R,A,M)`

The base point `B` is derived deterministically from the curve parameters using the following Sage math script: [ejubjub.sage](../.appendix/ejubjub.sage)

### EdDSA details

There are two in-circuit hash functions used as part of the EdDSA implementation:

 1. `H(R,A,M)`
 2. `M = H'(m)` (for HashEdDSA)

#### Signature

An EdDSA signature on a message `M` by public key `A` is the pair `(R,S)`, encoded in 2b bits on a curve point `R ∈ E(F_q)` and an integer `0 < S < ℓ`.

    (2^c * sB) = (2^c * R) + (2^c * H(R, A, M) * A)

This is *PureEdDSA*, where there is no message compression function (`M = H'(m)`) to compress `m`.

Multiplying by the cofactor ensures that the points were all on the prime-ordered sub-group.

HashEdDSA requires an extra step to compress the message before hashing, this is: `M = H'(m)`

#### Private key

An EdDSA private key is a `b`-bit string `k` which should be chosen uniformly at random. The corresponding public key is `A = sB` where `s = H(k)` is the least significant `b` bits of `H(k)` interpreted as an integer in little-endian. The signature on message `M` is `(R,S)` where `R = rB` for `r = H(H(k),M)` and

    S = r + H(R,A,M)s (mod ℓ)

This satisfies the verification equation:

    2^C SB = 2^c (r + (H(R,A,M) * s)) B
           = 2^c rB + 2^c H(R,A,M) s B
           = 2^c R + 2^c H(R,A,M) A
