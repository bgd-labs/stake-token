// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

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

    vm.startPrank(admin);

    stakeToken.slash(someone, amountToSlash);

    uint256 newExchangeRate = stakeToken.previewDeposit(1);

    assertLe(defaultExchangeRate, newExchangeRate);
  }

  function test_dataShouldBeNotUpdatedDuringDeposit() external {
    _deposit(1 ether, user, user);

    assertEq(mockRewardsController.lastTotalAssets(), 0);
    assertEq(mockRewardsController.lastTotalSupply(), 0);

    uint256 totalAssets = stakeToken.totalAssets();
    uint256 totalSupply = stakeToken.totalSupply();

    assertNotEq(totalAssets, 0);
    assertNotEq(totalSupply, 0);

    _deposit(1 ether, user, user);

    assertEq(mockRewardsController.lastTotalAssets(), totalAssets);
    assertEq(mockRewardsController.lastTotalSupply(), totalSupply);

    assertNotEq(totalAssets, stakeToken.totalAssets());
    assertNotEq(totalSupply, stakeToken.totalSupply());
  }

  function test_dataShouldBeNotUpdatedDuringWithdraw() external {
    _deposit(1 ether, user, user);

    uint256 newtotalAssets = stakeToken.totalAssets();
    uint256 newtotalSupply = stakeToken.totalSupply();

    vm.startPrank(user);
    stakeToken.cooldown();

    skip(stakeToken.getCooldown());

    stakeToken.withdraw(0.5 ether, user, user);

    assertEq(mockRewardsController.lastTotalAssets(), newtotalAssets);
    assertEq(mockRewardsController.lastTotalSupply(), newtotalSupply);

    assertNotEq(newtotalAssets, stakeToken.totalAssets());
    assertNotEq(newtotalSupply, stakeToken.totalSupply());
  }
}
