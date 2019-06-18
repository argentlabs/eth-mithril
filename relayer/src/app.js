require('dotenv').config();

const jayson = require('jayson');
const Controller = require('./controller');

const controller = new Controller(process.env.PRIVATE_KEY, process.env.PROVIDER_URL, process.env.MIXER_ADDRESS);

const methods = {
    eth_sendTransaction: async (args, callback) => {
        try {
            const params = args[0];
            const txHash = await controller.sendTransaction(params);
            callback(null, txHash);
        } catch (error) {
            return callback({ code: -1, message: error.message });
        }
    }
}

const port = process.env.PORT || 8080;
const server = jayson.server(methods);
server.http().listen(port);
