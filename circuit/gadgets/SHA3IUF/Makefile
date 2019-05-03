.PHONY : all test clean

all: sha3sum test

sha3test: sha3test.o sha3.o
	$(CC) -o $@ $^ ${LDFLAGS}

test: sha3test
	./sha3test

sha3sum: sha3.o sha3sum.c
	$(CC) -o $@ $^ ${LDFLAGS}

clean:
	-rm -f *.o sha3test sha3sum
