"""
This module implements a Pedersen hash function.
It can hash points, scalar values or blocks of message data.

It is possible to create two variants, however only the
non-homomorphic variant has been implemented.

The homomorphic variant users the same base point for every
input, whereas the non-homomorphic version uses a different
base point for every input.

For example to non-homomorphically hash the two points P1 and P2

	Four base points are chosen (consistently)

		B0, B1, B2, B3

	The result of the hash is the point:

		B0*P1.x + B1*P1.y + B2*P2.x + B3*P2.y

To homomorphically hash the two points:

	Two base points are chosen

		BX, BY

	The result of the hash is the point:

		BX*P1.x + BY*P1.y + BX*P2.x + BY*P2.y

	The hash will be the same if either point is swapped
	with the other, e.g. H(P1,P2) is the same as H(P2,P1).

	This provides a basis for 'chemeleon hashes', or where
	malleability is a feature rather than a defect.
"""

import math
import bitstring
from math import floor, log2
from struct import pack

from .jubjub import Point, JUBJUB_L


MAX_SEGMENT_BITS = floor(log2(JUBJUB_L))
MAX_SEGMENT_BYTES = MAX_SEGMENT_BITS // 8


def pedersen_hash_basepoint(name, i):
	"""
	Create a base point for use with the windowed pedersen
	hash function.
	The name and sequence numbers are used a unique identifier.
	Then HashToPoint is run on the name+seq to get the base point.
	"""
	if not isinstance(name, bytes):
		if isinstance(name, str):
			name = name.encode('ascii')
		else:
			raise TypeError("Name not bytes")
	if i < 0 or i > 0xFFFF:
		raise ValueError("Sequence number invalid")
	if len(name) > 28:
		raise ValueError("Name too long")
	data = b"%-28s%04X" % (name, i)
	return Point.from_hash(data)


def pedersen_hash_points(name, *points):
	# XXX: should the coordinate be truncated?
	result = Point.infinity()
	for i, p in enumerate(points):
		p = p.as_point()
		for j, c in enumerate([p.x, p.y]):
			base = pedersen_hash_basepoint(name, i*2 + j)
			result += base * c
	return result


def pedersen_hash_bytes(name, *args):
	"""
	Split the message data into segments, then hash each segment

	Data is split into bytes for convenience, rather
	than bits. e.g. if snark scalar field is 253 bits
	then only 248 will be used (31 bytes), the reason is:

		1) Conversion is easier
		2) All values are below L (location of the curve twist)
	"""
	data = b''.join(args)
	segments_list = [data[i:i+MAX_SEGMENT_BYTES]
					 for i in range(0, len(data), MAX_SEGMENT_BYTES)]
	result = Point.infinity()
	for i, segment in enumerate(segments_list):
		base = pedersen_hash_basepoint(name, i)
		scalar = int.from_bytes(segment, 'big')
		result += base * scalar
	return result


def pedersen_hash_zcash_windows(name, windows):
	# TODO: define `62`
	result = Point.infinity()
	for j, window in enumerate(windows):
		if j % 62 == 0:
			current = pedersen_hash_basepoint(name, j//62)
		j = j % 62
		if j != 0:
			current = current.double().double().double().double()
		segment = current * ((window & 0b11) + 1)
		if window > 0b11:
			segment = segment.neg()
		result += segment
	return result


def pedersen_hash_zcash_bits(name, bits):
	# Split into 3 bit windows
	if isinstance(bits, bitstring.BitArray):
		bits = bits.bin
	windows = [int(bits[i:i+3][::-1], 2) for i in range(0, len(bits), 3)]
	assert len(windows) > 0

	# Hash resulting windows
	return pedersen_hash_zcash_windows(name, windows)


def pedersen_hash_zcash_bytes(name, data):
	"""
	Hashes a sequence of bits (the message) into a point.

	The message is split into 3-bit windows after padding (via append)
	to `len(data.bits) = 0 mod 3`
	"""
	assert isinstance(data, bytes)
	assert len(data) > 0

	# Decode bytes to octets of binary bits
	bits = ''.join([bin(_)[2:].rjust(8, '0') for _ in data])

	return pedersen_hash_zcash_bits(name, bits)


def pedersen_hash_zcash_scalars(name, *scalars):
	"""
	Calculates a pedersen hash of scalars in the same way that zCash
	is doing it according to: ... of their spec.
	It is looking up 3bit chunks in a 2bit table (3rd bit denotes sign).

	E.g:

		(b2, b1, b0) = (1,0,1) would look up first element and negate it.

	Row i of the lookup table contains:

		[2**4i * base, 2 * 2**4i * base, 3 * 2**4i * base, 3 * 2**4i * base]

	E.g:

		row_0 = [base, 2*base, 3*base, 4*base]
		row_1 = [16*base, 32*base, 48*base, 64*base]
		row_2 = [256*base, 512*base, 768*base, 1024*base]

	Following Theorem 5.4.1 of the zCash Sapling specification, for baby jub_jub
	we need a new base point every 62 windows. We will therefore have multiple
	tables with 62 rows each.
	"""
	windows = []
	for i, s in enumerate(scalars):
		windows += list((s >> i) & 0b111 for i in range(0,s.bit_length(),3))
	return pedersen_hash_zcash_windows(name, windows)
