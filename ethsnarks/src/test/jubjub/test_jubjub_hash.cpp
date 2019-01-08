#include "jubjub/pedersen_hash.hpp"
#include "utils.hpp"


namespace ethsnarks {


static bool test_jubjub_hash_varbits(ProtoboardT& pb, const char *name, const VariableArrayT& data_variables, const jubjub::EdwardsPoint& expected)
{	
	const jubjub::Params params;

	jubjub::PedersenHash the_gadget(pb, params, name, data_variables, "the_gadget");
	the_gadget.generate_r1cs_constraints();
	the_gadget.generate_r1cs_witness();

	bool is_ok = true;
	if( expected.x != pb.val(the_gadget.result_x()) )
	{
		std::cerr << "FAIL unexpected x" << std::endl;
		std::cerr << "Expected:"; expected.x.print();
		std::cerr << "  Actual:"; pb.val(the_gadget.result_x()).print();
		is_ok = false;
	}

	if( expected.y != pb.val(the_gadget.result_y())  )
	{
		std::cerr << "FAIL unexpected y" << std::endl;
		std::cerr << "Expected:"; expected.y.print();
		std::cerr << "  Actual:"; pb.val(the_gadget.result_y()).print();
		is_ok = false;
	}

	return is_ok && pb.is_satisfied();
}


static bool test_jubjub_hash_bytes(const char *name, const uint8_t *data, size_t data_sz, const jubjub::EdwardsPoint& expected)
{	
	ProtoboardT pb;

	const auto data_bitvector = bytes_to_bv(data, data_sz);
	const auto data_variables = VariableArray_from_bits(pb, data_bitvector, "data_bitvector");

	return test_jubjub_hash_varbits(pb, name, data_variables, expected);
}


static bool test_jubjub_hash_bits(const char *name, const char *bits_str, const jubjub::EdwardsPoint& expected)
{	
	ProtoboardT pb;

	const size_t data_sz = ::strlen(bits_str);
	libff::bit_vector data_bitvector;
	data_bitvector.resize(data_sz);
	for( size_t i = 0; i < data_sz; i++ )
	{
		data_bitvector[i] = bits_str[i] == '1' ? true : false;
	}

	const auto data_variables = VariableArray_from_bits(pb, data_bitvector, "data_bitvector");
	return test_jubjub_hash_varbits(pb, name, data_variables, expected);
}


bool testcases_jubjub_hash( void )
{
	struct TestcaseJubjubHash {
		const char *name;
		const char *data;
		jubjub::EdwardsPoint expected;
	};

	// Testcases for bytes
	const std::vector<TestcaseJubjubHash> testcases_bytes = {
		{"EdDSA_Verify.m", "abc", {
			FieldT("9731843879694143436495111581488282877782046018277278061737612767920874642317"),
			FieldT("18679624827252625091380135611330259545748299185353272409619199893672152553192")}
		},
		{"EdDSA_Verify.m", "abcdefghijklmnopqrstuvwx", {
			FieldT("2924038456136707858258403902562106998409981203870787479135526690738568452881"),
			FieldT("14512385781738072049298244430820733351541114749367860936355491268534915271519")}
		}
	};
	size_t i = 0;
	for( const auto& test_case : testcases_bytes )
	{
		if( ! test_jubjub_hash_bytes(test_case.name, (uint8_t*)test_case.data, ::strlen(test_case.data), test_case.expected) ) {
			std::cerr << "Test case (bytes) " << i << std::endl;
			return false;
		}

		i += 1;
	}

	// Testcases for bits
	const std::vector<TestcaseJubjubHash> testcases_bits = {
		{"EdDSA_Verify.RAM", "101100110011111001100100101100010100011010100100001011101001000100100000001111101101111001001010111011101101011010010101101101101", {
			FieldT("10144551998940780328480570968929560941696149755089905049697570749773419347132"),
			FieldT("4379402081581385421046180178189642838656866939902458804157110827242522697027")}
		},
		{"EdDSA_Verify.RAM", "101100110011111001100100101100010100011010100100001011101001000100100000001111101101111001001010111011101101011010010101101101101000000010000000101010110100011110101110111100111100011110", {
			FieldT("11412003442196309874355977181423439876195143281789888359346965463436079815120"),
			FieldT("6197468436400950694139168074357138895996057806430011612085965864869751979160")}
		},
		{"EdDSA_Verify.RAM", "110000011001000100111001110010111000010011000110100000001010011011100001010000010001011011011010000001100000010101100001011101001010000011001111101000010010000111100110111001011100001001000", {
			FieldT("14045508791325353580494855977548389716424041263427327046036601485042042851718"),
			FieldT("15954708971572753815495876887310661753138650367206890755040363216818746514839")}
		},
		{"EdDSA_Verify.RAM", "101100110011111001100100101100010100011010100100001011101001000100100000001111101101111001001010111011101101011010010101101101101000000010000000101010110100011110101110111100111100011110110011100101011000000000110101111001110000101011011110100100011110010000110111010011000001000100101100101111001100100010110101", {
			FieldT("19005197533474047798024069747770576951728720804384764258027545974476779777665"),
			FieldT("14842872842509552797083293685791231389239778484277682907664087789150676438253")}
		},
		{"EdDSA_Verify.RAM", "101100110011111001100100101100010100011010100100001011101001000100100000001111101101111001001010111011101101011010010101101101101000000010000000101010110100011110101110111100111100011110110011100101011000000000110101111001110000101011011110100100011110010000110111010011000001000100101100101111001100100010110101100010001000000101111011011010010011110001110111101011110001111111100010010000110101000001010111000111011110111010010010000101110000011001111000101010001101100000110111111110011001110101011000110010111111000101001100010001011011101010101011101010110000111100101000000110011000011001101000001010110110010000110101011111100010111011100110111101110111011001001110100100110010100111001000001010101010010100010100101101000010100010000111110101111000101110", {
			FieldT("16391910732431349989910402670442677728780476741314399751389577385062806845560"),
			FieldT("9557600014660247419117975756584483223203707451467643504980876223495155042156")}
		}
	};
	i = 0;
	for( const auto& test_case : testcases_bits )
	{
		if( ! test_jubjub_hash_bits(test_case.name, test_case.data, test_case.expected) ) {
			std::cerr << "Test case (bits) " << i << std::endl;
			return false;
		}

		i += 1;
	}

	return true;
}


// namespace ethsnarks
}


int main( void )
{
	ethsnarks::ppT::init_public_params();

	if( ! ethsnarks::testcases_jubjub_hash() )
	{
        std::cerr << "FAIL\n";
        return 1;
    }

    std::cout << "OK\n";
    return 0;
}
