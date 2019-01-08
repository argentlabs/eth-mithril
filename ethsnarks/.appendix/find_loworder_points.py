#!/usr/bin/env python3
"""
Finds all low-order points
"""

from ethsnarks.jubjub import *
from os import urandom

def randpoint():
    y = FQ(int.from_bytes(urandom(32), 'big'))
    while True:
        try:
            p = Point.from_y(y)
        except SquareRootError:
            y += 1
            continue
        break
    return p

points = [randpoint() for _ in range(0, JUBJUB_C*JUBJUB_C)]
lowrder_points = set()

for _ in points:
    p = _ * JUBJUB_L
    lowrder_points.add((p.x.n, p.y.n))

assert len(lowrder_points) == JUBJUB_C

for x,y in sorted(lowrder_points):
	p = Point(FQ(x), FQ(y))
	assert (p * JUBJUB_C) == Point.infinity()
	print(p)
