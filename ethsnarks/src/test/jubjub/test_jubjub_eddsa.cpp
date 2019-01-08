#include "jubjub/eddsa.hpp"
#include "utils.hpp"

using ethsnarks::jubjub::EdwardsPoint;
using ethsnarks::jubjub::VariablePointT;
using ethsnarks::jubjub::EdDSA_Verify;
using ethsnarks::jubjub::PureEdDSA_Verify;
using ethsnarks::bytes_to_bv;
using ethsnarks::FieldT;


namespace ethsnarks {


template<class T>
bool test_jubjub_eddsa(
    const EdwardsPoint& B,
    const EdwardsPoint& A,
    const EdwardsPoint& R,
    const FieldT& s,
    const libff::bit_vector& msg
) {
    ProtoboardT pb;
    jubjub::Params params;

    auto msg_var_bits = make_var_array(pb, msg.size(), "msg_var_bits");
    msg_var_bits.fill_with_bits(pb, msg);

    const auto A_var = A.as_VariablePointT(pb, "A");
    const auto R_var = R.as_VariablePointT(pb, "R");

    auto s_var_bits = make_var_array(pb, FieldT::size_in_bits(), "s_var_bits");
    s_var_bits.fill_with_bits_of_field_element(pb, s);

    T the_gadget(pb, params, B, A_var, R_var, s_var_bits, msg_var_bits, "the_gadget");

    the_gadget.generate_r1cs_witness();
    the_gadget.generate_r1cs_constraints();

    std::cout << "Num constraints: " << pb.num_constraints() << std::endl;

    return pb.is_satisfied();
}


// namespace ethsnarks
}


/*
To generate signatures for testing:

    from os import urandom
    from ethsnarks.eddsa import *
    B = Point.from_hash(b'eddsa_base')
    k = FQ.random(JUBJUB_L)
    m = urandom(31)
    R, S, A = pureeddsa_sign(m, k, B)
*/

int main( int argc, char **argv )
{
    ethsnarks::ppT::init_public_params();


    // Verify HashEdDSA - where message is hashed prior to signing
    const char *msg = "abc";
    const auto msg_bits = bytes_to_bv((const uint8_t*)msg, strlen(msg));
    if( ! ethsnarks::test_jubjub_eddsa<EdDSA_Verify>(
        {
            FieldT("21609035313031231356478892405209584931807557563713540183143349090940105307553"),
            FieldT("845281570263603011277359323511710394920357596931617398831207691379369851278")
        }, {
            FieldT("5616630816018221659484394091994939318481030030481519242876140465113436048304"),
            FieldT("8476221375891900895034976644661703008703725320613595264559419965669922411183")
        }, {
            FieldT("17883110238616315155327756854433987355427639458557188556819876765548551765197"),
            FieldT("11833558192785987866925773659755699683735551950878443451361314529874236222818")
        },
        FieldT("9920504625278683304895036460477595239370241328717115039061027107077120437288"),
        msg_bits
    )) {
        std::cerr << "FAIL\n";
        return 1;
    }

    // Verify PureEdDSA where no message compression is used for H(R,A,M)
    const char *msg2 = "abcd";
    const auto msg2_bits = bytes_to_bv((const uint8_t*)msg2, strlen(msg2));
    if( ! ethsnarks::test_jubjub_eddsa<PureEdDSA_Verify>(
        {
            FieldT("16117159321177103813813294286550615556837550473658220567209763364611339839115"),
            FieldT("11465736382824868633493204496205282307637286781164666440541087834417561817657")
        }, {
            FieldT("7232078318593313024960606529959628262327760580530543297615441605656275483008"),
            FieldT("13445187542498117393920468884784587115570437154948817232436446927611108297778")
        }, {
            FieldT("16748186150368319377210820880944935248945916993910817768852007732596413990860"),
            FieldT("4850962850934517657076914998696277193398065576910427229359881798401199408131")
        },
        FieldT("9530517511211249528464523051059372760063486304291273287859289432498093931519"),
        msg2_bits
    )) {
        std::cerr << "FAIL\n";
        return 1;
    }

    std::cout << "OK\n";
    return 0;
}
