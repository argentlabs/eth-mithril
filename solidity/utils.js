list_flatten = l => {
  return [].concat.apply([], l);
};

module.exports = {
  vk_to_flat: vk => {
    return [
      list_flatten([
        vk.alpha[0],
        vk.alpha[1],
        list_flatten(vk.beta),
        list_flatten(vk.gamma),
        list_flatten(vk.delta)
      ]),
      list_flatten(vk.gammaABC)
    ];
  },

  proof_to_flat: proof => {
    return list_flatten([proof.A, list_flatten(proof.B), proof.C]);
  }
};
