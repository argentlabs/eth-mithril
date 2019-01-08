import unittest

from collections import defaultdict

from ethsnarks.jubjub import FQ, JUBJUB_L


class TestJubJubLMask(unittest.TestCase):
	def test_jubjub_l_size(self):
		"""
		Any 250 bits will be below JUBJUB_L
		This ensures that any 250 bit value cannot
		be used to exceed the twist point of the curve
		"""
		self.assertTrue(int('1' * 250, 2) < JUBJUB_L)

	def test_mask_bits(self):
		histogram = defaultdict(int)
		n_samples = 256*2
		for _ in range(0, n_samples):
			randfq = FQ.random()
			randfq_mod_l = randfq.n % JUBJUB_L
			as_binary = bin(randfq_mod_l)[2:][::-1]
			for i, bit in enumerate(as_binary):
				histogram[i] += 1

		"""
		# Display histogram of bit probablities
		for i in range(0, 256):
			print(i, histogram[i], histogram[i] / n_samples)
		"""

		for i in range(251, 256):
			self.assertEqual(histogram[i], 0)

if __name__ == "__main__":
	unittest.main()
