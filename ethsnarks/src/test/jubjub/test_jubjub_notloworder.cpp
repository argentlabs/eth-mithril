#include "jubjub/notloworder.hpp"
#include "utils.hpp"

using ethsnarks::FieldT;

struct Point {
    FieldT x;
    FieldT y;
};


namespace ethsnarks {

    
bool test_jubjub_notloworder(bool expected_result, const Point& in_point)
{
    jubjub::Params params;

    ProtoboardT pb;

    VariableT var_x = make_variable(pb, in_point.x, "var_x");
    VariableT var_y = make_variable(pb, in_point.y, "var_y");

    jubjub::NotLowOrder the_gadget(pb, params, var_x, var_y, "the_gadget");

    the_gadget.generate_r1cs_witness();
    the_gadget.generate_r1cs_constraints();

    return pb.is_satisfied() == expected_result;
}


// namespace ethsnarks
}


int main( int argc, char **argv )
{
    ethsnarks::ppT::init_public_params();

    std::vector<Point> low_order_points = {
        {FieldT("0"),
         FieldT("1")},

        {FieldT("4342719913949491028786768530115087822524712248835451589697801404893164183326"),
         FieldT("4826523245007015323400664741523384119579596407052839571721035538011798951543")},

        {FieldT("17545522957889784193459637215142187266023652151580582754000402781682644312291"),
         FieldT("17061719626832259898845741003733890968968767993363194771977168648564009544074")},

        {FieldT("18930368022820495955728484915491405972470733850014661777449844430438130630919"),
         FieldT("0")},

        {FieldT("2957874849018779266517920829765869116077630550401372566248359756137677864698"),
         FieldT("0")},

        {FieldT("4342719913949491028786768530115087822524712248835451589697801404893164183326"),
         FieldT("17061719626832259898845741003733890968968767993363194771977168648564009544074")},

        {FieldT("0"),
         FieldT("21888242871839275222246405745257275088548364400416034343698204186575808495616")},

        {FieldT("17545522957889784193459637215142187266023652151580582754000402781682644312291"),
         FieldT("4826523245007015323400664741523384119579596407052839571721035538011798951543")},
    };

    int i = 1;
    for( const auto& p : low_order_points )
    {
        if( ! ethsnarks::test_jubjub_notloworder(false, p) )
        {
            std::cerr << "FAIL\n";
            return i;
        }
        i++;    
    }

    std::vector<Point> normal_points = {
        {FieldT("10657778831676136358931702237911772396037479284083882279590955996478431574932"),
         FieldT("14493726596329109458217280019868056472506193969483340532366215427503893148042")},

        {FieldT("12270702296682179429054196838232844499684385799449748076666923281911121296647"),
         FieldT("3109481945422795097766933698268050183973759353715280291861585133507495786832")},

        {FieldT("18132897677589980670480742551885775017792594288121259998847003436234167218632"),
         FieldT("5131541471716336228334303233250961274216912158492742225987808352154889400096")}
    };

    for( const auto& p : normal_points )
    {
        if( ! ethsnarks::test_jubjub_notloworder(true, p) )
        {
            std::cerr << "FAIL\n";
            return i;
        }
        i++;    
    }

    std::cout << "OK\n";
    return 0;
}
