#ifndef JUBJUB_PARAMS_HPP_
#define JUBJUB_PARAMS_HPP_

#include "ethsnarks.hpp"


namespace ethsnarks {

namespace jubjub {


class Params {
public:
    // Base point
    const FieldT Gx;
    const FieldT Gy;

    // twisted Edwards parameters
    const FieldT a;
    const FieldT d;

    // Montgomery parameters
    const FieldT A;
    const FieldT scale;

    Params() :
        Gx("16540640123574156134436876038791482806971768689494387082833631921987005038935"),
        Gy("20819045374670962167435360035096875258406992893633759881276124905556507972311"),
        a("168700"),
        d("168696"),
        A("168698"),
        scale("1")
    {}
};


// namespace jubjub
}

// namespace ethsnarks
}

// JUBJUB_PARAMS_HPP_
#endif
