// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from 'src/contracts/interfaces/IPoolAddressesProvider.sol';
import {IRewardsController} from 'src/contracts/interfaces/IRewardsController.sol';

import {StakeToken} from 'src/contracts/StakeToken.sol';
import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';

contract MockToken is StakeToken {
  using SafeCast for uint256;

  constructor(
    IRewardsController rewardsController,
    IPoolAddressesProvider provider
  ) StakeToken(rewardsController, provider) {}

  function setExchangeRate(uint256 newExchangeRate) public {
    _updateExchangeRate(newExchangeRate.toUint192());
  }
}
