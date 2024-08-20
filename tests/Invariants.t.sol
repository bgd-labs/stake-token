// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {StakeTestBase} from './utils/StakeTestBase.sol';

contract InvariantTest is StakeTestBase {
  // we will use 192 instead of uint256 or 224, cause it will lead to overflow in this fuzzing test, due to mulDiv with new ExchangeRate
  /// forge-config: default.fuzz.runs = 100000
  function test_exchangeRateAfterSlashingAlwaysIncreasing(
    uint192 amountToDeposit,
    uint192 amountToSlash
  ) external {
    vm.assume(amountToDeposit > stakeToken.MIN_ASSETS_REMAINING());
    vm.assume(
      amountToSlash > 0 && amountToDeposit > amountToSlash + stakeToken.MIN_ASSETS_REMAINING()
    );

    _deposit(amountToDeposit, user, user);

    uint256 initialExchangeRate = stakeToken.getExchangeRate();

    vm.startPrank(slashingAdmin);

    stakeToken.slash(someone, amountToSlash);

    uint256 exchangeRateAfterSlash = stakeToken.getExchangeRate();

    assertLe(initialExchangeRate, exchangeRateAfterSlash);
  }
}
