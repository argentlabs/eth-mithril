node_modules:
	npm install

.PHONY: test
test: node_modules
	npm run test

.PHONY: deploy
deploy: node_modules
	truffle migrate