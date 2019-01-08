#ifndef HASHPREIMAGE_HPP_
#define HASHPREIMAGE_HPP_

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdbool.h>

/**
* Create a proof of a 64 byte preimage without revealing it to the verifier
*
* @param pk_file Path of file which contains the proving key
* @param preimage_bytes64 512 bits, used as the input block to the hash
* @returns Proof string, as a JSON-encoded dictionary
*/
char *hashpreimage_prove( const char *pk_file, const uint8_t *preimage_bytes64 );

/**
* Generate the proving key for the hashpreimage circuit
* @param pk_file Output proving key (as JSON) to this file path
* @param pk_file Output verifying key (as JSON) to this file path
*/
int hashpreimage_genkeys( const char *pk_file, const char *vk_file );

/**
* Verify a supplied proof against the verifying key
*
* @param vk_json Verifing key, string of JSON encoded data
* @param proof_json Proof, string of JSON encoded data
* @return true if valid
*/
bool hashpreimage_verify( const char *vk_json, const char *proof_json );

#ifdef __cplusplus
} // extern "C"
#endif

// HASHPREIMAGE_HPP_
#endif
