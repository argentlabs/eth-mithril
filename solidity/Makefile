TRUFFLE = ./node_modules/.bin/truffle

all: test

node_modules:
	npm install

testrpc:
	npm run testrpc

.PHONY: test
test: node_modules
	npm run test

.PHONY: deploy
deploy: node_modules
	$(TRUFFLE) migrate

deploy-rinkeby: node_modules
	$(TRUFFLE) migrate --network localrinkeby

deploy-ropsten: node_modules
	$(TRUFFLE) migrate --network ropsten

deploy-mainnet: node_modules
	$(TRUFFLE) migrate --network mainnet
