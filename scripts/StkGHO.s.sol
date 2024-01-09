// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StakeToken} from '../src/contracts/StakeToken.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {EthereumScript} from 'aave-helpers/ScriptUtils.sol';
import {TransparentUpgradeableProxy} from 'aave-token-v3/../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';

/**
 * @dev Deploy Ethereum
 * deploy-command: make deploy-ledger contract=scripts/StkGHO.s.sol:DeployStkGHO chain=mainnet
 * verify-command: npx catapulta-verify -b broadcast/StkGHO.s.sol/1/run-latest.json
 * example script according to https://governance.aave.com/t/arfc-upgrade-safety-module-with-stkgho/15635#motivation-2
 * - 100% slashing is technically not possible without breaking the stk exchangeRate, therfore maxSlashing is set to 99%
 * - 10 days cooldown seems wrong, so it's set to 20 days instead
 */
contract DeployStkGHO is EthereumScript {
  function run() external broadcast {
    StakeToken stkTokenImpl = new StakeToken(
      'stkGHO',
      IERC20(AaveV3EthereumAssets.GHO_UNDERLYING),
      IERC20(AaveV3EthereumAssets.AAVE_UNDERLYING),
      2 days,
      MiscEthereum.ECOSYSTEM_RESERVE,
      GovernanceV3Ethereum.EXECUTOR_LVL_1
    );
    new TransparentUpgradeableProxy(
      address(stkTokenImpl),
      address(MiscEthereum.PROXY_ADMIN),
      abi.encodeWithSelector(
        StakeToken.initialize.selector,
        'Staked GHO',
        'stkGHO',
        GovernanceV3Ethereum.EXECUTOR_LVL_1,
        GovernanceV3Ethereum.EXECUTOR_LVL_1,
        GovernanceV3Ethereum.EXECUTOR_LVL_1,
        9900, // 99 %
        20 days
      )
    );
  }
}