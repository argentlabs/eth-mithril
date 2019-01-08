// Copyright (c) 2018 HarryR
// License: GPL-3.0+

#include <cstring>
#include <iostream> // cerr
#include <fstream>  // ofstream

#include "mod/hashpreimage.cpp"
#include "utils.hpp"
#include "stubs.hpp"


using std::cerr;
using std::cout;
using std::ofstream;
using std::ifstream;
using std::stringstream;

using ethsnarks::stub_main_genkeys;
using ethsnarks::stub_main_verify;
using ethsnarks::hex_to_bytes;
using ethsnarks::mod_hashpreimage;


static int main_prove( int argc, char **argv )
{
    uint8_t input_buffer[64];
    const char *out_filename = nullptr;

    if( argc < 4 )
    {
        cerr << "Usage: " << argv[0] << " prove <pk.raw> <0x...64_bytes_as_hex> [proof.json]\n";
        cerr << "Without [proof.json] it will be echo'd to stdout\n";
        return 1;
    }

    auto pk_filename = argv[2];
    auto input_hex = argv[3];

    if( argc > 3 )
    {
        out_filename = argv[4];
    }

    if( ! hex_to_bytes(input_hex, input_buffer, 64) )
    {
        cerr << "Error: couldn't parse `input_buffer` from: " << argv[1] << "\n";
        return 2;
    }

    auto json = hashpreimage_prove(pk_filename, input_buffer);

    if( ! out_filename )
    {
        cout << json << "\n";
    }
    else {
        ofstream fh;
        fh.open(out_filename, std::ios::binary);
        fh << json;
        fh.flush();
        fh.close();
    }

    return 0;
}


int main( int argc, char **argv )
{
    if( argc < 2 )
    {
        cerr << "Usage: " << argv[0] << " <genkeys|prove|verify> [...]\n";
        return 1;
    }

    if( 0 == ::strcmp(argv[1], "prove") )
    {
        return main_prove(argc, argv);
    }
    else if( 0 == ::strcmp(argv[1], "genkeys") )
    {
        return stub_main_genkeys<mod_hashpreimage>(argv[0], argc-1, &argv[1]);
    }
    else if( 0 == ::strcmp(argv[1], "verify") )
    {
        return stub_main_verify(argv[0], argc-1, (const char **)&argv[1]);
    }

    cerr << "Error: unknown sub-command " << argv[1] << "\n";
    return 2;
}
