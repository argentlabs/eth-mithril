import unittest
import json
import time
import random

from ethsnarks.verifier import VerifyingKey, Proof
from ethsnarks.mod.hashpreimage import HashPreimage
from ethsnarks.utils import native_lib_path


VK_STATIC = {'alpha': ['0x1a9b4e2ac1995dd16f454f29e99eb5117ad746622861e7f431b6c4c8d3baafb9', '0x31cdc99db948afc75eabbe2eae7a9eca07d381015a2328113c3167b917be3ca'], 'beta': [['0xc6f1198c576e2207e51f67b68ff7bdf4c0e025a06d939ed60dc48cec66d4039', '0x17284231b380c0e58a7427ba62d81361c270d736dac2da24a79e4f7c636768c4'], ['0x1a8943f3de1661a58bbabc79383c2d0f21a383c60f63a02137e745b9c37773', '0x1c2a6f9fbbcc6cf56138e592c88e85c9bd3b9475502ee74ee2e2270bdada1721']], 'gamma': [['0x2696d25a7afb6661334ab032c2f542228dde68b5bbf40b632b565548a62b4609', '0x44603e77c3089413bb7b14919796794945cfd8dff60f24c3c95ce934174a764'], ['0x24af680afaf803574962a13aa200fbef3ce72195115f58311d49e7bc6258c329', '0x1e1ec3dcdb121633453b323616ef4534ac3c85aaf7bd55dc81c742d0b04ba9fc']], 'delta': [['0x19769645773ead44e472cc5e7c4e10452c04c822eb30907a02eb040b9a27354d', '0x5154440eb40fb1784183c61fb0e601f37987c550f6ed3fad38c250dd8c1b8fd'], ['0x2f1f75b1858a0054df7f216ef1b56f309f164179bfca1741062c724c8556dc8c', '0x25909e78312ff8925a6c32df4510716c58ad8433582ad192be8ebcf3e4958533']], 'gammaABC': [['0x1caac86452b8e9a97f3999ecb5655bc114fa5adeabaf99ad81d8b683435afb7f', '0x169d8cd35287b8292902371d04e51a01450d08845911f2393563b754ca859767'], ['0x26efb6f2c684ac0efe064724e6417e13060a963c0d1684fad0fd1c4168b29055', '0x2c1aa9c6e49dc7a7ccb633f02195c9a8fd1aab04fac22b89056e1c33b9c40188'], ['0x522736633167bb2752cfda11562c05b2d17ab8f5a0a5615f7f14972f0fb7ccd', '0x8648d86f08c4afd8578bd3a1ac84eadc6168f48551ffa3a20b7630070d83f37']]}

PROOF_STATIC = {'A': ['0x6e07b410bc94ff66d22fc9c954649e25e46f05cdf0fdc4f8482ab97b8d3e618', '0x25087e637a414e698bd1a661bdf1dad9234f6a8a22b2b439422aa6aa183c0482'], 'B': [['0x2e416841c35c40c19ad12b5412257c30000997a34fe80ceee4ef05ffae4e5dd7', '0xca0968c96862fa37a3e7f6352e036715b19f650c3a088054a9fd7145a98ed27'], ['0x28d28ee72c8091bf9999a9776098880bacbc3c52fcfa25d669a8c8bbaced0cba', '0xabc52932061ab659f7127549e0a7d27626f44f6829cd22bb2e36f3828b30364']], 'C': ['0x499945e18eebc8eabb2143f02bbd4c1d7165715c60c1236cb42442e76506a2e', '0x208074aa4a026f42e086089c50fd815038cfaba4f963c23535fecd0f627b17d6'], 'input': ['0x6f63883e503af3bf844c55046e43b5c79f7676c67327d0267f2e1a1a76f294b', '0x7']}


class VerifyTests(unittest.TestCase):
    def test_vk_roundtrip(self):
        vk = VerifyingKey.from_dict(VK_STATIC)
        vk_json = vk.to_json()
        vk2 = VerifyingKey.from_dict(json.loads(vk_json))
        self.assertEqual(vk, vk2)

    def test_verify_native(self):
        """Verify using fast native library"""
        vk = VerifyingKey.from_dict(VK_STATIC)
        proof = Proof.from_dict(PROOF_STATIC)
        wrapper = HashPreimage(native_lib_path('build/src/libhashpreimage'), vk)
        self.assertTrue(wrapper.verify(proof))

    def test_verify_python(self):
        # Verify using sloooow python implementation
        vk = VerifyingKey.from_dict(VK_STATIC)
        proof = Proof.from_dict(PROOF_STATIC)
        self.assertTrue(vk.verify(proof))

if __name__ == "__main__":
    unittest.main()
