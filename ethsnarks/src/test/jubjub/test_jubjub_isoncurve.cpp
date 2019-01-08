#include "jubjub/isoncurve.hpp"
#include "stubs.hpp"

using ethsnarks::FieldT;

namespace ethsnarks {


bool test_jubjub_isoncurve(const FieldT& x, const FieldT& y, bool expected_result)
{
    jubjub::Params params;

    ProtoboardT pb;

    const auto var_x = make_variable(pb, x, "x");
    const auto var_y = make_variable(pb, y, "y");

    jubjub::IsOnCurve the_gadget(pb, params, var_x, var_y, "the_gadget");

    the_gadget.generate_r1cs_witness();
    the_gadget.generate_r1cs_constraints();

    return (pb.is_satisfied() == expected_result);
}


// namespace ethsnarks
}


typedef struct {
    FieldT x;
    FieldT y;
    bool expected_result;
} isoncurve_test_t;


int main( int argc, char **argv )
{
    ethsnarks::ppT::init_public_params();

    // X/Y coordinates of points, and the status of whether or not it's on a curve
    const isoncurve_test_t tests[] = {
        {FieldT::zero(), FieldT::one(), true},

        {FieldT::one(), FieldT::one(), false},

        {FieldT::one(), FieldT::zero(), false},

        {FieldT::zero(), FieldT::zero(), false},

        {FieldT("17777552123799933955779906779655732241715742912184938656739573121738514868268"),
         FieldT("2626589144620713026669568689430873010625803728049924121243784502389097019475"), true},

        {FieldT("6890855772600357754907169075114257697580319025794532037257385534741338397365"),
         FieldT("4338620300185947561074059802482547481416142213883829469920100239455078257889"), true}
    };

    for( const auto& test : tests )
    {
        if( ! ethsnarks::test_jubjub_isoncurve(test.x, test.y, test.expected_result) )
        {
            std::cerr << "FAIL\n";
            return 1;
        }
    }

    std::cout << "OK\n";
    return 0;
}
