// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {StakeTestBase} from './utils/StakeTestBase.sol';

contract InvariantTest is StakeTestBase {
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

    uint256 defaultExchangeRate = stakeToken.previewDeposit(1);

    vm.startPrank(slashingAdmin);

    stakeToken.slash(someone, amountToSlash);

    uint256 newExchangeRate = stakeToken.previewDeposit(1);

    assertLe(defaultExchangeRate, newExchangeRate);
  }
}
