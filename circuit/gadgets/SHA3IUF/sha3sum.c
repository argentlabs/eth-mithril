// This is an open source non-commercial project. Dear PVS-Studio, please check it.
// PVS-Studio Static Code Analyzer for C, C++ and C#: http://www.viva64.com

/* -------------------------------------------------------------------------
 * Run SHA-3 (NIST FIPS 202) on the given file. 
 *
 * Call as
 *
 * sha3sum 256|384|512 file_path
 *
 * See sha3.c for additional details. 
 *
 * Jun 2018. Andrey Jivsov. crypto@brainhub.org
 * ---------------------------------------------------------------------- */

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <sys/types.h>
#include <stdlib.h>

#include "sha3.h"

static void help(const char *argv0) {
    printf("To call: %s 256|384|512 file_path.\n", argv0);
}

static void byte_to_hex(uint8_t b, char s[23]) {
    unsigned i=1;
    s[0] = s[1] = '0';
    s[2] = '\0';
    while(b) {
        unsigned t = b & 0x0f;
        if( t < 10 ) {
            s[i] = '0' + t;
        } else {
            s[i] = 'a' + t - 10;
        }
        i--;
        b >>= 4;
    }
}

int main(int argc, char *argv[])
{
    sha3_context c;
    const uint8_t *hash;
    int image_size;
    const char *file_path;
    FILE* fd;
    int i;

    if( argc != 3 ) {
	    help(argv[0]);
	    return 1;
    }

    image_size = atoi(argv[1]);
    switch( image_size ) {
	case 256:
	case 384:
	case 512:
		break;
	default:
		help(argv[0]);
		return 1;
    }

    file_path = argv[2];

    fd = fopen(file_path, "r");
    if( fd == NULL ) {
	    printf("Cannot open file '%s' for reading", file_path);
	    return 2;
    }

    switch(image_size) {
	case 256:
    		sha3_Init256(&c);
		break;
	case 384:
    		sha3_Init384(&c);
		break;
	case 512:
    		sha3_Init512(&c);
		break;
    }

    while( 1 )
    {
        char buffer[1024];
        size_t nbytes = fread(buffer, 1024, 1, fd);

        if( nbytes > 0 ) {
            sha3_Update(&c, buffer, 1024);
        }

        if( nbytes != 1024 )
        {
            break;
        }
    }

    fclose(fd);

    hash = sha3_Finalize(&c);

    for(i=0; i<image_size/8; i++) {
	    char s[3];
	    byte_to_hex(hash[i],s);
	    printf("%s", s);
    }
    printf("  %s\n", file_path);

    return 0;
}
