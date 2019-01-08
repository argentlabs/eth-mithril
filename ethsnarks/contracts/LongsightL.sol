// Copyright (c) 2018 HarryR
// License: LGPL-3.0+

pragma solidity ^0.4.24;

library LongsightL
{
    // altBN curve order
    uint256 constant public SCALAR_FIELD = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;

    function GetScalarField()
        internal pure returns (uint256)
    {
        return SCALAR_FIELD;
    }

    /**
    * x = (x + k + c)^5
    */
    function LongsightL_round( uint256 in_x, uint256 in_k, uint256 in_C )
        internal pure returns (uint256 out_x)
    {
        assembly {
            let localQ := 0x30644E72E131A029B85045B68181585D2833E84879B9709143E1F593F0000001
            let t := addmod(addmod(in_x, in_C, localQ), in_k, localQ)
            let j := mulmod(t, t, localQ)
            out_x := mulmod(mulmod(j, j, localQ), t, localQ)
        }
    }


    /**
    * According to MiMC paper, first and last round constants must be zero, so for 12 rounds, require 10 constants
    */
    function LongsightL12p5( uint256 in_x, uint256 in_k, uint256[10] memory C )
        internal pure returns(uint256)
    {
        require( C.length == 10 );

        uint256 i;

        // TODO: convert to assembly for faster running / lower gas

        in_x = LongsightL_round(in_x, in_k, 0);

        for (i = 0; i < 10; i++) {
            in_x = LongsightL_round(in_x, in_k, C[i]);
        }

        return addmod(in_x, in_k, SCALAR_FIELD);
    }


    /**
    * The Miyaguchi–Preneel single-block-length one-way compression
    * function is an extended variant of Matyas–Meyer–Oseas. It was
    * independently proposed by Shoji Miyaguchi and Bart Preneel.
    * 
    * H_i = E_{H_{i-1}}(m_i) + {H_{i-1}} + m_i
    * 
    * or..
    *
    *              m_i
    *               |
    *               |----,
    *               v    |
    * H_{i-1}----->[E]   |
    *          |    |    |
    *          `-->(+)<--'
    *               |
    *               v
    *              H_i
    *
    * @param in_M list of inputs
    * @param in_IV initial key
    * @param in_C constants
    */
    function LongsightL12p5_MP( uint256[2] memory in_M, uint256 in_IV, uint256[10] memory in_C )
        internal pure returns (uint256 H_i)
    {
        uint256 i;
        uint256 k_i = in_IV;
        H_i = 0;

        for (i = 0; i < in_M.length; i++) {
            k_i = LongsightL12p5(in_M[i], k_i, in_C);
            H_i = addmod(H_i, in_M[i], SCALAR_FIELD);
            H_i = addmod(H_i, k_i, SCALAR_FIELD);
            k_i = H_i;
        }
    }


    function ConstantsL12p5( uint256[10] memory round_constants )
        internal pure
    {
        round_constants[0] = 11320456767883992575540216531659159576888907600959638766206030019748976127606;
        round_constants[1] = 7981126051239707003404038749078222981671967097536451175036296852326189803512;
        round_constants[2] = 7177016095912962923423600183006851057882812872551720265919580867301753242163;
        round_constants[3] = 8098911980008466624346445261656915633454189000125625847988658771331954170343;
        round_constants[4] = 1032632784196571780292853138329928818496444871110283900956706333284256874691;
        round_constants[5] = 17559578801496357866545202012242818709850618304526541533401975266004490452593;
        round_constants[6] = 20105898635002360807557831381163536261238002929830115424973371306325234092701;
        round_constants[7] = 9821031787055617703014732039788161451595861640101098344778391103120052870883;
        round_constants[8] = 13594207757815484006858931156275898631089441276351317178509382393302956999941;
        round_constants[9] = 18368721345647595535348572980589403703594399342587924949617577258470281904352;
    }
}
