# StakeToken - Vault

New version of the Aave Safety Module stk tokens. This is an updated version intended for the Umbrella project.

## About

The `StakeToken` contains an EIP-4626 generic token vault for all non-rebase tokens (especially targeting `static-a-tokens`).

## Features

- **Full [EIP-4626](https://eips.ethereum.org/EIPS/eip-4626) compatibility.**
- Withdrawal of funds from the storage can be carried out only after activation of cooldown after a certain time.
- The `StakeToken` is designed to cover small `Bad Debt`'s in a semi-automatic mode, but can withdraw almost all funds up to the `getMaxSlashableAssets()` amount in emergencies.
- Providing liquidity in the `StakeToken` includes the risk of slashing and is therefore paid for with additional rewards through `REWARDS_CONTROLLER`.
- **Permit-transactions support.** To enable interfaces to offer gas-less transactions to deposit with a permit.
- **Upgradable by the Aave governance.** Similar to other contracts of the Aave ecosystem, the Level 1 executor (short executor) will be able to add new features to the deployed instances of the `stakeTokens`.

See [`IERC4626StakeToken.sol`](src/contracts/interfaces/IERC4626StakeToken.sol) for detailed method documentation.

## Deployed Addresses

An up-to-date address can be fetched from the respective [address-book pool library](https://github.com/bgd-labs/aave-address-book/blob/main/src/AaveV3Ethereum.sol).

## Limitations

The `StakeToken` is not natively integrated into the aave protocol and therefore cannot use multiple sources of additional incentives. Additional incentives included in the `static-a-tokens` are disabled when using the `StakeTokens`.

Since the `StakeToken` implies a decrease in `totalAssets()` over time (loss of funds), irreversible losses associated with the accuracy of calculations could occur over time.

Losses do not exceed 1 wei if calculated relative to assets, but they can be more significant when using functions related to calculations through shares (due to OZ roundings). It is recommended to manually check and find more profitable ways to deposit/withdraw liquidity. However, in most cases, the difference should not exceed any significant amount.

### Inheritance

The `StakeToken` is based on [`open-zeppelin-upgradeable`](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable) contracts.

The `StakeToken` is separated into 2 different contracts, where `ERC4626StakeTokenUpgradeable` inherits `ERC4626Upgradeable`.

- `ERC4626StakeTokenUpgradeable` is an abstract contract implementing the [EIP-4626](https://eips.ethereum.org/EIPS/eip-4626) methods for an underlying asset. It provides basic functionality for the `StakeToken` without any access control or pausability.
- `StataTokenV2` is the main contract stitching things together, while adding `Pausable`, `Rescuable`, `Permit`, and the actual initialization.

#### depositWithPermit

[`ERC20PermitUpgradeable`](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/9a47a37c4b8ce2ac465e8656f31d32ac6fe26eaa/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol) has been added to the `StakeToken`, which added the ability to make a deposit using a valid signature and 1 tx via `permit()`.

#### Rescuable

[`Rescuable`](https://github.com/bgd-labs/solidity-utils/blob/main/src/contracts/utils/Rescuable.sol) has been applied to
the `StakeToken` which will allow the `owner()` of the corresponding `StakeToken` to rescue tokens on the contract.

#### Pausable

The `StakeToken` implements the [`PausableUpgradeable`](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/9a47a37c4b8ce2ac465e8656f31d32ac6fe26eaa/contracts/utils/PausableUpgradeable.sol) allowing `owner()` to pause the vault in case of an emergency.
As long as the vault is paused, any non-view actions (deposit/redeem/slash) are impossible.

## Dependencies

- Foundry, [how-to install](https://book.getfoundry.sh/getting-started/installation) (we recommend also update to the last version with `foundryup`)
- Lcov
  - Optional, only needed for coverage testing
  - For Ubuntu, you can install via `apt install lcov`
  - For Mac, you can install via `brew install lcov`

### Setup

```sh
cp .env.example .env

forge install

# optional, to install prettier
bun install
```

### Tests

- To run the full test suite: `make test`
- To re-generate the coverage report: `make coverage`
