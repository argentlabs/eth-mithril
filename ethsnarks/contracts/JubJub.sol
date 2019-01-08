// Copyright (c) 2018 @HarryR
// Copyright (c) 2018 @yondonfu
// License: LGPL-3.0+

pragma solidity ^0.4.24;

library JubJub
{
    // A should be a square in Q
    uint256 constant public JUBJUB_A = 168700;

    // D should not be a square in Q
    uint256 constant public JUBJUB_D = 168696;

    uint256 constant public COFACTOR = 8;

    uint256 constant public Q = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    // L * COFACTOR = Curve Order
    uint256 constant public L = 2736030358979909402780800718157159386076813972158567259200215660948447373041;


    function Generator()
        internal pure returns (uint256[2])
    {
        return 
[17777552123799933955779906779655732241715742912184938656739573121738514868268,
 2626589144620713026669568689430873010625803728049924121243784502389097019475];
    }


    function submod(uint256 a, uint256 b, uint256 modulus)
        internal pure returns (uint256)
    {
        uint256 n = a;

        if (a <= b) {
            n += modulus;
        }

        return (n - b) % modulus;
    }


    function modexp(uint256 base, uint256 exponent, uint256 modulus)
        internal view returns (uint256)
    {
        uint256[1] memory output;
        uint256[6] memory input;
        input[0] = 0x20;
        input[1] = 0x20;
        input[2] = 0x20;
        input[3] = base;
        input[4] = exponent;
        input[5] = modulus;

        bool success;
        assembly {
            success := staticcall(sub(gas, 2000), 5, input, 0xc0, output, 0x20)
        }
        require(success);
        return output[0];
    }


    function inv(uint256 value, uint256 field_modulus)
        internal view returns (uint256)
    {
        return modexp(value, field_modulus - 2, field_modulus);
    }


    function scalarMult(uint256 x, uint256 y, uint256 value)
        internal view returns (uint256, uint256)
    {
        uint256[4] memory p;
        (p[0], p[1], p[2]) = pointToEac(x, y);
        p[3] = 1;

        uint256[4] memory a = [uint256(0), uint256(1), uint256(0), uint256(1)];

        uint256 i = 0;

        while (value != 0)
        {
            if ((value & 1) != 0)
            {
                a = etecAdd(a, p);
            }

            p = etecAdd(p, p);

            value = value / 2;

            i += 1;
        }

        return etecToPoint(a[0], a[1], a[2], a[3]);
    }


    /**
    * Project X,Y point to extended affine coordinates
    */
    function pointToEac( uint256 X, uint256 Y )
        internal pure returns (uint256, uint256, uint256)
    {
        return (X, Y, mulmod(X, Y, Q));
    }


    /**
    * Extended twisted edwards coordinates to extended affine coordinates
    */
    function etecToEac( uint256 X, uint256 Y, uint256 T, uint256 Z )
        internal view returns (uint256, uint256, uint256)
    {
        Z = inv(Z, Q);
        return (mulmod(X, Z, Q), mulmod(Y, Z, Q), mulmod(T, Z, Q));
    }


    /**
    * Extended twisted edwards coordinates to extended affine coordinates
    */
    function etecToPoint( uint256 X, uint256 Y, uint256 T, uint256 Z )
        internal view returns (uint256, uint256)
    {
        Z = inv(Z, Q);
        return (mulmod(X, Z, Q), mulmod(Y, Z, Q));
    }


    function eacToPoint( uint256 X, uint256 Y, uint256 T )
        internal pure returns (uint256, uint256)
    {
        return (X, Y);
    }

    /**
     * @dev Add 2 etec points on baby jubjub curve
     * x3 = (x1y2 + y1x2) * (z1z2 - dt1t2)
     * y3 = (y1y2 - ax1x2) * (z1z2 + dt1t2)
     * t3 = (y1y2 - ax1x2) * (x1y2 + y1x2)
     * z3 = (z1z2 - dt1t2) * (z1z2 + dt1t2)
     */
    function etecAdd(
        uint256[4] _p1,
        uint256[4] _p2
    ) 
        internal
        pure
        returns (uint256[4] p3)
    {
        // inf + (x,y) = (x,y)
        if (_p1[0] == 0 && _p1[1] == 1 && _p1[2] == 0 && _p1[3] == 1) {
            return _p2;
        }

        // (x,y) + inf = (x,y)
        if (_p2[0] == 0 && _p2[1] == 1 && _p2[2] == 0 && _p2[3] == 1) {
            return _p1;
        }

        assembly {
            let localQ := 0x30644E72E131A029B85045B68181585D2833E84879B9709143E1F593F0000001 
            let localA := 0x292FC
            let localD := 0x292F8 

            // A <- x1 * x2
            let a := mulmod(mload(_p1), mload(_p2), localQ)
            // B <- y1 * y2
            let b := mulmod(mload(add(_p1, 0x20)), mload(add(_p2, 0x20)), localQ)
            // C <- d * t1 * t2
            let c := mulmod(mulmod(localD, mload(add(_p1, 0x40)), localQ), mload(add(_p2, 0x40)), localQ)
            // D <- z1 * z2
            let d := mulmod(mload(add(_p1, 0x60)), mload(add(_p2, 0x60)), localQ)
            // E <- (x1 + y1) * (x2 + y2) - A - B
            let e := mulmod(addmod(mload(_p1), mload(add(_p1, 0x20)), localQ), addmod(mload(_p2), mload(add(_p2, 0x20)), localQ), localQ)
            if lt(e, add(a, 1)) {
                e := add(e, localQ)
            }
            e := mod(sub(e, a), localQ)
            if lt(e, add(b, 1)) {
                e := add(e, localQ)
            }
            e := mod(sub(e, b), localQ)
            // F <- D - C
            let f := d
            if lt(f, add(c, 1)) {
                f := add(f, localQ)
            }
            f := mod(sub(f, c), localQ)
            // G <- D + C
            let g := addmod(d, c, localQ)
            // H <- B - a * A
            let aA := mulmod(localA, a, localQ)
            let h := b
            if lt(h, add(aA, 1)) {
                h := add(h, localQ)
            }
            h := mod(sub(h, aA), localQ)

            // x3 <- E * F
            mstore(p3, mulmod(e, f, localQ))
            // y3 <- G * H
            mstore(add(p3, 0x20), mulmod(g, h, localQ))
            // t3 <- E * H
            mstore(add(p3, 0x40), mulmod(e, h, localQ))
            // z3 <- F * G
            mstore(add(p3, 0x60), mulmod(f, g, localQ))
        }
    }

    function pointAdd(uint256[2] self, uint256[2] other)
        internal view returns (uint256[2])
    {
        if (self[0] == 0 && self[1] == 0) {
            return other;
        } else if (other[0] == 0 && other[1] == 0)
        {
            return self;
        }

        uint256 x1x2 = mulmod(self[0], other[0], Q);
        uint256 y1y2 = mulmod(self[1], other[1], Q);

        // ----------------     

        //          (x1*y2 + y1*x2)
        uint256 x3_lhs = addmod(mulmod(self[0], other[1], Q), mulmod(self[1], other[0], Q), Q);

        //                                    JUBJUB_D*x1*x2*y1*y2
        uint256 dx1x2y1y2 = mulmod(mulmod(JUBJUB_D, x1x2, Q), y1y2, Q);

        //                          (Fq.ONE + JUBJUB_D*u1*u2*v1*v2)
        uint256 x3_rhs = addmod(1, dx1x2y1y2, Q);

        //                          (Fq.ONE - JUBJUB_D*u1*u2*v1*v2)
        uint256 y3_rhs = submod(1, dx1x2y1y2, Q);


        //          (y1*y2 - A*x1*x2)
        uint256 y3_lhs = submod(y1y2, mulmod(JUBJUB_A, x1x2, Q), Q);

        // ----------------

        // lhs / rhs
        return [
            // x3 = (x1*y2 + y1*x2)   / (Fq.ONE + D*x1*x2*y1*y2)
            mulmod(x3_lhs, inv(x3_rhs, Q), Q),

            // y3 = (y1*y2 - A*x1*x2) / (Fq.ONE - D*x1*x2*y1*y2)
            mulmod(y3_lhs, inv(y3_rhs, Q), Q)
        ];
    }
}
