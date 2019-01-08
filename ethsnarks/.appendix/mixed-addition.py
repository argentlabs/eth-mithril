from random import randint
from os import urandom
from ethsnarks.jubjub import FQ, Point, JUBJUB_D, JUBJUB_A, JUBJUB_L


def mixed_add(P1, P2, bit_flag):
    X1, Y1, T1, Z1 = P1
    X2, Y2 = P2
    a = JUBJUB_A
    d = JUBJUB_D
    T2 = X2 * Y2

    """
    # madd-2008-hwcd-3
    # Assumptions: a=-1 Z2=1 and k=2*d.
    # Constraints: 7
    A = (Y1-X1)*(Y2-X2)
    B = (Y1+X1)*(Y2+X2)
    C = T1*k*T2
    X3 = (B-A)*((2*Z1)-C)
    Y3 = ((2*Z1)+C)*(B+A)
    T3 = (B-A)*(B+A)
    Z3 = ((2*Z1)-C)*((2*Z1)+C)
    """

    # madd-2008-hwcd
    # https://hyperelliptic.org/EFD/g1p/auto-twisted-projective.html#addition-madd-2008-hwcd
    """
    # Z2=1
    # 8 constraints
    A = X1*X2
    B = Y1*Y2
    C = T1*d*T2
    E = (X1+Y1)*(X2+Y2)-A-B
    X3 = E*(Z1-C)
    Y3 = (Z1+C)*(B-a*A)
    T3 = E*(B-a*A)
    Z3 = (Z1-C)*(Z1+C)
    """

    """
    # madd-2008-hwcd-2
    # 8 constraints
    # Z2=1
    A = X1*X2
    B = Y1*Y2
    C = Z1*T2
    F = (X1-Y1)*(X2+Y2)+B-A
    X3 = (T1+C)*F
    Y3 = (B+a*A)*(T1-C)
    T3 = (T1+C)*(T1-C)
    Z3 = F*(B+a*A)
    """

    """
    # madd-2008-bbjlp
    # 9 constraints, variable P1 and P2
    # Z2=1
    A = Z1*Z1
    C = X1*X2
    D = Y1*Y2
    E = C*D
    I = (X1+Y1)*(X2+Y2)-C-D
    X3 = (E+(d*A))*(C-a*D)
    Y3 = (E-(d*A))*I
    H = (C-a*D)*I
    Z3 = Z1*H
    """

    """
    # madd-2008-bbjlp
    # 5 constraints, variable P1 and fixed P2
    # Z2=1
    c_X2 = X2
    c_Y2 = Y2
    c_negdY2 = -(d * c_Y2)
    c_X2plusY2= X2 + Y2
    A = Z1*Z1
    E = (X1*c_X2)*(Y1*c_Y2)
    X3 = (E+(d*A))*((X1*c_X2)+(Y1*c_negdY2))
    Y3 = (E-(d*A))*((X1+Y1)*c_X2plusY2 - (X1*c_X2) - (Y1*c_Y2))
    Z3 = Z1*((X1*c_X2)+(Y1*c_negdY2))*((X1+Y1)*c_X2plusY2 - (X1*c_X2) - (Y1*c_Y2))
    """

    """
    # mmadd-2008-bbjlp
    # 4 constraints
    # Z1=1 and Z2=1
    c_dX2 = d * X2
    c_aX2 = a * X2
    c_X2plusY2 = X2 + Y2
    E = (c_dX2*X1)*(Y1*c_Y2)
    X3 = (1-E)*((X1+Y1)*c_X2plusY2-(X1*c_X2)-(Y1*c_Y2))
    Y3 = (1+E)*((Y1*c_Y2)-(c_aX2*X1))
    1 - Z3 = (E * E)
    """

    # madd-2008-hwcd
    #"""
    c_Y2 = Y2
    c_X2plusY2 = X2 + Y2
    c_negaX2 = -(a * X2)
    c_negY2 = -Y2
    c_negX2 = -X2
    c_dT2 = d*T2
    c_negdT2 = -(d*T2)
    # C = A                                                                    * B
    X3 = ((X1*c_X2plusY2) + (Y1*c_X2plusY2) + (X1 * c_negX2) + (Y1 * c_negY2)) * (Z1 + (T1*c_negdT2))
    Y3 = (Z1 + (T1*c_dT2))                                                     * (Y1*c_Y2 + (c_negaX2*X1))
    T3 = ((X1*c_X2plusY2) + (Y1*c_X2plusY2) + (X1 * c_negX2) + (Y1 * c_negY2)) * (Y1*c_Y2 + (X1 * c_negaX2))
    Z3 = (Z1 + (T1*c_negdT2))                                                  * (Z1 + (T1*c_dT2))
    #"""


    # madd-2008-hwcd-2
    """
    c_X2 = X2
    c_negX2 = -X2
    c_X2plusY2 = (X2+Y2)
    c_negX2plusY2 = -c_X2plusY2
    c_Y2 = Y2
    c_aX2 = a * X2
    c_T2 = T2
    c_negT2 = -T2
    # C =  B                       * A
    X3 = ((T1 + (Z1*c_T2))         * ((X1*c_X2plusY2) + (Y1*c_negX2plusY2) + (Y1*c_Y2) + (c_negX2 * X1)))
    Y3 = (((Y1*c_Y2) + (c_aX2*X1)) * (T1 + (Z1*c_negT2)))
    T3 = ((T1 + (Z1*c_T2))         * (T1 + Z1*c_negT2))
    Z3 = (((Y1*c_Y2) + (c_aX2*X1)) * ((X1*c_X2plusY2) + (Y1*c_negX2plusY2) + (Y1*c_Y2) + (c_negX2 * X1)))
    """

    # Conditional addition of the delta to get the result
    X4 = (X3 - X1) * bit_flag
    Y4 = (Y3 - Y1) * bit_flag
    T4 = (T3 - T1) * bit_flag
    Z4 = (Z3 - Z1) * bit_flag

    return ((X1 + X4), (Y1 + Y4), (T1 + T4), (Z1 + Z4))




if __name__ == "__main__":
    summed = (FQ(0), FQ(1), FQ(0), FQ(1))

    base_start = Point.from_hash(urandom(32))
    scalar = randint(1, JUBJUB_L-1)
    result = base_start * scalar

    while scalar != 0:
        base_powered = (base_start.x, base_start.y)
        summed = mixed_add(summed, base_powered, (scalar & 1))
        base_start = base_start.double()
        scalar = scalar // 2

    X3 = summed[0] / summed[3]
    Y3 = summed[1] / summed[3]
    assert X3 == result.x
    assert Y3 == result.y
