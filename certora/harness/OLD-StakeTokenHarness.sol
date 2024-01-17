// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {StakeToken} from '../../src/contracts/StakeToken.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';

contract StakeTokenHarness is StakeToken {
    constructor(
                string memory name,
                IERC20 stakedToken,
                IERC20 rewardToken,
                uint256 unstakeWindow,
                address rewardsVault,
                address emissionManager,
                uint128 distributionDuration
    ) StakeToken (name, stakedToken, rewardToken, unstakeWindow,
                  rewardsVault, emissionManager, distributionDuration) {}

}

