// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {IStakedTokenV3} from './IStakedTokenV3.sol';
import {IGhoVariableDebtTokenTransferHook} from './IGhoVariableDebtTokenTransferHook.sol';

interface IStakedAaveV3 is IStakedTokenV3 {
  /**
   * @dev Claims an `amount` of `REWARD_TOKEN` and stakes.
   * @param to Address to stake to
   * @param amount Amount to claim
   */
  function claimRewardsAndStake(
    address to,
    uint256 amount
  ) external returns (uint256);

  /**
   * @dev Claims an `amount` of `REWARD_TOKEN` and stakes. Only the claim helper contract is allowed to call this function
   * @param from The address of the from from which to claim
   * @param to Address to stake to
   * @param amount Amount to claim
   */
  function claimRewardsAndStakeOnBehalf(
    address from,
    address to,
    uint256 amount
  ) external returns (uint256);
}
