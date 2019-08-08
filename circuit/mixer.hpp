#ifndef MIXER_HPP_
#define MIXER_HPP_

#pragma once

#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C"
{
#endif

    const extern size_t MIXER_TREE_DEPTH;

    char *mixer_prove_json( const char *pk_file, const char *in_json );

    char *mixer_prove(
        const char *pk_file,
        const char *in_root,
        const char *in_wallet_address,
        const char *in_nullifier,
        const char *in_nullifier_secret,
        const char *in_address,
        const char **in_path);

    int mixer_genkeys(const char *pk_file, const char *vk_file);

    bool mixer_verify(const char *vk_json, const char *proof_json);

    size_t mixer_tree_depth(void);

#ifdef __cplusplus
}
#endif

#endif
