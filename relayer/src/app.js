require('dotenv').config();

const jayson = require('jayson');
const express = require('express');
const jsonParser = require('body-parser').json;
const rateLimit = require("express-rate-limit");

const Controller = require('./controller');

const controller = new Controller(process.env.PRIVATE_KEY, process.env.PROVIDER_URL, process.env.MIXER_ADDRESS);

const app = express();
const port = process.env.PORT || 8080;

app.set('trust proxy', 1);
app.use(rateLimit({
    windowMs: process.env.RATELIMIT_WINDOW || 15 * 60 * 1000,
    max: process.env.RATELIMIT_MAX || 3,
    skip: (req) => {
        if (req.path === '/health') return true;
        return false;
    }
}));

const server = jayson.server({
    eth_sendTransaction: async (args, callback) => {
        try {
            const params = args[0];
            const txHash = await controller.sendTransaction(params);
            callback(null, txHash);
        } catch (error) {
            return callback({ code: -1, message: error.message });
        }
    }
});

app.get('/health', (req, res) => {
    res.json({ status: 'OK' })
});

app.use(jsonParser());
app.use(server.middleware());

app.listen(port, () => console.log(`App listening on port ${port}!`));
