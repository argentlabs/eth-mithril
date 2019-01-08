// Copyright (c) 2018 HarryR
// License: LGPL-3.0+

#pragma once

#include <libsnark/gadgetlib1/gadget.hpp>
#include <libsnark/gadgetlib1/gadgets/basic_gadgets.hpp>

#include "ethsnarks.hpp"

using libsnark::r1cs_constraint;
using libsnark::generate_boolean_r1cs_constraint;


namespace ethsnarks {

/**
* The 1-of-N gadget verifies whether an Input exists within a set of items
*
*   e.g. MyValue ∈ Values
*
* To do this, it uses 3 variables:
*
*  - our_item
*  - items[]
*  - toggles[]
*
* For example:
*
*  - our_item = 4
*  - items = [1, 2, 3, 4, 5, 6, 7, 8, 9]
*  - toggles = [0, 0, 0, 1, 0, 0, 0, 0, 0]
*
* You must indicate which value is yours by setting the appropriate toggle
*
* It works this way because the constraints for each item must be the same
* Where a constraint is A * B - C. The constraints for the above would be:
*
*  - ensure_bitness(toggles)
*  - sum(toggles) == 1
*  - (items[i] * toggles[i]) == (toggles[i] * our_item)
* 
* This ensures that only 1 item is toggled, and whichever one it is is ours.
*/
class one_of_n : public GadgetT
{
public:
    const VariableT &our_item;
    const VariableArrayT &items;
    VariableArrayT toggles;
    VariableArrayT toggles_sum;
    const std::string annotation_prefix="";

    one_of_n(
        ProtoboardT &in_pb,
        const VariableT &in_our_item,
        const VariableArrayT &in_items,
        const std::string &in_annotation_prefix=""
    ) :
        GadgetT(in_pb, FMT(in_annotation_prefix, " one_of_n")),
        our_item(in_our_item),
        items(in_items),
        toggles(),
        toggles_sum(),
        annotation_prefix(in_annotation_prefix)
    {
        assert( in_items.size() > 0 );

        toggles.allocate(in_pb, in_items.size(), FMT(annotation_prefix, " toggles"));

        toggles_sum.allocate(in_pb, in_items.size(), FMT(annotation_prefix, " toggles_sum"));
    }

    void generate_r1cs_constraints()
    {
        // ensure bitness of toggles
        for( size_t i = 0; i < items.size(); i++ )
        {
            generate_boolean_r1cs_constraint<FieldT>(pb, toggles[i], FMT(annotation_prefix, ".toggles_%zu_bitness", i));
        }

        // ensure the sum of toggles equals 1
        for( size_t i = 1; i < toggles.size(); i++ )
        {
            pb.add_r1cs_constraint(
                r1cs_constraint<FieldT>(
                    toggles_sum[i-1] + toggles[i],
                    FieldT::one(),
                    toggles_sum[i]),
                FMT(this->annotation_prefix, ".toggles_sum_%zu", i));
        }
        pb.add_r1cs_constraint(
                r1cs_constraint<FieldT>(
                    toggles_sum[items.size()-1],
                    FieldT::one(),
                    FieldT::one()),
                FMT(this->annotation_prefix, ".toggles_sum_eq_1"));

        // XXX: why use `lc_val` here?
        auto our_item_lc_val = pb.lc_val(our_item);

        // then multiply toggles with items
        // subtract toggle*our_item
        for( size_t i = 0; i < items.size(); i++ )
        {
            pb.add_r1cs_constraint(
                r1cs_constraint<FieldT>(
                    items[i],
                    toggles[i],
                    toggles[i] * our_item_lc_val),
                FMT(this->annotation_prefix, ".were_selected"));
        }
    }

    void generate_r1cs_witness()
    {
        for( size_t i = 0; i < toggles.size(); i++ )
        {
            if( pb.val(items[i]) == pb.val(our_item) )
            {
                pb.val(toggles[i]) = FieldT::one();
                break;
            }
        }

        // create toggle sum
        toggles_sum[0] = toggles[0];
        for( size_t i = 1; i < toggles.size(); i++ )
        {
            pb.val(toggles_sum[i]) = pb.val(toggles_sum[i-1]) + pb.val(toggles[i]);
        }
    }
};

// ethsnarks
}
