from math import ceil, log2
from os import urandom
from ethsnarks.field import FQ
from ethsnarks.jubjub import Point

N = 8
nbits = ceil(log2(N))

c = [FQ.random() for _ in range(0, N)]


def sumfq(x):
    r = FQ(0)
    for _ in x:
        r = r + _
    return r


for i in range(0, 8):
    b = [int(_) for _ in bin(i)[2:].rjust(nbits, '0')][::-1]
    r = c[i]
    precomp = b[0] * b[1]
    precomp1 = b[0] * b[2]
    precomp2 = b[1] * b[2]
    precomp3 = precomp * b[2]
    A = [
        c[0],
        (b[0] * -c[0]),
        (b[0] * c[1]),

        (b[1] * -c[0]),
        (b[1] * c[2]),

        (precomp * (-c[1] + -c[2] + c[0] + c[3])),

        (b[2] * (-c[0] + c[4])),

        (precomp1 * (c[0] - c[1] - c[4] + c[5])),

        (precomp2 * (c[0] - c[2] - c[4] + c[6])),

        (precomp3 * ( -c[0] + c[1] + c[2] - c[3] + c[4] - c[5] - c[6] + c[7] ))
    ]
    assert sumfq(A) == r
