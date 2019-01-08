from random import randint
from os import urandom
from ethsnarks.jubjub import FQ, Point, JUBJUB_D, JUBJUB_A, JUBJUB_L


def point_add(P1, P2):
    d = JUBJUB_D
    nega = -FQ(JUBJUB_A)
    X1 = P1.x
    X2 = P2.x
    Y1 = P1.y
    Y2 = P2.y

    P3 = P1 + P2

    # https://z.cash/technology/jubjub/

    # Variables
    beta = X1 * Y2
    gamma = Y1 * X2
    delta = Y1 * Y2
    epsilon = X1 * X2
    tau = delta * epsilon

    # Constants, calculated out of circuit
    X3 = (beta+gamma) / (1 + (d*tau))
    Y3 = (delta+(nega*epsilon)) / (1 - (d*tau))

    # 7 Constraints
    assert beta == X1 * Y2
    assert gamma == Y1 * X2
    assert delta == Y1 * Y2
    assert epsilon == X1 * X2
    assert tau == delta * epsilon
    assert X3 * (1 + (d*tau)) == (beta + gamma)
    assert Y3 * (1 - (d*tau)) == (delta + (nega*epsilon))

    print(X3, P3.x)
    print(Y3, P3.y)
    print()
    return Point(X3, Y3)


if __name__ == "__main__":
    summed = Point.infinity()

    base_start = Point.from_hash(urandom(32))    
    scalar = randint(1, JUBJUB_L-1)
    result = base_start * scalar

    while scalar != 0:
        if (scalar & 1) == 1:
            summed = point_add(summed, base_start)
        base_start = base_start.double()
        scalar = scalar // 2

    assert summed.x == result.x
    assert summed.y == result.y
