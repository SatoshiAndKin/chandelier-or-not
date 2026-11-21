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

Use Foundry v1.10.0 to regenerate the snapshots. The default profile builds and tests with the pinned Solar v0.3.0 compiler and Osaka EVM target. The fixed-fork snapshot is a test baseline, not a production gas estimate.

Set `BASE_RPC_URL` to a Base RPC with historical state and `NN_VERIFICATIONS_ADDRESS` to the address in the [CI workflow](.github/workflows/test.yml). The tests fork at a fixed block.

```shell
$ forge snapshot
$ forge snapshot --check
```

### Anvil

```shell
$ anvil
```

### Deploy

Use the development steps for local Solar/Osaka experiments. [Solar code generation is experimental](https://github.com/paradigmxyz/solar/releases/tag/v0.3.0); do not deploy its bytecode to production.

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

Start Anvil with the Osaka hardfork:

```shell
anvil --hardfork osaka
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
./script/post-and-vote-to-chandelier-or-not.sh "~/Desktop/chandeliers/IMG_7856.png" "true" --rpc-url http://127.0.0.1:8545
```

### Production Deploy Steps

Use the `production` profile to retain solc 0.8.28, Cancun, and the existing via-IR compilation.

```shell
source .env
```

```shell
FOUNDRY_PROFILE=production forge script script/Deploy.s.sol:DeployScript \
    --broadcast \
    --verify \
    --rpc-url "$BASE_RPC_URL"
```

Create a post and vote for it:

```shell
./script/post-and-vote-to-chandelier-or-not.sh "$HOME/Desktop/chandeliers/IMG_7856.png" "true" --rpc-url "$BASE_RPC_URL"
```
