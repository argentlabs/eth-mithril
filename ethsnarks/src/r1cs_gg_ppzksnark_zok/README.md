# Groth16 on Ethereum

## Context

The Groth16 proof system offers better performance both on the prover and verifier side. However, limitations of the pairing precompiled contract introduced in Ethereum make implementing an efficient verifier impossible. We present a modified version of Groth16 for which the limitations of the pairing precompiled contract do not hold.

## Pairings on Ethereum

Since the Byzantium hard fork, Ethereum has enabled to compute pairing checks on ALT_BN128. A precompiled contract is defined as the following:
> Input: (a1, b1, a2, b2, ..., ak, bk) from (G_1 x G_2)^k
Output: If the length of the input is incorrect or any of the inputs are not elements of
        the respective group or are not encoded correctly, the call fails.
        Otherwise, return one if
        log_P1(a1) * log_P2(b1) + ... + log_P1(ak) * log_P2(bk) = 0
        (in F_q) and zero else.
        
With `e: (G_1 x G_2) -> (G_T)` the pairing function, the above check is equivalent to:
```
e(a1, b1) * ... * e(ak, bk) = 1
```
Note that the right side of the equation is the element 1 of `G_T`.

## The Groth16 verifier
In the Groth16 scheme, veriying a proof is done in the following way:

For a circuit over `F_p` with `p` a prime and `n` the number of public inputs:

```
vk := {alpha_beta: G_T, gamma: G_2, delta: G_2, gamma_ABC: G_1^n}
proof := {A: G_1, B: G_2, C: G_1}`
let inputs: (F_p)^n
let x: G_1 computed from vk.gamma_ABC and inputs
```

From https://eprint.iacr.org/2016/260.pdf §3.1 (pg14), the check is:
```
vk.alpha_beta = e(A, B) * e(-x, vk.gamma) * e(C, vk.delta)
```

## The issue running a Groth16 with the current precompiled contract

In the Groth16 check, the right side of the equation can be any element of `G_T` as it is computed during the setup phase, whereas in the precompiled contract, it must be 1. Therefore, we cannot use the precompiled contract as is as there's no way to pass it an arbitrary element of `G_T`.

## Modified Groth16
We propose a modified version of the scheme which is compatible with the Ethereum precompiled contract.

To do so, we note that in the Groth16 scheme, `vk.alpha_beta` is a precomputed element of `G_T` by applying the pairing function to `alpha: G_1` and `beta: G_2`. Therefore, we ignore the precomputation and define:

```
vk := {alpha: G_1, beta: G_2, gamma: G_2, delta: G_2, gamma_ABC: (G_1)^n}
```

Where
```
vk.beta := beta
vk.alpha := alpha
```
The verification then becomes:
```
e(A, B) * e(-x, vk.gamma) * e(C, vk.delta) = e(alpha, beta)
```

Which is equivalent to:
```
e(A, B) * e(-x, vk.gamma) * e(C, vk.delta) * e(-alpha, beta) = 1
```

Such a verification can be run using the available precompiled contract, at the expense of computing another pairing `e(-alpha, beta)`

We operate a final optimisation by precomputing the opposite of alpha in the setup phase, so that the final verification key is:

```
vk := {minus_alpha: G_1, beta: G_2, gamma: G_2, delta: G_2, gamma_ABC: (G_1)^n}
```
And the verification:
```
e(A, B) * e(-x, vk.gamma) * e(C, vk.delta) * e(minus_alpha, beta) = 1
```

## References

 * Groth16 paper https://eprint.iacr.org/2016/260.pdf

 * Groth16 implementation in libsnark https://github.com/scipr-lab/libsnark/tree/master/libsnark/zk_proof_systems/ppzksnark/r1cs_gg_ppzksnark

 * Specification for ALT_BN128 pairing checks on Ethereum https://github.com/ethereum/EIPs/blob/master/EIPS/eip-197.md