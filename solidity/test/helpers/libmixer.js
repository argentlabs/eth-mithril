const ffi = require("ffi");
const ref = require("ref");
const ArrayType = require("ref-array");
const StringArray = ArrayType(ref.types.CString);

module.exports = ffi.Library("../.build/libmixer", {
  // Retrieve depth of tree
  mixer_tree_depth: ["size_t", []],

  // Create a proof for the parameters, using JSON arguments
  mixer_prove_json: [
    "string",
    [
      "string", // pk_file
      "string"  // in_json
    ]
  ],

  // Create a proof for the parameters
  mixer_prove: [
    "string",
    [
      "string", // pk_file
      "string", // in_root
      "string", // in_wallet_address
      "string", // in_nullifier
      "string", // in_nullifier_secret
      "string", // in_address
      StringArray // in_path
    ]
  ],

  // Verify a proof
  mixer_verify: [
    "bool",
    [
      "string", // vk_json
      "string" // proof_json
    ]
  ]
});
