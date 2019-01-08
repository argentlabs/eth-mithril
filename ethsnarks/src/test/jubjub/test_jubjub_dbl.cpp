#include "jubjub/doubler.hpp"
#include "stubs.hpp"

namespace ethsnarks {
	
bool test_jubjub_dbl()
{
	jubjub::Params params;

	ProtoboardT pb;

	VariableT a_x = make_variable(pb, "a_x");
	VariableT a_y = make_variable(pb, "a_y");
	pb.val(a_x) = FieldT("16838670147829712932420991684129000253378636928981731224589534936353716235035");
	pb.val(a_y) = FieldT("4937932098257800452675892262662102197939919307515526854605530277406221704113");

	VariableT c_x = make_variable(pb, "c_x");
	VariableT c_y = make_variable(pb, "c_y");
	pb.val(c_x) = FieldT("1249069967781607466547858200520552758439927990791406532841560791635366786371");
	pb.val(c_y) = FieldT("10747067029747663615909968100597860241004259895153898217341596221843695010374");

	jubjub::PointDoubler the_gadget(pb, params, a_x, a_y, "the_gadget");

	the_gadget.generate_r1cs_witness();
	the_gadget.generate_r1cs_constraints();

	pb.add_r1cs_constraint(
        ConstraintT(c_x, 1, the_gadget.result_x()),
            FMT("expected x3", " is correct"));

	pb.add_r1cs_constraint(
        ConstraintT(c_y, 1, the_gadget.result_y()),
            FMT("expected y3", " is correct"));

	return pb.is_satisfied();
}


// namespace ethsnarks
}


int main( int argc, char **argv )
{
    // Types for board 
    ethsnarks::ppT::init_public_params();

    if( ! ethsnarks::test_jubjub_dbl() )
    {
        std::cerr << "FAIL\n";
        return 1;
    }

    std::cout << "OK\n";
    return 0;
}
