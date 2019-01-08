pragma solidity ^0.4.24;

import "./Miximus.sol";
import "./Verifier.sol";


// Please note, it saves a lot of gas to use the `vk2sol`
// utility to generate Solidity code, hard-coding the
// verifying key avoids the cost of loading from storage.

contract TestableMiximus is Miximus
{
    uint256[14] m_vk;
    uint256[] m_gammaABC;

    constructor( uint256[14] in_vk, uint256[] in_gammaABC )
        public
    {
        m_vk = in_vk;
        m_gammaABC = in_gammaABC;
    }


    function TestVerify ( uint256[14] in_vk, uint256[] vk_gammaABC, uint256[8] in_proof, uint256[] proof_inputs )
        public view returns (bool)
    {
        return Verifier.Verify(in_vk, vk_gammaABC, in_proof, proof_inputs);
    }


    function GetVerifyingKey ()
        public view returns (uint256[14] out_vk, uint256[] out_gammaABC)
    {
        return (m_vk, m_gammaABC);
    }
}
