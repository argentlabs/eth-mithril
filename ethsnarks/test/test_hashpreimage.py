import unittest
from binascii import hexlify
from hashlib import sha256
from os import urandom

from ethsnarks.mod.hashpreimage import HashPreimage
from ethsnarks.utils import libsnark2python, native_lib_path


VK_FILENAME = '.keys/hpi.vk.json'
PK_FILENAME = '.keys/hpi.pk.raw'
SO_FILENAME = native_lib_path('build/src/libhashpreimage')


class HashPreimageTests(unittest.TestCase):
    def test_prove_verify(self):
        hpi = HashPreimage(SO_FILENAME, VK_FILENAME, PK_FILENAME)
        preimage = urandom(64)
        proof = hpi.prove(preimage)

        # Verify the proof input matches the expected value
        postimage = sha256(preimage).digest()
        inputs = libsnark2python(proof.input)
        self.assertEqual(inputs[0], '0x' + hexlify(postimage).decode('ascii'))

        # Ensure proof verifies
        self.assertTrue(hpi.verify(proof))

        # TODO: flip a bit in the proof input, verify it doesn't verify
        proof.input[0] -= 1
        self.assertFalse(hpi.verify(proof))


if __name__ == "__main__":
    unittest.main()
