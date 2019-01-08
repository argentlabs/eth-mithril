# Copyright (c) 2018 HarryR
# License: LGPL-3.0+

import hashlib
import math

from .longsight import LongsightL12p5_MP
from .field import FQ, SNARK_SCALAR_FIELD


class MerkleProof(object):
    __slots__ = ('leaf', 'address', 'path', '_hasher')
    def __init__(self, leaf, address, path, hasher):
        self.leaf = leaf
        self.address = address
        self.path = path
        self._hasher = hasher

    def verify(self, root):
        item = self.leaf
        depth = 0
        for bit, node in zip(self.address, self.path):
            if bit:
                item = self._hasher.hash_pair(depth, node, item)
            else:
                item = self._hasher.hash_pair(depth, item, node)
            depth += 1
        return root == item


class MerkleHasherLongsight(object):
    def __init__(self, tree_depth):
        self._tree_depth = tree_depth
        self._IVs = self._make_IVs()

    def hash_pair(self, depth, left, right):
        IV = self._IVs[depth]
        return LongsightL12p5_MP([left, right], IV)

    def unique(self, depth, index):
        assert depth < self._tree_depth
        item = int(depth).to_bytes(2, 'big') + int(index).to_bytes(30, 'big')
        hasher = hashlib.sha256()
        hasher.update(item)
        return int.from_bytes(hasher.digest(), 'big') % SNARK_SCALAR_FIELD

    def _make_IVs(self):
        out = []
        hasher = hashlib.sha256()
        for i in range(0, self._tree_depth):
            item = int(i).to_bytes(2, 'little')
            hasher.update(b'MerkleTree-' + item)
            digest = int.from_bytes(hasher.digest(), 'big') % SNARK_SCALAR_FIELD
            out.append(digest)
        return out

    def valid(self, item):
        return isinstance(item, int) and item > 0 and item < SNARK_SCALAR_FIELD


class MerkleTree(object):
    def __init__(self, n_items):
        assert n_items > 1
        self._tree_depth = math.ceil(math.log2(n_items))
        self._hasher = MerkleHasherLongsight(self._tree_depth)
        self._n_items = n_items
        self._cur = 0
        self._leaves = [list() for _ in range(0, self._tree_depth + 1)]

    def __len__(self):
        return self._cur

    def update(self, index, leaf):
        if isinstance(leaf, FQ):
            leaf = leaf.n
        if not isinstance(leaf, int):
            raise TypeError("Invalid key")
        assert leaf >= 0 and leaf < SNARK_SCALAR_FIELD
        if (len(self._leaves[0]) - 1) < index:
            raise KeyError("Out of bounds")
        self._leaves[0][index] = leaf
        self._updateTree(index)

    def append(self, leaf):
        if self._cur >= (self._n_items):
            raise RuntimeError("Tree Full")
        if isinstance(leaf, FQ):
            leaf = leaf.n
        assert leaf >= 0 and leaf < SNARK_SCALAR_FIELD
        self._leaves[0].append(leaf)
        self._updateTree()
        self._cur += 1
        return self._cur - 1

    def __getitem__(self, key):
        if not isinstance(key, int):
            raise TypeError("Invalid key")
        if key < 0 or key >= self._cur:
            raise KeyError("Out of bounds")
        return self._leaves[0][key]

    def __setitem__(self, key, value):
        self.update(key, value)

    def __contains__(self, key):
        return key in self._leaves[0]

    def index(self, leaf):
        return self._leaves[0].index(leaf)

    def proof(self, index):
        leaf = self[index]
        if index >= self._cur:
            raise RuntimeError("Proof for invalid item!")
        address_bits = list()
        merkle_proof = list()
        for i in range(0, self._tree_depth):
            if index % 2 == 0:
                proof_item = self.leaf(i, index + 1)
            else:
                proof_item = self.leaf(i, index - 1)
            address_bits.append( index % 2 )
            merkle_proof.append( proof_item )
            index = index // 2
        return MerkleProof(leaf, address_bits, merkle_proof, self._hasher)

    def _updateTree(self, cur_index=None):
        cur_index = self._cur if cur_index is None else cur_index
        for depth in range(0, self._tree_depth):
            next_index = cur_index // 2
            if cur_index % 2 == 0:
                leaf1 = self._leaves[depth][cur_index]
                leaf2 = self.leaf(depth, cur_index + 1)
            else:
                leaf1 = self.leaf(depth, cur_index - 1)
                leaf2 = self._leaves[depth][cur_index]
            node = self._hasher.hash_pair(depth, leaf1, leaf2)
            if len(self._leaves[depth+1]) == next_index:
                self._leaves[depth+1].append(node)
            else:
                self._leaves[depth+1][next_index] = node
            cur_index = next_index

    def leaf(self, depth, offset):
        if offset >= len(self._leaves[depth]):
            leaf = self._hasher.unique(depth, offset)
        else:
            leaf = self._leaves[depth][offset]
        return leaf

    @property
    def root(self):
        if self._cur == 0:
            return None
        return self._leaves[self._tree_depth][0]
