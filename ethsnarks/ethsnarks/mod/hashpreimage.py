__all__ = ('HashPreimage',)

import os
import ctypes
from ctypes import cdll

from ..verifier import Proof, VerifyingKey


class HashPreimage(object):
    def __init__(self, native_library_path, vk, pk_file=None):
        if pk_file:
            if not os.path.exists(pk_file):
                raise RuntimeError("Proving key file doesnt exist: " + pk_file)
        self._pk_file = pk_file

        if not isinstance(vk, VerifyingKey):
            if isinstance(vk, dict):
                vk = VerifyingKey.from_dict(vk)
            elif os.path.exists(vk):
                vk = VerifyingKey.from_file(vk)
            else:
                vk = VerifyingKey.from_json(vk)
        if not isinstance(vk, VerifyingKey):
            raise TypeError("Invalid vk type")
        self._vk = vk

        lib = cdll.LoadLibrary(native_library_path)

        lib_prove = lib.hashpreimage_prove
        lib_prove.argtypes = [ctypes.c_char_p, ctypes.c_char_p] 
        lib_prove.restype = ctypes.c_char_p
        self._prove = lib_prove

        lib_verify = lib.hashpreimage_verify
        lib_verify.argtypes = [ctypes.c_char_p, ctypes.c_char_p] 
        lib_verify.restype = ctypes.c_bool
        self._verify = lib_verify

    def prove(self, preimage, pk_file=None):        
        if pk_file is None:
            pk_file = self._pk_file
        if pk_file is None:
            raise RuntimeError("No proving key file")
        if len(preimage) != 64:
            raise RuntimeError("Invalid preimage size, must be 64 bytes")

        pk_file_cstr = ctypes.c_char_p(pk_file.encode('ascii'))
        preimage_cstr = ctypes.c_char_p(preimage)

        data = self._prove(pk_file_cstr, preimage_cstr)
        if data is None:
            raise RuntimeError("Could not prove!")
        return Proof.from_json(data)

    def verify(self, proof):
        if not isinstance(proof, Proof):
            raise TypeError("Invalid proof type")

        vk_cstr = ctypes.c_char_p(self._vk.to_json().encode('ascii'))
        proof_cstr = ctypes.c_char_p(proof.to_json().encode('ascii'))

        return self._verify( vk_cstr, proof_cstr )
