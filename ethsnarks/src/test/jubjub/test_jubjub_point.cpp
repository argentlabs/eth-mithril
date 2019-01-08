#include "jubjub/point.hpp"


using ethsnarks::FieldT;
using ethsnarks::jubjub::EdwardsPoint;

namespace ethsnarks {


bool test_point_from_y(const FieldT& expected_x, const FieldT& in_y)
{
    const jubjub::Params params;
    const auto p = EdwardsPoint::from_y_always(in_y, params);
    return expected_x == p.x;
}


bool test_point_from_hash( const char *data, size_t sz, const EdwardsPoint& expected )
{
    const jubjub::Params params;
    const auto p = EdwardsPoint::from_hash((void*)data, sz, params);

    if( p.y != expected.y ) {
        std::cerr << "FAIL - expected y mismatch" << std::endl;
        std::cerr << "Expected "; expected.y.print();
        std::cerr << "Actual "; p.y.print();
        return false;
    }

    if( p.x != expected.x ) {
        std::cerr << "FAIL - expected x mismatch" << std::endl;
        std::cerr << "Expected "; expected.x.print();
        std::cerr << "Actual "; p.x.print();
        return false;
    }

    return true;
}


bool test_basepoint_expected( const char *name, unsigned int n, const EdwardsPoint expected )
{
    const jubjub::Params params;
    const auto p = EdwardsPoint::make_basepoint(name, n, params);

    if( p.y != expected.y ) {
        std::cerr << "FAIL - expected y mismatch" << std::endl;
        std::cerr << "Expected "; expected.y.print();
        std::cerr << "Actual "; p.y.print();
        return false;
    }

    if( p.x != expected.x ) {
        std::cerr << "FAIL - expected x mismatch" << std::endl;
        std::cerr << "Expected "; expected.x.print();
        std::cerr << "Actual "; p.x.print();
        return false;
    }

    return true;
}


// namespace ethsnarks
}


bool testcases_from_hash ()
{
    struct PointFromHashTestCase {
        const char *data;
        size_t sz;
        EdwardsPoint expected;
    };

    std::vector<PointFromHashTestCase> test_cases = {
        {"test", 4,
         {FieldT("6310387441923805963163495340827050724868600896655464356695079365984952295953"),
          FieldT("12999349368805111542414555617351208271526681431102644160586079028197231734677")}}
    };

    for( const auto& testcase : test_cases )
    {
        if( ! ethsnarks::test_point_from_hash(testcase.data, testcase.sz, testcase.expected) ) {
            return false;
        }
    }

    return true;
}


static bool testcases_from_y ()
{
    struct PointFromYTestCase {
        FieldT x;
        FieldT y;
    };

    std::vector<PointFromYTestCase> test_cases = {
        // 0
        {FieldT("20616554786359396897066290204264220576319536076538991133935783866206841138898"),
         FieldT("10592275084648178561464128859907688344447649297734555224341876545305639835999")},

        // 1, verifies that Y coordinate is incremented after not finding a square root
        {FieldT("20616554786359396897066290204264220576319536076538991133935783866206841138898"),
         FieldT("10592275084648178561464128859907688344447649297734555224341876545305639835998")},

        // 2
        {FieldT("11610117029953798428826613242669939481045605849364609771767823351326159443609"),
         FieldT("3722409228507723418678713896319610332389736117851027921973860155000856891140")},

        // 3
        {FieldT("21680045038775759642189425577922609025982451102460978847266452551495203884482"),
         FieldT("6168854640927408084732268325506202000962285527703379133980054444068219727690")},

        // 4
        {FieldT("18879782252170350866370777185563748782908354718484814019474117245310535071541"),
         FieldT("2946855428411022359321514310392164228862398839132752152798293872913224129374")}
    };

    int i = 0;
    for( const auto& testcase : test_cases )
    {
        if( ! ethsnarks::test_point_from_y(testcase.x, testcase.y) ) {
            std::cerr << "FAIL testcases_from_y " << i << std::endl;
            return false;
        }

        i += 1;
    }

    return true;
}


bool testcases_basepoint()
{
    struct TestcaseBasepoint {
        const char *name;
        unsigned int n;
        EdwardsPoint expected;
    };

    std::vector<TestcaseBasepoint> test_cases = {
        {"test", 3, {
            FieldT("6325232514758476047657295329562397658895927829648225433723319142523734188126"),
            FieldT("14815770185427470544334506238195577620110904285381068559206285331777725695895")}},
        {"0123456789012345678912345678", 65534, {
            FieldT("8763217421961576778406532484867718904583472092215613710660899805738458038487"),
            FieldT("15658432742711332940634965710759465758177105318005110010402361107342563090103")
        }}
    };

    int i = 0;
    for( const auto& testcase : test_cases )
    {
        if( ! ethsnarks::test_basepoint_expected(testcase.name, testcase.n, testcase.expected) ) {
            std::cerr << "FAIL testcases_basepoint " << i << std::endl;
            return false;
        }

        i += 1;
    }

    return true;
}


int main( void )
{
    ethsnarks::ppT::init_public_params();

    bool result = testcases_from_y();
    result &= testcases_from_hash();
    result &= testcases_basepoint();

    if( result ) {
        std::cout << "OK" << std::endl;
        return 0;
    }

    return 1;
}