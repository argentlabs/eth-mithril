const Verifier = artifacts.require("Verifier.sol");
const Mixer = artifacts.require("Mixer.sol");
const { vk_to_flat } = require("../utils");

async function doDeploy(deployer, network) {
  await deployer.deploy(Verifier);
  await deployer.link(Verifier, Mixer);

  var vk = require("../../.keys/mixer.vk.json");
  let [vk_flat, vk_flat_IC] = vk_to_flat(vk);
  await deployer.deploy(Mixer, vk_flat, vk_flat_IC);
}

module.exports = function(deployer, network) {
  deployer.then(async () => {
    await doDeploy(deployer, network);
  });
};
