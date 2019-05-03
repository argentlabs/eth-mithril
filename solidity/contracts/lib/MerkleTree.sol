pragma solidity ^0.5.0;

import "./MiMC.sol";

library MerkleTree
{
    // ceil(log2(1<<29))
    uint constant public TREE_DEPTH = 29;


    // 2<<28 leaves
    uint constant public MAX_LEAF_COUNT = 536870912;


    struct Data
    {
        uint cur;
        uint256[536870912][30] nodes; // first row = leaves, second row = leaves' parents, etc
    }

    function treeDepth() internal pure returns (uint256) {
        return TREE_DEPTH;
    }


    function fillLevelIVs (uint256[29] memory IVs)
        internal 
        pure
    {
        IVs[0] = 149674538925118052205057075966660054952481571156186698930522557832224430770;
        IVs[1] = 9670701465464311903249220692483401938888498641874948577387207195814981706974;
        IVs[2] = 18318710344500308168304415114839554107298291987930233567781901093928276468271;
        IVs[3] = 6597209388525824933845812104623007130464197923269180086306970975123437805179;
        IVs[4] = 21720956803147356712695575768577036859892220417043839172295094119877855004262;
        IVs[5] = 10330261616520855230513677034606076056972336573153777401182178891807369896722;
        IVs[6] = 17466547730316258748333298168566143799241073466140136663575045164199607937939;
        IVs[7] = 18881017304615283094648494495339883533502299318365959655029893746755475886610;
        IVs[8] = 21580915712563378725413940003372103925756594604076607277692074507345076595494;
        IVs[9] = 12316305934357579015754723412431647910012873427291630993042374701002287130550;
        IVs[10] = 18905410889238873726515380969411495891004493295170115920825550288019118582494;
        IVs[11] = 12819107342879320352602391015489840916114959026915005817918724958237245903353;
        IVs[12] = 8245796392944118634696709403074300923517437202166861682117022548371601758802;
        IVs[13] = 16953062784314687781686527153155644849196472783922227794465158787843281909585;
        IVs[14] = 19346880451250915556764413197424554385509847473349107460608536657852472800734;
        IVs[15] = 14486794857958402714787584825989957493343996287314210390323617462452254101347;
        IVs[16] = 11127491343750635061768291849689189917973916562037173191089384809465548650641;
        IVs[17] = 12217916643258751952878742936579902345100885664187835381214622522318889050675;
        IVs[18] = 722025110834410790007814375535296040832778338853544117497481480537806506496;
        IVs[19] = 15115624438829798766134408951193645901537753720219896384705782209102859383951;
        IVs[20] = 11495230981884427516908372448237146604382590904456048258839160861769955046544;
        IVs[21] = 16867999085723044773810250829569850875786210932876177117428755424200948460050;
        IVs[22] = 1884116508014449609846749684134533293456072152192763829918284704109129550542;
        IVs[23] = 14643335163846663204197941112945447472862168442334003800621296569318670799451;
        IVs[24] = 1933387276732345916104540506251808516402995586485132246682941535467305930334;
        IVs[25] = 7286414555941977227951257572976885370489143210539802284740420664558593616067;
        IVs[26] = 16932161189449419608528042274282099409408565503929504242784173714823499212410;
        IVs[27] = 16562533130736679030886586765487416082772837813468081467237161865787494093536;
        IVs[28] = 6037428193077828806710267464232314380014232668931818917272972397574634037180;
    }


    function hashImpl (uint256 left, uint256 right, uint256 IV)
        internal 
        pure 
        returns (uint256)
    {
        uint256[] memory x = new uint256[](2);
        x[0] = left;
        x[1] = right;

        return MiMC.Hash(x, IV);
    }


    function insert(Data storage self, uint256 leaf)
        internal 
        returns (uint256 new_root, uint256 offset)
    {
        require(leaf != 0);


        uint256[29] memory IVs;
        fillLevelIVs(IVs);

        offset = self.cur;

        require(offset != MAX_LEAF_COUNT - 1);

        self.nodes[0][offset] = leaf;

        new_root = updateTree(self, IVs);

        self.cur = offset + 1;
    }


    /**
    * Returns calculated merkle root
    */
    function verifyPath(uint256 leaf, uint256[29] memory in_path, bool[29] memory address_bits)
        internal 
        pure 
        returns (uint256 merkleRoot)
    {
        uint256[29] memory IVs;
        fillLevelIVs(IVs);

        merkleRoot = leaf;

        for (uint depth = 0; depth < TREE_DEPTH; depth++) {
            if (address_bits[depth]) {
                merkleRoot = hashImpl(in_path[depth], merkleRoot, IVs[depth]);
            } else {
                merkleRoot = hashImpl(merkleRoot, in_path[depth], IVs[depth]);
            }
        }
    }


    function verifyPath(Data storage self, uint256 leaf, uint256[29] memory in_path, bool[29] memory address_bits)
        internal 
        view 
        returns (bool)
    {
        return verifyPath(leaf, in_path, address_bits) == getRoot(self);
    }


    function getLeaf(Data storage self, uint depth, uint offset)
        internal 
        view 
        returns (uint256)
    {
        return getUniqueLeaf(depth, offset, self.nodes[depth][offset]);
    }


    function getMerkleProof(Data storage self, uint index)
        internal 
        view 
        returns (uint256[29] memory proof_path)
    {
        for (uint depth = 0; depth < TREE_DEPTH; depth++)
        {
            if (index % 2 == 0) {
                proof_path[depth] = getLeaf(self, depth, index + 1);
            } else {
                proof_path[depth] = getLeaf(self, depth, index - 1);
            }
            index = uint(index / 2);
        }
    }


    function getUniqueLeaf(uint256 depth, uint256 offset, uint256 leaf)
        internal pure returns (uint256)
    {
        if (leaf == 0x0)
        {
            leaf = uint256(
                sha256(
                    abi.encodePacked(
                        uint16(depth),
                        uint240(offset)))) % MiMC.getScalarField();
        }

        return leaf;
    }


    function updateTree(Data storage self, uint256[29] memory IVs)
        internal returns(uint256 root)
    {
        uint currentIndex = self.cur;

        uint256 leaf1;

        uint256 leaf2;

        for (uint depth = 0; depth < TREE_DEPTH; depth++)
        {
            uint nextIndex = uint(currentIndex/2);

            if (currentIndex%2 == 0)
            {
                leaf1 = self.nodes[depth][currentIndex];

                leaf2 = getUniqueLeaf(depth, currentIndex + 1, self.nodes[depth][currentIndex + 1]);
            } else
            {
                leaf1 = getUniqueLeaf(depth, currentIndex - 1, self.nodes[depth][currentIndex - 1]);

                leaf2 = self.nodes[depth][currentIndex];
            }

            self.nodes[depth+1][nextIndex] = hashImpl(leaf1, leaf2, IVs[depth]);

            currentIndex = nextIndex;
        }

        return self.nodes[TREE_DEPTH][0];
    }


    function getRoot (Data storage self)
        internal 
        view 
        returns (uint256)
    {
        return self.nodes[TREE_DEPTH][0];
    }
}