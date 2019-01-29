module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*", // Match any network id
      gas: 6500000 // Gas limit
    }
  },
  solc: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  }
};
