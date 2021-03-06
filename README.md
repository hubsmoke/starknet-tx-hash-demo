This repo demonstrates an important StarkNet concept with regard to transaction hashes and how they are processed by StarkNet Alpha v4. This may be helpful to developers who are used to working with the EVM.

The `CantIncrementTwiceCounter.cairo` program exposes a write function `incrementCounter` that takes no parameters and increases the state counter by 1 upon each invocation

[When receiving a contract function call, StarkNet Alpha v4 calculates the transaction hash based on the deployed contract address, the called function, the passed function parameters, and the chain id.](https://starknet.io/transaction-structure-and-hash/) `incrementCounter` has no parameters and so the transaction hash will always be the same when `incrementCounter` is directly invoked for this deployed contract.

The counter starts at 0. No matter how many times `incrementCounter` is directly invoked, counter will always be a maximum of 1. However, the cairo code seems to imply the counter should increase upon each invocation.

So, why is the counter not updated to 2 after the second invocation? Each time the `incrementCounter` function is directly invoked, the same exact transaction hash will be submitted to the network, resulting in the invocation being ignored by StarkNet Alpha v4, and thus no further computation or state updates will be made.

# How do I make this work in practice, with a counter that increments as expected?

The current best practice to update states is via the Account abstraction. This is a contract, referred to as an Account, which stores a public key and nonce internally. The public key is used to verify signed transactions. The nonce is used to prevent replay attacks and update transaction hashes, it is incremented after every authenticated external contract call.

The idea here is that calls to Account contract can be authenticated by signature verification based on the Account's assigned public key, therefore granting the private key holder custody of the Account. All external contract calls are effectively proxied through the Account contract's "execute" function *which takes a nonce as a parameter, therefore modifying the transaction hash*. This new transaction hash enables StarkNet Alpha v4 to continue processing the transaction, allowing computation to continue and states to be updated. The end result is similar to the experience of making authenticated contract calls using the EVM.

There are currently two major implementations:

- https://github.com/argentlabs/argent-contracts-starknet/blob/main/contracts/ArgentAccount.cairo
- https://github.com/OpenZeppelin/cairo-contracts/blob/main/contracts/Account.cairo

The minimum/naive implementation to achieve a counter that increments above 1 without using the full authenticated Account abstraction would be to add one or more parameters to the `incrementCounter` function and invoke it with different parameters each time, however that is neither as practical nor as useful as the Account abstraction.

Deploying your own Account and updating the state of the counter to > 1 is currently left as an exercise to the reader. The following repo provides a working example for a similar counter contract using the ArgentX StarkNet wallet as the interface to the Account abstraction: https://github.com/fracek/starknet-react-example

# Further reading
- https://hackmd.io/@RoboTeddy/BJZFu56wF
- https://www.cairo-lang.org/docs/hello_starknet/user_auth.html#what-if-we-have-an-invalid-signature
- https://perama-v.github.io/cairo/account-abstraction/
- https://github.com/gakonst/awesome-starknet


# Running Demo

Set up Environment
------------------

https://www.cairo-lang.org/docs/quickstart.html

Deploy contract
------------------
`starknet deploy --contract CantIncrementTwiceCounter_compiled.json --gateway_url https://alpha4.starknet.io/gateway/`

```
Deploy transaction was sent.
Contract address: 0x03f7fc65c3151b30addb82bc81180098e65e4a99a566def4d8ed894d028ce402
Transaction hash: 0x81d6b588502d0f51305bc8ec8bc3a58504f3700d32532181845248db880c04
```

Get counter
------------------
`starknet call --address 0x03f7fc65c3151b30addb82bc81180098e65e4a99a566def4d8ed894d028ce402 --abi CantIncrementTwiceCounter_abi.json --function counter --network alpha-goerli`
```
0
```

Increment counter (1st time)
------------------
`starknet invoke --address 0x03f7fc65c3151b30addb82bc81180098e65e4a99a566def4d8ed894d028ce402 --abi CantIncrementTwiceCounter_abi.json --function incrementCounter --network alpha-goerli`
```
Invoke transaction was sent.
Contract address: 0x03f7fc65c3151b30addb82bc81180098e65e4a99a566def4d8ed894d028ce402
Transaction hash: 0x4db992c1109bf426675eb859da9f98e782934b95799bc4e10a5626720a3d06d
```

Wait for transaction to finish
------------------
`starknet get_transaction_receipt --hash 0x4db992c1109bf426675eb859da9f98e782934b95799bc4e10a5626720a3d06d --gateway_url https://alpha4.starknet.io/gateway/ --network alpha-goerli`
```
{
    "block_hash": "0x5aff1cc2231d35aeb8f454a29e0f57562f6406b83d5d49829910445e8e8b09e",
    "block_number": 27550,
    "execution_resources": {
        "builtin_instance_counter": {
            "bitwise_builtin": 0,
            "ec_op_builtin": 0,
            "ecdsa_builtin": 0,
            "output_builtin": 0,
            "pedersen_builtin": 0,
            "range_check_builtin": 0
        },
        "n_memory_holes": 0,
        "n_steps": 74
    },
    "l2_to_l1_messages": [],
    "status": "ACCEPTED_ON_L2",
    "transaction_hash": "0x4db992c1109bf426675eb859da9f98e782934b95799bc4e10a5626720a3d06d",
    "transaction_index": 3
}
```

Get counter (2nd time)
------------------
`starknet call --address 0x03f7fc65c3151b30addb82bc81180098e65e4a99a566def4d8ed894d028ce402 --abi CantIncrementTwiceCounter_abi.json --function counter --network alpha-goerli`
```
1
```

Increment counter (2nd time)
------------------
`starknet invoke --address 0x03f7fc65c3151b30addb82bc81180098e65e4a99a566def4d8ed894d028ce402 --abi CantIncrementTwiceCounter_abi.json --function incrementCounter --network alpha-goerli`
```
# NOTE: same exact transaction hash!
Invoke transaction was sent.
Contract address: 0x03f7fc65c3151b30addb82bc81180098e65e4a99a566def4d8ed894d028ce402
Transaction hash: 0x4db992c1109bf426675eb859da9f98e782934b95799bc4e10a5626720a3d06d
```

Get counter (3rd time)
------------------
`starknet call --address 0x03f7fc65c3151b30addb82bc81180098e65e4a99a566def4d8ed894d028ce402 --abi CantIncrementTwiceCounter_abi.json --function counter --network alpha-goerli`
```
# still returns 1, no state update made
# second write invocation was ignored
1
```
