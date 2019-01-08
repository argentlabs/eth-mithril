import sys
from math import log2, ceil
from random import randint
from ethsnarks.field import SNARK_SCALAR_FIELD, FQ
from z3 import *

prime = SNARK_SCALAR_FIELD

N = 5

p = []
for _ in range(0, N):
	x = randint(1, prime-1)
	y = randint(1, prime-1)
	p.append((x, y))

p[0] = (0, 1)

S = Solver()

coefficients_A = []
for _ in range(0, N+1):
	x = Int('a' + str(_))
	S.add(x > 0, x < prime)
	coefficients_A.append( x )

coefficients_B = []
for _ in range(0, N+1):
	x = Int('b' + str(_))
	S.add(x > 0, x < prime)
	coefficients_B.append( x )

nbits = ceil(log2(N))

B = 1

for i in range(0, N):
	bits = [int(_) for _ in bin(i)[2:].rjust(nbits, '0')]

	# Y = 0 if both bits are zero, otherwise 1
	summed_bits = sum(bits)
	summed_inv = (1 / FQ(summed_bits, prime)).n
	Y = (summed_bits * summed_inv) % prime
	S.add( (summed_bits * summed_inv) % prime == Y )
	S.add( (Y * Y) % prime == Y )

	sumargs_A = []
	for j, b in enumerate(bits):
		sumargs_A.append( (coefficients_A[j] * b) )
	sumargs_A.append(coefficients_A[j+1])
	sumargs_A.append(Y)

	sumargs_B = []
	for j, b in enumerate(bits):
		sumargs_B.append( (coefficients_B[j] * b) )		
	sumargs_B.append(coefficients_B[j+1])
	sumargs_B.append(Y)

	Ax = Sum(sumargs_A) % prime
	Cx = p[i][0]
	Bx = Y
	S.add( (Ax * Bx) % prime == Cx )

	Ay = Sum(sumargs_B) % prime
	Cy = p[i][1]
	By = Y
	S.add( (Ay * By) % prime == Cy - 1 )


print(S.check(), N)
try:		
	model = S.model()
except Z3Exception:
	sys.exit(1)

print(model)


for i in range(0, N):
	bits = [int(_) for _ in bin(i)[2:].rjust(nbits, '0')]

	# Y = 0 if both bits are zero, otherwise 1
	summed_bits = sum(bits)
	summed_inv = (1 / FQ(summed_bits, prime)).n
	Y = (summed_bits * summed_inv) % prime

	summed_A = 0
	for j, b in enumerate(bits):
		summed_A += b * int(str(model[coefficients_A[j]]))
	summed_A += int(str(model[coefficients_A[j+1]]))
	summed_A += Y
	summed_A = summed_A % prime

	summed_B = 0
	for j, b in enumerate(bits):
		summed_B += b * int(str(model[coefficients_B[j]]))
	summed_B += int(str(model[coefficients_B[j+1]]))
	summed_B += Y
	summed_B = summed_B % prime

	x = (summed_A * Y)
	print('x', bits, p[i][0], x)

	y = (summed_B * Y)
	print('y', bits, p[i][1], y)

	assert p[i][0] == x
	assert p[i][1] == y + 1
	print()