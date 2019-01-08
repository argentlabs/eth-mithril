include_directories(.)

add_library(ethsnarks_jubjub STATIC
  fixed_base_mul.cpp
  conditional_point.cpp
  scalarmult.cpp
  adder.cpp
  doubler.cpp
  isoncurve.cpp
  commitment.cpp
  notloworder.cpp
  validator.cpp
  point.cpp
  pedersen_hash.cpp
  fixed_base_mul_zcash.cpp
  montgomery.cpp
  eddsa.cpp
)

target_link_libraries(ethsnarks_jubjub ethsnarks_gadgets)