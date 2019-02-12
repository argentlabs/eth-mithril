import unittest

from ethsnarks.longsight import random_element, LongsightL12p5_MP
from ethsnarks.utils import native_lib_path
from ethsnarks.merkletree import MerkleTree
from mixer import Mixer

from hashlib import sha256

NATIVE_LIB_PATH = native_lib_path('../.build/libmixer')
VK_PATH = '../.keys/mixer.vk.json'
PK_PATH = '../.keys/mixer.pk.raw'


def to_hex(intValue):
    return "{0:#0{1}x}".format(intValue, 66)


def get_sha256_hash(left, right):
    binput = bytes.fromhex(left[2:] + right[2:])
    output = sha256(binput).hexdigest()
    list_output = list(output)
    list_output[0] = '0'
    return '0x' + "".join(list_output)


class TestMixer(unittest.TestCase):
    def test_make_proof(self):
        n_items = 2 << 28
        tree = MerkleTree(n_items)
        for n in range(0, 2):
            tree.append(random_element())

        wallet_address = random_element()
        nullifier_secret = random_element()
        nullifier_hash_IV = 0
        nullifier_hash = LongsightL12p5_MP(
            [nullifier_secret, nullifier_secret], nullifier_hash_IV)
        # leaf_hash_IV = 0
        # leaf_hash = LongsightL12p5_MP(
        # [nullifier_secret, wallet_address], leaf_hash_IV)
        leaf_hash = int(get_sha256_hash(
            to_hex(nullifier_secret), to_hex(wallet_address)), 16)

        # print('============== PYTHON ===================')
        # print('Inputs as integers:', [nullifier_secret, wallet_address])
        # print('Inputs as hex:', [to_hex(nullifier_secret),
        #                          to_hex(wallet_address)])
        # print('Output as integer:', leaf_hash)
        # print('Output as hex:', to_hex(leaf_hash))
        # print('=========================================')

        leaf_idx = tree.append(leaf_hash)
        self.assertEqual(leaf_idx, tree.index(leaf_hash))

        # Verify it exists in true
        leaf_proof = tree.proof(leaf_idx)
        self.assertTrue(leaf_proof.verify(tree.root))

        # Generate proof
        wrapper = Mixer(NATIVE_LIB_PATH, VK_PATH, PK_PATH)
        tree_depth = wrapper.tree_depth
        snark_proof = wrapper.prove(
            tree.root,
            wallet_address,
            nullifier_hash,
            nullifier_secret,
            # (index)_2 bits reversed, i.e. [LSB, ... , MSB]
            leaf_proof.address,
            leaf_proof.path)

        self.assertTrue(wrapper.verify(snark_proof))


if __name__ == "__main__":
    unittest.main()
