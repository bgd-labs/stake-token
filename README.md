# Stake token

New version of the Aave Safety Module stk tokens.

## Summary of Changes

The `StakeToken` is a token deployed on Ethereum, with the main utility of participating in the Aave safety module.

There are currently two proxy contracts which utilize a `StakeToken`:

- [stkAAVE](https://etherscan.io/token/0x4da27a545c0c5b758a6ba100e3a049001de870f5) with the [StakedAaveV3 implementation](https://etherscan.io/address/0xaa9faa887bce5182c39f68ac46c43f36723c395b#code)
- [stkABPT](https://etherscan.io/address/0xa1116930326D21fB917d5A27F1E9943A9595fb47#code) with the [StakedTokenV3 implementation](https://etherscan.io/address/0x9921c8cea5815364d0f8350e6cbe9042a92448c9#code)

The implementation can be found [here](https://github.com/bgd-labs/aave-stk-gov-v3)
Together with all the standard ERC20 functionalities, the current implementation includes extra logic for:

- entering and exiting the safety module
- management & accounting for safety module rewards
- management & accounting of voting and proposition power
- slashing mechanics for slashing in the case of shortfall events

The new iteration of the generic `StakeToken` is intended for new Deployments **only**.
While it does not alter any core mechanics, the new iteration cleans up numerous historical artifacts.

The main goals here are:

- simpler inheritance chain
- cleaner storage layout
- updated/modernized libraries

## Development

This project uses [Foundry](https://getfoundry.sh). See the [book](https://book.getfoundry.sh/getting-started/installation.html) for detailed instructions on how to install and use Foundry.
The template ships with sensible default so you can use default `foundry` commands without resorting to `MakeFile`.

### Setup

```sh
cp .env.example .env
forge install
```

### Test

```sh
forge test
```

## Advanced features

### Diffing

For contracts upgrading implementations it's quite important to diff the implementation code to spot potential issues and ensure only the intended changes are included.
Therefore the `Makefile` includes some commands to streamline the diffing process.

#### Download

You can `download` the current contract code of a deployed contract via `make download chain=polygon address=0x00`. This will download the contract source for specified address to `src/etherscan/chain_address`. This command works for all chains with a etherscan compatible block explorer.

#### Git diff

You can `git-diff` a downloaded contract against your src via `make git-diff before=./etherscan/chain_address after=./src out=filename`. This command will diff the two folders via git patience algorithm and write the output to `diffs/filename.md`.

**Caveat**: If the onchain implementation was verified using flatten, for generating the diff you need to flatten the new contract via `forge flatten` and supply the flattened file instead fo the whole `./src` folder.
