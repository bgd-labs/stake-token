// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IRewardsController} from '../interfaces/IRewardsController.sol';
import {StakeToken} from '../StakeToken.sol';
import {IStaticATokenLM} from '../interfaces/IStaticATokenLM.sol';

/**
 * A customized version of StakeToken to acoomondate for 4626 stata methods
 */
contract StataGateway is StakeToken {
  constructor(IRewardsController rewardsController) StakeToken(rewardsController) {}

  // TODO: add methods for direct deposit / withdrawal from aToken/underlying

  /**
   * @notice Allows the DAO to claim LM rewards that would otherwise be stuck on the stk.
   */
  function claimStataRewards(address receiver) external onlyOwner {
    IStaticATokenLM(asset()).claimRewards(receiver, IStaticATokenLM(asset()).rewardTokens());
  }
}
