#include "utils.hpp"
#include "ethsnarks.hpp"

using ethsnarks::ppT;
using ethsnarks::ProvingKeyT;
using ethsnarks::loadFromFile;


int main( int argc, char **argv )
{
	ppT::init_public_params();

	if( argc < 2 ) {
		std::cerr << "Usage: " << argv[0] << " <proofkey.raw>\n";
		return 1;
	}

	ProvingKeyT pk = loadFromFile<ProvingKeyT>(argv[1]);

    std::cout << "OK\n";

	return 0;
}