module.exports = {
	networks: {
		coverage: {
			host: "localhost",
			port: 8555,
			network_id: "*",
			gas: 0xFFFFFFFF,
			gasPrice: 0x1
		},
		testrpc: {
			host: "localhost",
			port: 8545,
			network_id: "*"
		}
	},
	solc: {
		optimizer: {
			enabled: true,
			runs: 200
		}
	}
}