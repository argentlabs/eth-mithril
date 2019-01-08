#include "jubjub/adder.hpp"
#include "stubs.hpp"

namespace ethsnarks {
	
bool test_jubjub_add()
{
	jubjub::Params params;

	ProtoboardT pb;

	VariableT a_x = make_variable(pb, "a_x");
	VariableT a_y = make_variable(pb, "a_y");
	pb.val(a_x) = FieldT("16838670147829712932420991684129000253378636928981731224589534936353716235035");
	pb.val(a_y) = FieldT("4937932098257800452675892262662102197939919307515526854605530277406221704113");

	VariableT b_x = make_variable(pb, "b_x");
	VariableT b_y = make_variable(pb, "b_y");
	pb.val(b_x) = FieldT("1538898545681068144632304956674715144385644913102700797899565858629154026483");
	pb.val(b_y) = FieldT("2090866097726307108368399316617534306721374642464311386024657526409503477525");

	VariableT c_x = make_variable(pb, "c_x");
	VariableT c_y = make_variable(pb, "c_y");
	pb.val(c_x) = FieldT("6973964026021872993461206321838264291006454903617648820964060641444266170799");
	pb.val(c_y) = FieldT("5058405786102109493822166715025707301516781386582502239931016782220981024527");

	jubjub::PointAdder the_gadget(pb, params, a_x, a_y, b_x, b_y, "the_gadget");

	the_gadget.generate_r1cs_witness();
	the_gadget.generate_r1cs_constraints();

	pb.add_r1cs_constraint(
        ConstraintT(c_x, 1, the_gadget.result_x()),
            FMT("x3", " is correct"));

	pb.add_r1cs_constraint(
        ConstraintT(c_y, 1, the_gadget.result_y()),
            FMT("y3", " is correct"));

	return pb.is_satisfied();
}


// namespace ethsnarks
}


int main( int argc, char **argv )
{
    // Types for board 
    ethsnarks::ppT::init_public_params();

    if( ! ethsnarks::test_jubjub_add() )
    {
        std::cerr << "FAIL\n";
        return 1;
    }

    std::cout << "OK\n";
    return 0;
}
