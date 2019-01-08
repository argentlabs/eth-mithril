/*    
    copyright 2018 to the Miximus Authors

    This file is part of Miximus.

    Miximus is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Miximus is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Miximus.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity ^0.4.24;

import "./Verifier.sol";
import "./SnarkUtils.sol";
import "./MerkleTree.sol";
import "./LongsightL.sol";


contract Miximus
{
    using MerkleTree for MerkleTree.Data;

    uint constant public AMOUNT = 1 ether;

    mapping (uint256 => bool) public nullifiers;

    MerkleTree.Data internal tree;


    function GetRoot()
        public view returns (uint256)
    {
        return tree.GetRoot();
    }


    /**
    * Returns leaf offset
    */
    function Deposit(uint256 leaf)
        public payable returns (uint256 new_root, uint256 new_offset)
    {
        require( msg.value == AMOUNT );

        return tree.Insert(leaf);
    }


    function MakeLeafHash(uint256 spend_preimage, uint256 nullifier)
        public pure returns (uint256)
    {
        uint256[10] memory round_constants;
        LongsightL.ConstantsL12p5(round_constants);

        uint256 spend_hash = LongsightL.LongsightL12p5_MP([spend_preimage, nullifier], 0, round_constants);

        return LongsightL.LongsightL12p5_MP([nullifier, spend_hash], 0, round_constants);
    }


    function GetPath(uint256 leaf)
        public view returns (uint256[29] out_path, bool[29] out_addr)
    {
        return tree.GetProof(leaf);
    }


    function GetExtHash()
        public view returns (uint256)
    {
        return uint256(sha256(
            abi.encodePacked(
                address(this),
                msg.sender
            ))) % Verifier.ScalarField();
    }


    function IsSpent(uint256 nullifier)
        public view returns (bool)
    {
        return nullifiers[nullifier];
    }


    function VerifyProof( uint256 in_root, uint256 in_nullifier, uint256 in_exthash, uint256[8] proof )
        public view returns (bool)
    {
        uint256[] memory snark_input = new uint256[](3);
        snark_input[0] = in_root;
        snark_input[1] = in_nullifier;
        snark_input[2] = in_exthash;

        uint256[14] memory vk;
        uint256[] memory vk_gammaABC;
        (vk, vk_gammaABC) = GetVerifyingKey();

        return Verifier.Verify( vk, vk_gammaABC, proof, snark_input );
    }


    function Withdraw(
        uint256 in_root,
        uint256 in_nullifier,
        uint256[8] proof
    )
        public
    {
        require( false == nullifiers[in_nullifier] );

        bool is_valid = VerifyProof(in_root, in_nullifier, GetExtHash(), proof);

        require( is_valid );

        nullifiers[in_nullifier] = true;

        msg.sender.transfer(AMOUNT);
    }


    function GetVerifyingKey ()
        public view returns (uint256[14] out_vk, uint256[] out_gammaABC);
}
