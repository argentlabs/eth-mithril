import unittest

from os import urandom

from ethsnarks.field import FQ
from ethsnarks.jubjub import Point, EtecPoint, ProjPoint, JUBJUB_L, JUBJUB_C, MONT_A, MONT_B, JUBJUB_E
from ethsnarks.numbertheory import SquareRootError


class TestJubjub(unittest.TestCase):
	def _point_r(self):
		return Point.from_hash(urandom(10))

	def _point_a(self):
		x = 0x274dbce8d15179969bc0d49fa725bddf9de555e0ba6a693c6adb52fc9ee7a82c
		y = 0x5ce98c61b05f47fe2eae9a542bd99f6b2e78246231640b54595febfd51eb853
		return Point(FQ(x), FQ(y))

	def _point_a_double(self):
		x = 6890855772600357754907169075114257697580319025794532037257385534741338397365
		y = 4338620300185947561074059802482547481416142213883829469920100239455078257889
		return Point(FQ(x), FQ(y))

	def _verify_via_all(self, p):
		points = [p.as_point(), p.as_etec(), p.as_proj()]
		for q in points:
			self.assertTrue(q.valid())
			qoints = [q.as_point(), q.as_etec(), q.as_proj()]
			for i, r in enumerate(qoints):
				self.assertTrue(r.valid())
				self.assertEqual(r.rescale(), points[i].rescale(), "Conversion between %r, %r and %r" % (type(q), type(r), type(points[i])))

	def test_serialise(self):
		for _ in range(0, 10):
			p = self._point_r()
			s = p.compress()
			q = Point.decompress(s)
			self.assertEqual(p, q)

	def test_3_validity(self):
		"""
		Verify that 10 random points can be converted to and from every other
		coordinate system without losing information or corruption.
		"""
		self.assertTrue(self._point_a().valid())
		self.assertTrue(Point.infinity().valid())
		self.assertTrue(EtecPoint.infinity().valid())
		self.assertTrue(ProjPoint.infinity().valid())

		for _ in range(0, 10):
			p = self._point_r()
			self._verify_via_all(p)

	def test_5_recover_x(self):
		"""
		There is one x point for every y
		"""
		for _ in range(0, 10):
			p = self._point_r()
			q = Point.from_y(p.y)
			self.assertTrue(p.x in [q.x, -q.x])

	def test_6_recover_y(self):
		"""
		There are two y points for every x
		"""
		for _ in range(0, 10):
			p = self._point_r()
			q = Point.from_x(p.x)
			self.assertEqual(p.x, q.x)
			self.assertTrue(p.y in [q.y, -q.y])

		# These confirm compatibility across implementations
		known_test_cases = [
			(20616554786359396897066290204264220576319536076538991133935783866206841138898,
			 10592275084648178561464128859907688344447649297734555224341876545305639835999),

			(11610117029953798428826613242669939481045605849364609771767823351326159443609,
			 3722409228507723418678713896319610332389736117851027921973860155000856891140),

			(21680045038775759642189425577922609025982451102460978847266452551495203884482,
			 6168854640927408084732268325506202000962285527703379133980054444068219727690),

			(18879782252170350866370777185563748782908354718484814019474117245310535071541,
			 2946855428411022359321514310392164228862398839132752152798293872913224129374)
		]
		for x, y in known_test_cases:
			x, y = FQ(x), FQ(y)
			q = Point.from_y(y)
			self.assertEqual(q.x, x)

	def test_7_negate(self):
		"""
		Addition of its own negative results in infinity
		"""
		p = self._point_a()
		for q in [p.as_point(), p.as_etec(), p.as_proj()]:
			self.assertFalse(q.is_negative())
			r = q.neg()
			self.assertTrue(r.valid())
			self.assertTrue(r.is_negative())

			self.assertEqual(q.infinity().neg(), q.infinity())

			# (x,y) + (-(x,y)) = infinity
			r = q.add( q.neg() )
			self.assertEqual(r.as_point(), p.infinity())

			# (x,y) + infinity = (x,y)
			s = q.add( q.infinity() )
			self.assertEqual(s.as_point(), q.as_point())

			# infinity + (x,y) = (x,y)
			s = q.infinity().add(q)
			self.assertEqual(s.as_point(), q.as_point())

	def test_8_hash_to_point(self):
		p = Point.from_hash(b'test')
		expected = Point(x=6310387441923805963163495340827050724868600896655464356695079365984952295953,
						 y=12999349368805111542414555617351208271526681431102644160586079028197231734677)
		self.assertEqual(p, expected)

		for _ in range(0, 10):
			entropy = urandom(10)
			p = Point.from_hash(entropy)

	def test_9_zero(self):
		"""
		Verify that operations on infinity result in infinity
		"""
		zero = Point.infinity()
		etec_zero = EtecPoint.infinity()
		proj_zero = ProjPoint.infinity()

		self.assertEqual(zero.as_etec(), etec_zero)
		self.assertEqual(zero.as_proj(), proj_zero)

		self.assertEqual(etec_zero.as_point(), zero)
		self.assertEqual(etec_zero.as_proj(), proj_zero)

		self.assertEqual(proj_zero.as_point(), zero)
		self.assertEqual(proj_zero.as_etec(), etec_zero)

		self.assertEqual(zero.add(zero), zero)
		self.assertEqual(etec_zero.add(etec_zero), etec_zero)
		self.assertEqual(proj_zero.add(proj_zero), proj_zero)

		self.assertEqual(zero.double(), zero)
		self.assertEqual(etec_zero.double(), etec_zero)
		self.assertEqual(proj_zero.double(), proj_zero)

	def test_10_twist(self):
		"""
		Any point, multiplied by L results in a weird point
		Multiplying again by L results in the same point
		The resulting point, multiplied by the cofactor results in infinity
		"""
		p = self._point_r()
		for q in [p.as_point(), p.as_proj(), p.as_etec()]:
			r = q.mult(JUBJUB_L).as_point()
			s = r.mult(JUBJUB_L).as_point()
			self.assertTrue(r.valid())
			self.assertEqual(r, s)
			self.assertEqual(s.mult(JUBJUB_C), s.infinity())

	def test_12_nonsquares(self):
		"""
		If (A+2)*(A-2) is a square (e.g. if `ad` is a square) then there are two more
		points with v=0. These points have order 2
		"""
		try:
			x = (MONT_A+2) * (MONT_A-2)
			FQ(int(x)).sqrt()
			self.assertTrue(False)
		except SquareRootError:
			pass

		"""
		If (A-2)/B is a square (e.g. if `d` is a square) then there are two points
		with `u=-1`. These points have order 4. These points correspond to two points
		of order 4 at infinity of the desingularization of E_{E,a,d}
		"""
		try:
			x = int((MONT_A-2) / MONT_B)
			FQ(x).sqrt()
			self.assertTrue(False)
		except SquareRootError:
			pass

	def test_13_equality(self):
		p = self._point_a()
		for q in [p.as_point(), p.as_proj(), p.as_etec()]:
			a = q.mult(9).add(q.mult(5))
			b = q.mult(12).add(q.mult(2))

			self.assertTrue(a.as_point().valid())
			self.assertTrue(b.as_point().valid())
			self.assertTrue(a.valid())
			self.assertTrue(b.valid())
			self.assertEqual(a.as_point(), b.as_point())

	def test_negate_order(self):
		p = self._point_r()
		self.assertEqual(p * (JUBJUB_E+1), p)
		self.assertEqual(p * (JUBJUB_E-1), p.neg())
		self.assertEqual(p - p - p, p.neg())

	def test_multiplicative(self):
		G = self._point_r()
		a = FQ.random()
		A = G*a
		b = FQ.random()
		B = G*b

		ab = (a.n * b.n) % JUBJUB_E
		AB = G*ab
		self.assertEqual(A*b, AB)
		self.assertEqual(B*a, AB)

	def test_cyclic(self):
		G = self._point_r()
		self.assertEqual(G * (JUBJUB_E+1), G)

	def test_double_via_add(self):
		a = self._point_a()
		a_dbl = a.add(a)
		self.assertEqual(a_dbl.as_point(), self._point_a_double())

	def test_etec_double(self):
		a = self._point_a().as_etec()
		a_dbl = a.double()
		self.assertEqual(a_dbl.as_point(), self._point_a_double())

	def test_etec_double_via_add(self):
		a = self._point_a().as_etec()
		a_dbl = a.add(a)
		self.assertEqual(a_dbl.as_point(), self._point_a_double())

	def test_projective_double(self):
		b = self._point_a().as_proj()
		b_dbl = b.double()
		self.assertEqual(b_dbl.as_point(), self._point_a_double())

	def test_projective_double_via_add(self):
		c = self._point_a().as_proj()
		c_dbl = c.add(c)
		self.assertEqual(c_dbl.as_point(), self._point_a_double())

	def test_mult_2(self):
		p = self._point_a().as_etec()
		q = p.mult(2)
		self.assertEqual(q.as_point(), self._point_a_double())

	def test_etec_mult_n(self):
		p = self._point_a().as_etec()
		q = p.mult(6890855772600357754907169075114257697580319025794532037257385534741338397365)
		q = q.as_point()
		self.assertEqual(q.x, 6317123931401941284657971611369077243307682877199795030160588338302336995127)
		self.assertEqual(q.y, 17705894757276775630165779951991641206660307982595100429224895554788146104270)

	def test_proj_mult_n(self):
		p = self._point_a().as_proj()
		q = p.mult(6890855772600357754907169075114257697580319025794532037257385534741338397365)
		q = q.as_point()
		self.assertEqual(q.x, 6317123931401941284657971611369077243307682877199795030160588338302336995127)
		self.assertEqual(q.y, 17705894757276775630165779951991641206660307982595100429224895554788146104270)

	def test_loworder(self):
		for p in Point.all_loworder_points():
			if p != Point.infinity():
				q = p * JUBJUB_L
				self.assertEqual(q, p)
				self.assertNotEqual(q, Point.infinity())

if __name__ == "__main__":
	unittest.main()
