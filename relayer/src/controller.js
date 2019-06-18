const ethers = require('ethers');
const ajv = require('ajv')();
const schema = require('./schema.json');

class Controller {
    constructor(privateKey, providerUrl, contractAddress) {
        const provider = new ethers.providers.JsonRpcProvider(providerUrl);
        this.signer = new ethers.Wallet(privateKey, provider);
        this.contractAddress = contractAddress;
    }

    async sendTransaction(params) {
        const valid = ajv.validate(schema, params);
        if (valid !== true) {
            const message = ajv.errors.map(err => `${err.dataPath} ${err.message}.`).join(' ');
            throw new Error(`Input paramaters validation issue: ${message}`);
        }

        if (params.to.toLowerCase() !== this.contractAddress.toLowerCase()) {
            throw new Error('Invalid contract address');
        }

        const tx = {
            to: params.to,
            data: params.data
        };

        if (params.gas) {
            tx.gasLimit = ethers.utils.hexlify(params.gas);
        }

        const txResult = await this.signer.sendTransaction(tx);
        return txResult.hash;
    }
}

module.exports = Controller;
