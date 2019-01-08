// Copyright (c) 2018 @HarryR
// Copyright (c) 2018 @yondonfu
// License: LGPL-3.0+

pragma solidity ^0.4.24;

import "./JubJub.sol";

contract JubJubPublic
{
    function pointAddViaEtec(uint256[2] a, uint256[2] b)
        public view returns (uint256[2])
    {
        uint256[4] memory p;
        uint256[4] memory q;
        uint256[4] memory r;
        (p[0], p[1], p[2]) = JubJub.pointToEac(a[0], b[0]);
        (q[0], q[1], q[2]) = JubJub.pointToEac(a[0], b[0]);
        p[3] = 1;
        q[3] = 1;
        r = JubJub.etecAdd(p, q);

        (p[0], p[1]) = JubJub.etecToPoint(r[0], r[1], r[2], r[3]);
        return [p[0], p[1]];
    }

    function pointAdd(uint256[2] a, uint256[2] b)   
        public view returns (uint256[2])
    {
        return JubJub.pointAdd(a, b);
    }

    function scalarMult(uint256[2] a, uint256 s)
        public view returns (uint256, uint256)
    {
        return JubJub.scalarMult(a[0], a[1], s);
    }
}
