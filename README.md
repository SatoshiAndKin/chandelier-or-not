## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

### Development Deploy Steps

First, create an `.env`

```shell
source .env
```

Start anvil:

```shell
anvil
```

Deploy to anvil:

```shell
forge script script/Deploy.s.sol:DeployScript \
    --broadcast \
    --rpc-url http://127.0.0.1:8545
```

Then, add the address to your `~/.env`

Create a post:

```shell
./script/post-to-chandelier-or-not.sh "~/Desktop/chandeliers/IMG_7856.png" --rpc-url http://127.0.0.1:8545
```

### Production Deploy Steps

```shell
source .env
```

```shell
forge script script/Deploy.s.sol:DeployScript \
    --broadcast \
    --rpc-url "$BASE_RPC_URL"
```

Create a post and vote for it:

```shell
./script/post-to-chandelier-or-not.sh "$HOME/Desktop/chandeliers/IMG_7856.png" "true" --rpc-url "$BASE_RPC_URL"
```
