from py_ecc.bn128 import curve_order
from z3 import *

from ethsnarks.shamirspoly import shamirs_poly_n, randn

#curve_order = 29
#curve_order = 251
curve_order = 65521


def evalpoly(x, a):
	e0 = a[0]

	e1 = (a[1] * x) % curve_order

	x2 = (x * x) % curve_order
	e2 = (a[2] * x2) % curve_order

	x3 = (x2 * x) % curve_order
	e3 = (a[3] * x3) % curve_order

	return (e0 + e1 + e2 + e3) % curve_order

#s = Solver()
s = Tactic('qfnra-nlsat').solver()

A = [randn(curve_order - 1) for _ in range(0, 4)]
I = randn(curve_order - 1)
J = randn(curve_order - 1)

K = Int('K')
L = Int('L')
s.add(K > 0, K < (curve_order - 1))
s.add(L > 0, L < (curve_order - 1))

B = [Int("b0"), Int("b1"), Int("b2"), Int("b3")]
for i in range(0, len(B)):
	s.add(B[i] > 0, B[i] < (curve_order - 1))

# Evaluate two points
W = evalpoly(I, A)
X = evalpoly(J, A)

# Then find a matching B
Y = evalpoly(K, B)
Z = evalpoly(L, B)

s.add(I == K)
s.add(J == L)

s.add(W == Y)
s.add(X == Z)

print("A", A)
print("I", I)
print("J", J)
print(s.check())
print(s.model())