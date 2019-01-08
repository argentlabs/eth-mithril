#include "jubjub/scalarmult.hpp"
#include "utils.hpp"


namespace ethsnarks {


bool test_jubjub_mul()
{
    jubjub::Params params;
    ProtoboardT pb;

    VariableArrayT scalar;
    scalar.allocate(pb, 252, "scalar");
    scalar.fill_with_bits_of_field_element(pb, FieldT("6453482891510615431577168724743356132495662554103773572771861111634748265227"));

    VariableT x = make_variable(pb, "x");
    VariableT y = make_variable(pb, "y");
    pb.val(x) = FieldT("17777552123799933955779906779655732241715742912184938656739573121738514868268");
    pb.val(y) = FieldT("2626589144620713026669568689430873010625803728049924121243784502389097019475");

    auto expected_x = FieldT("14404769628348642617958769113059441570295803354118213050215321178400191767982");
    auto expected_y = FieldT("18111766293807611156003252744789679243232262386740234472145247764702249886343");

    jubjub::ScalarMult the_gadget(pb, params, x, y, scalar, "the_gadget");

    the_gadget.generate_r1cs_witness();
    the_gadget.generate_r1cs_constraints();

    if( pb.val(the_gadget.result_x()) != expected_x ) {
        std::cerr << "x mismatch" << std::endl;
        return false;
    }

    if( pb.val(the_gadget.result_y()) != expected_y ) {
        std::cerr << "y mismatch" << std::endl;
        return false;
    }

    std::cout << pb.num_constraints() << " constraints" << std::endl;
    std::cout << (pb.num_constraints() / float(scalar.size())) << " constraints per bit" << std::endl;

    return pb.is_satisfied();
}


// namespace ethsnarks
}


int main( int argc, char **argv )
{
    // Types for board 
    ethsnarks::ppT::init_public_params();

    if( ! ethsnarks::test_jubjub_mul() )
    {
        std::cerr << "FAIL\n";
        return 1;
    }

    std::cout << "OK\n";
    return 0;
}
