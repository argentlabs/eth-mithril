// Copyright (c) 2018 @HarryR
// License: LGPL-3.0+

pragma solidity ^0.4.24;

import "./JubJub.sol";


contract EdDSA
{
    function HashToInt( bytes data )
        public pure returns (uint256)
    {
        uint256 hashed = uint256(sha256(data));

        // (2<<249) - 1
        uint256 mask = 1809251394333065553493296640760748560207343510400633813116524750123642650623;

        return hashed & mask;
    }

    function Verify( uint256[2] pubkey, uint256 hashed_msg, uint256[2] R, uint256 s )
        public view returns (bool)
    {
        uint256[2] memory B = JubJub.Generator();
        uint256[2] memory lhs;
        uint256[2] memory rhs;

        (lhs[0], lhs[1]) = JubJub.scalarMult(B[0], B[1], s);

        uint256 t = HashToInt(abi.encodePacked(
            R[0], R[1],
            pubkey[0], pubkey[1],
            hashed_msg
            ));

        (rhs[0], rhs[1]) = JubJub.scalarMult(pubkey[0], pubkey[1], t);

        return lhs[0] == rhs[0] && lhs[1] == rhs[1];
    }
}
