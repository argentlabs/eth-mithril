# Copyright (c) 2018 HarryR
# License: LGPL-3.0+

import unittest
from random import randint
from py_ecc.bn128 import curve_order


class OneOfNTests(unittest.TestCase):
    def test_one_of_n(self):
        items = [randint(1, curve_order-1) for _ in range(0, 10)]
        our_n = randint(0, len(items) - 1)
        our_item = items[our_n]
        toggles = [0 for _ in range(0, len(items))]
        toggles[our_n] = 1

        # create toggle sum
        toggles_sum = [0] * len(items)
        toggles_sum[0] = toggles[0]
        for i in range(1, len(items)):
            toggles_sum[i] = toggles_sum[i-1] + toggles[i]

        # Ensure bitness of toggles
        for i in range(0, len(items)):
            assert (toggles[i] * (1 - toggles[i])) == 0

        # ensure sum of toggles equals 1
        for i in range(1, len(items)):
            assert (((toggles_sum[i-1] + toggles[i]) * 1) - toggles_sum[i]) == 0
        assert toggles_sum[-1] == 1

        # then multiply toggles with items
        # subtract toggle*our_item
        for i in range(0, len(items)):
            assert ((items[i] * toggles[i]) - (toggles[i] * our_item)) == 0


if __name__ == "__main__":
    unittest.main()
