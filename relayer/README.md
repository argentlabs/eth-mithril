# Hopper Relayer

Relayers are used to post transactions to the blockchain so that the recipient of a private transfer can withdraw a private note from the mixer without needing any prior ether.

⚠️ Please note that this relayer is in alpha state and should be used with caution. It is not production-ready and may contain flaws that result in the loss of your funds. ⚠️

# Technical details

This relayer is a JSON RPC server implementing a single method: **eth_sendTransaction**.

## eth_sendTransaction

Sign and send the relayed transaction.

#### Parameters

* `to`: `(ETHEREUM ADDRESS)` The address the transaction is directed to (it should be the mixer contract address in this case).
* `data`: `(HEX)` The hash of the invoked method signature and encoded parameters
* `gas` (optional): `(HEX or NUMBER)` Gas limit provided for the transaction execution.

#### Returns

It returns the transaction hash.

# TO DO

* Better gas price management (using third party api like Eth Gas Station)

* If transactions frequency increases, transaction nonce unicity might become an issue. It could be good the implement a strategy where the nonce is stored and incremented locally instead of calling getTransactionCount.