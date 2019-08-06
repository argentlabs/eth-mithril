// Copyright (c) 2018 HarryR
// License: LGPL-3.0+

pragma solidity ^0.5.0;

import "./MiMCpe7_generated.sol";

library MiMC_hash
{
    function getScalarField ()
        internal pure returns (uint256)
    {
        return 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    }

    function MiMCpe7_mp( uint256[] memory in_x, uint256 in_k )
        internal pure returns (uint256)
    {
        uint256 r = in_k;
        uint256 localQ = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

        for ( uint256 i = 0; i < in_x.length; i++ )
        {
            r = (r + in_x[i] + MiMCpe7_generated.MiMCpe7(in_x[i], r)) % localQ;
        }
        
        return r;
    }

    function MiMCpe7_md( uint256[] memory in_x, uint256 in_k )
        internal pure returns (uint256)
    {
        for ( uint256 i = 0; i < in_x.length; i++ )
        {
            in_k = MiMCpe7_generated.MiMCpe7(in_x[i], in_k);
        }
        
        return in_k;
    }
}
