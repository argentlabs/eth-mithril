const Mixer = artifacts.require("Mixer.sol");
const { vk_to_flat } = require("../utils");

async function doDeploy(deployer) {
  var vk = require("../../.keys/mixer.vk.json");
  let [vk_flat, vk_flat_IC] = vk_to_flat(vk);

  await deployer.deploy(Mixer, vk_flat, vk_flat_IC);
}

module.exports = function(deployer) {
  deployer.then(async () => {
    await doDeploy(deployer);
  });
};
