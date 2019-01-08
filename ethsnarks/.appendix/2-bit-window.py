from math import ceil, log2
from os import urandom
from ethsnarks.jubjub import Point

N = 4
nbits = ceil(log2(N))

p = []
for _ in range(0, N):
   p.append(Point.from_hash(urandom(32)))
p[0] = Point.infinity()

c = [_.x for _ in p]

for i in range(0, N):
   b = [int(_) for _ in bin(i)[2:].rjust(nbits, '0')][::-1]

   r = c[i]
   
   A = (b[1]*c[3]) - (b[1]*c[2]) - (b[1]*c[1]) + c[1] + (c[0]*b[1]) - c[0]
   B = b[0]
   C = r - (b[1]*c[2]) + (c[0]*b[1]) - c[0]

   assert A * B == C
