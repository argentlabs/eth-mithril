#include "ethsnarks.hpp"
#include "utils.hpp"
#include "stubs.hpp"
#include "gadgets/lookup_2bit.hpp"

using ethsnarks::FieldT;


namespace ethsnarks {


bool test_lookup_2bit(const std::vector<FieldT> rand_items)
{
    ProtoboardT pb;

    std::vector<VariableArrayT> items;
    std::vector<lookup_2bit_gadget> gadgets;

    for( size_t i = 0; i < rand_items.size(); i++ )
    {
        items.emplace_back( );
        items[i].allocate(pb, 2, FMT("items.", "%d", i));
        items[i].fill_with_bits_of_ulong(pb, i);

        gadgets.emplace_back( pb, rand_items, items[i], FMT("the_gadget.", "%d", i) );
        gadgets[i].generate_r1cs_witness();
        gadgets[i].generate_r1cs_constraints();

        assert( pb.val(gadgets[i].result()) == rand_items[i] );

        if( ! pb.is_satisfied() ) {
            std::cerr << "Not satisfied " << i << std::endl;
            return false;
        }
    }

    return true;
}

// namespace ethsnarks
}


int main( int argc, char **argv )
{
    // Types for board 
    ethsnarks::ppT::init_public_params();

    if( ! ethsnarks::test_lookup_2bit({
        FieldT::random_element(), FieldT::random_element(),
        FieldT::random_element(), FieldT::random_element()
    }))
    {
        std::cerr << "FAIL 1\n";
        return 1;
    }

    if( ! ethsnarks::test_lookup_2bit({
        FieldT::one(), FieldT::zero(),
        FieldT::zero(), FieldT::one()
    }))
    {
        std::cerr << "FAIL 2\n";
        return 1;
    }

    if( ! ethsnarks::test_lookup_2bit({
        FieldT::zero(), FieldT::one(),
        FieldT::one(), FieldT::zero()
    }))
    {
        std::cerr << "FAIL 3\n";
        return 1;
    }

    if( ! ethsnarks::test_lookup_2bit({
        FieldT::one(), FieldT::one(),
        FieldT::one(), FieldT::one()
    }))
    {
        std::cerr << "FAIL 4\n";
        return 1;
    }

    std::cout << "OK\n";
    return 0;
}
