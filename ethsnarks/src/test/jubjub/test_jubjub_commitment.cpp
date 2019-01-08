#include "jubjub/commitment.hpp"
#include "stubs.hpp"

using ethsnarks::FieldT;

namespace ethsnarks {
    
bool test_jubjub_commitment(
    const std::vector<jubjub::EdwardsPoint> in_points,
    const std::vector<FieldT> in_scalars,
    const FieldT in_expected_x,
    const FieldT in_expected_y
) {
    jubjub::Params params;

    std::vector<VariableArrayT> scalars;

    ProtoboardT pb;

    VariableT expected_x = make_variable(pb, in_expected_x, "expected_x");
    VariableT expected_y = make_variable(pb, in_expected_y, "expected_y");

    size_t i = 0;
    for( const auto& s : in_scalars ) {
        scalars.emplace_back();
        auto& var = scalars[scalars.size()-1];
        var.allocate(pb, 254, FMT("s", "%zu", i));
        var.fill_with_bits_of_field_element(pb, s);
        i += 1;
    }

    jubjub::Commitment the_gadget(pb, params, in_points, scalars, "the_gadget");

    the_gadget.generate_r1cs_witness();
    the_gadget.generate_r1cs_constraints();

    pb.add_r1cs_constraint(
        ConstraintT(expected_x, 1, the_gadget.result_x()),
            FMT("expected_x", " is correct"));

    pb.add_r1cs_constraint(
        ConstraintT(expected_y, 1, the_gadget.result_y()),
            FMT("expected_y", " is correct"));

    return pb.is_satisfied();
}


// namespace ethsnarks
}


int main( int argc, char **argv )
{
    // Types for board 
    ethsnarks::ppT::init_public_params();

    // Test 2 points
    if( ! ethsnarks::test_jubjub_commitment(
        {
            {FieldT("5567805418184289632147756797386939297552492549350438828849966834254236768053"),
             FieldT("12211740668908124738560443678335132239528947778387813753698502685621212356267")},
            {FieldT("1014897178776683700465153185417668029368564952996728930133332649103606654349"),
             FieldT("1912949077136662524685140410995329795897195347736015124979412035272178941280")}
        },
        {
            FieldT("10986450173123285754094078004335109933319969130344112319915385933216275031166"),
            FieldT("2005489705524582641429738422402014661880825960671904545851268453708789243098")
        },
        FieldT("21432886514156222616316186668441287251238348704077801933565007474921054371504"),
        FieldT("248033853556018705465489274950905395201511706850656570854551227822003731763")
    ) )
    {
        std::cerr << "FAIL (2)\n";
        return 1;
    }

    // Test 3 points
    if( ! ethsnarks::test_jubjub_commitment(
        {
            {FieldT("18711813783827180207124447196139534826112748455014411397103191885302573186177"),
             FieldT("7894085631011368230905512940366369177490751126789162452408410394984840330485")},
            {FieldT("7066372621571166136151614778064732022672458346166374172249046796138608396221"),
             FieldT("15873128071097042084149123594062827139607854335508714396010550569589457829538")},
            {FieldT("11166630027879447065465016890269933458618805196817439092349010687543808902655"),
             FieldT("19590404420753291829240914715638715665405852054741217113720101603220818441206")}
        },
        {
            FieldT("18758077331286283257526481560763239046487169323724789424303867883523177518991"),
            FieldT("2929375059378574084025515491022926415853781081439545806464600885278112080452"),
            FieldT("18752552816943644776177493132303579742946349691365286478792190991436230241840")
        },
        FieldT("2895672221531106372179277937393330340641376347537345474490018416084992452005"),
        FieldT("2943984801121732069162700109515379964711928521715052769262110639886654015489")
    ) )
    {
        std::cerr << "FAIL (3)\n";
        return 1;
    }

    std::cout << "OK\n";
    return 0;
}
