require("dotenv").config();
const HDWalletProvider = require("truffle-hdwallet-provider");

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*", // Match any network id
      gas: 6.5e6 // Gas limit
    },
    localrinkeby: {
      // Rinkeby via a local geth node
      host: "localhost",
      port: 8545,
      network_id: 4,
      gas: 2.5e6, // Gas limit
      gasPrice: 32e9, // 32 GWei
      skipDryRun: true
    },
    ropsten: {
      provider: () =>
        new HDWalletProvider(
          process.env.ROPSTEN_DEPLOYER_SECRET_KEY,
          process.env.ROPSTEN_URL
        ),
      network_id: 3,
      gas: 2.5e6,
      gasPrice: 32e9, // 32 GWei
      skipDryRun: true
    },
    mainnet: {
      provider: () =>
        new HDWalletProvider(
          process.env.MAINNET_DEPLOYER_SECRET_KEY,
          process.env.MAINNET_URL
        ),
      network_id: 1,
      gas: 2.5e6,
      gasPrice: 3e9,
      timeoutBlocks: 150,
      skipDryRun: true
    }
  },
  solc: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  }
};
