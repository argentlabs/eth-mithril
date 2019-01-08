#!/usr/bin/env python
# https://en.wikipedia.org/wiki/K-ary_tree
# https://en.wikipedia.org/wiki/Arity

from random import randint
from ethsnarks.longsight import LongsightF12p5


class Storage(object):
	def __init__(self):
		self._gas = 0
		self._gas_refund = 0
		self._stor = dict()

	def __setitem__(self, idx, value):
		# https://github.com/ethereum/go-ethereum/blob/2433349c808fad601419d1f06275bec5b6a93ec8/core/vm/gas_table.go#L118
		SstoreResetGas   = 5000  # Once per SSTORE operation if the zeroness changes from zero.
		SstoreClearGas   = 5000  # Once per SSTORE operation if the zeroness doesn't change.
		SstoreRefundGas  = 15000 # Once per SSTORE operation if the zeroness changes to zero.
		SstoreSetGas     = 20000 # Once per SSTORE operation.

		# Three secnarios
		# 1. From a zero-value address to a non-zero value (NEW VALUE)
		# 2. From a non-zero value address to a zero-value address (DELETE)
		# 3. From a non-zero to a non-zero (CHANGE)

		old_value = self._stor.get(idx, 0)
		if old_value == 0 and value != 0:
			# 0 => non 0
			self._gas += SstoreSetGas
			self._stor[idx] = value
		elif old_value != 0 and value == 0:
			# non 0 => 0
			self._gas_refund += SstoreRefundGas
			self._gas += SstoreClearGas
			del self._stor[idx]
		else:
			# non 0 => non 0 (or 0 => 0)
			self._gas += SstoreResetGas
			self._stor[idx] = value

	def __contains__(self, idx):
		self._gas += 50
		return idx in self._stor

	def get(self, idx, default=0):
		self._gas += 50
		if idx in self._stor:
			return self._stor[idx]
		return default

	def __getitem__(self, idx):
		assert idx in self._stor
		self._gas += 50
		return self._stor[idx]

	def __delitem__(self, idx):
		assert idx in self._stor
		self[idx] = 0

	def emit(self, name, **args):
		# https://github.com/ethereum/go-ethereum/blob/2433349c808fad601419d1f06275bec5b6a93ec8/core/vm/gas_table.go#L140
		self._gas += 375 + 375	# Basic cost + 1 topic
		self._gas += 8 * 32 * len(args)	# each arg assumed 32 bytes
		print("%s(%s)" % (name, ', '.join(['%s=%d' % (k, int(v)) for k, v in args.items()])))

	def gas_reset(self):
		self._gas = 0
		self._gas_refund = 0

	def gas_used(self):
		return self._gas, self._gas_refund, max(self._gas//2, self._gas - self._gas_refund)


class SparseMerkleMountainRange(object):
	def __init__(self):
		self._stor = Storage()

	def gas_used(self):
		return self._stor.gas_used()

	def gas_reset(self):
		self._stor.gas_reset()

	def emit(self, lvl, seq, item):
		self._stor.emit("Append", lvl=lvl, seq=seq, item=item)
		#print("Append(lvl=%d, seq=%d, item=%d)" % (lvl, seq, item))

	def append(self, item):
		lvl = 0
		while True:
			lvl_count_key = 'lvl.' + str(lvl)
			lvl_count = self._stor.get(lvl_count_key)

			self.emit(lvl, lvl_count, item)
			

			if lvl_count % 2 == 1:
				prev_val_key = "%d.%d" % (lvl, lvl_count - 1)
				prev_val = self._stor[prev_val_key]
				item = LongsightF12p5(prev_val, item)
				del self._stor[prev_val_key]
			else:
				val_key = "%d.%d" % (lvl, lvl_count)
				self._stor[val_key] = item

			lvl_count += 1
			self._stor[lvl_count_key] = lvl_count
			if lvl_count % 2 != 0:
				break
			lvl += 1


x = SparseMerkleMountainRange()

for i in range(0, randint(100, 5000)):
	x.append(i+1)
	peak, refund, total = x.gas_used()
	print("gas: peak=%d refund=%d total=%d" % (peak, refund, total))
	x.gas_reset()
	print("")

print("")

for k, v in x._stor._stor.items():
	if k.startswith('lvl.'):
		print("level %04d: %d" % (int(k.split('.')[1]), v))

print("")

for k, v in sorted(x._stor._stor.items()):
	if not k.startswith('lvl.'):
		print("level %04d item %04d: %d" % (int(k.split('.')[0]), int(k.split('.')[1]), v))