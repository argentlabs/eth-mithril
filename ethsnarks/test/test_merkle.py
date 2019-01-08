import unittest

import hashlib
from ethsnarks.merkletree import MerkleTree, MerkleHasherLongsight
from ethsnarks.field import FQ, SNARK_SCALAR_FIELD


class TestMerkleTree(unittest.TestCase):
    def test_tree(self):
        n_items = 32
        tree = MerkleTree(n_items)
        self.assertEqual(tree.root, None)
        self.assertEqual(len(tree), 0)

        previous_root = None
        hasher = hashlib.sha256()
        for n in range(0, n_items):
            hasher.update(bytes([n]) * 32)
            item = int.from_bytes(hasher.digest(), 'big') % SNARK_SCALAR_FIELD
            tree.append(item)
            self.assertEqual(len(tree), n + 1)
            self.assertNotEqual(tree.root, previous_root)
            previous_root = tree.root
            proof = tree.proof(n)
            self.assertTrue(proof.verify(tree.root))

            # Then verify all existing items can also be proven to be in the tree
            for m in range(0, len(tree) - 1):
                self.assertTrue(tree.proof(m).verify(tree.root))

    def test_known1(self):
        tree = MerkleTree(2)

        item_a = 3703141493535563179657531719960160174296085208671919316200479060314459804651
        tree.append(item_a)

        item_b = 134551314051432487569247388144051420116740427803855572138106146683954151557
        tree.append(item_b)

        self.assertEqual(tree.root, 13981856331482487152452149678096232821987624395720231314895268163963385035507)

        proof_a = tree.proof(0)
        self.assertEqual(proof_a.path, [item_b])

        proof_b = tree.proof(1)
        self.assertEqual(proof_b.path, [item_a])

    def test_update(self):
        """
        Verify that items in the tree can be updated
        """
        tree = MerkleTree(2)
        tree.append(FQ.random())
        tree.append(FQ.random())
        proof_0_before = tree.proof(0)
        proof_1_before = tree.proof(1)
        root_before = tree.root
        self.assertTrue(proof_0_before.verify(tree.root))
        self.assertTrue(proof_1_before.verify(tree.root))

        leaf_0_after = FQ.random()
        tree.update(0, leaf_0_after)
        root_after_0 = tree.root
        proof_0_after = tree.proof(0)
        self.assertTrue(proof_0_after.verify(tree.root))
        self.assertNotEqual(root_before, root_after_0)

        leaf_1_after = FQ.random()
        tree.update(1, leaf_1_after)
        root_after_1 = tree.root
        proof_1_after = tree.proof(1)
        self.assertTrue(proof_1_after.verify(tree.root))
        self.assertNotEqual(root_before, root_after_1)
        self.assertNotEqual(root_after_0, root_after_1)

    def test_known_2pow28(self):
        tree = MerkleTree(2<<28)

        item_a = 3703141493535563179657531719960160174296085208671919316200479060314459804651
        tree.append(item_a)

        item_b = 134551314051432487569247388144051420116740427803855572138106146683954151557
        tree.append(item_b)

        self.assertEqual(tree.root, 12880293998234311228895747943713504338160238149993004139365982527556885579681)

        proof_a = tree.proof(0)
        self.assertTrue(proof_a.verify(tree.root))

        proof_b = tree.proof(1)
        self.assertTrue(proof_b.verify(tree.root))

        self.assertEqual(tree.leaf(0, 0), 3703141493535563179657531719960160174296085208671919316200479060314459804651)
        self.assertEqual(tree.leaf(1, 0), 13981856331482487152452149678096232821987624395720231314895268163963385035507)
        self.assertEqual(tree.leaf(2, 0), 4008582766686307301250960594183893449903725811265984514032955228389672705119)

        self.assertEqual(tree.leaf(1, 1), 17296471688945713021042054900108821045192859417413320566181654591511652308323)
        self.assertEqual(tree.leaf(2, 1), 4832852105446597958495745596582249246190817345027389430471458078394903639834)
        self.assertEqual(tree.leaf(13, 1), 14116139569958633576637617144876714429777518811711593939929091541932333542283)
        self.assertEqual(tree.leaf(22, 1), 16077039334695461958102978289003547153551663194787878097275872631374489043531)


    def test_uniques(self):
        hasher = MerkleHasherLongsight(29)
        self.assertEqual(hasher.unique(20, 20), 6738165491478210350639451800403024427867073896603076888955948358229240057870)
        self.assertEqual(hasher.unique(2, 2), 21534879888322772601810176771999178940739467644392123609236489175629034941722)
        self.assertEqual(hasher.unique(0, 0), 2544023609834722662089612003212769975105508295482723304413974529614913939747)

if __name__ == "__main__":
    unittest.main()
