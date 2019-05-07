module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 7545,
      network_id: "*", // Match any network id
      gas: 6500000 // Gas limit
    },
    localrinkeby: {
      // Rinkeby via a local geth node
      host: "localhost",
      port: 8545,
      network_id: 4,
      gas: 3000000, // Gas limit
      gasPrice: 32000000000, // 32 GWei
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
