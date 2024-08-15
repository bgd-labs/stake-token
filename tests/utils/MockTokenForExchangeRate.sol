// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {StakeToken} from '../../src/contracts/StakeToken.sol';

import {IPoolAddressesProvider} from 'aave-v3-origin/core/contracts/interfaces/IPoolAddressesProvider.sol';
import {IRewardsController} from '../../src/contracts/interfaces/IRewardsController.sol';

contract MockToken is StakeToken {
  constructor(
    IRewardsController rewardsController,
    IPoolAddressesProvider provider
  ) StakeToken(rewardsController, provider) {}

  function setExchangeRate(uint256 newExchangeRate) public {
    _updateExchangeRate(newExchangeRate);
  }
}
