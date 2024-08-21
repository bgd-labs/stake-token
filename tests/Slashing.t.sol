// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IStakeToken} from 'src/contracts/interfaces/IStakeToken.sol';

import {StakeToken} from 'src/contracts/StakeToken.sol';
import {StakeTestBase} from './utils/StakeTestBase.sol';

contract SlashingTests is StakeTestBase {
  function test_slashWithWrongCaller() external {
    vm.startPrank(user);

    vm.expectRevert(IStakeToken.CallerIsNotSlashingAdmin.selector);
    stakeToken.slash(user, type(uint256).max);
  }

  function test_slash_shouldRevertWithAmountZero() public {
    vm.startPrank(slashingAdmin);

    vm.expectRevert(IStakeToken.ZeroAmountSlashing.selector);
    stakeToken.slash(user, 0);
  }

  function test_slash_shouldRevertWithFundsLteMinimum(uint256 amount) public {
    vm.assume(amount > 0 && amount <= stakeToken.MIN_ASSETS_REMAINING());

    _deposit(amount, user, user);

    vm.startPrank(slashingAdmin);

    vm.expectRevert(IStakeToken.ZeroFundsAvailable.selector);
    stakeToken.slash(someone, type(uint256).max);
  }

  function test_slash(uint192 amountToStake, uint192 amountToSlash) public {
    vm.assume(amountToStake > stakeToken.MIN_ASSETS_REMAINING());
    vm.assume(amountToSlash > 0 && amountToSlash < amountToStake);
    vm.assume(amountToStake - stakeToken.MIN_ASSETS_REMAINING() >= amountToSlash);

    _deposit(amountToStake, user, user);

    vm.startPrank(slashingAdmin);

    stakeToken.slash(someone, amountToSlash);

    vm.stopPrank();

    assertEq(underlying.balanceOf(someone), amountToSlash);
    assertEq(underlying.balanceOf(address(stakeToken)), amountToStake - amountToSlash);

    assertEq(stakeToken.convertToAssets(stakeToken.balanceOf(user)), amountToStake - amountToSlash);
  }

  function test_stakeAfterSlash(uint192 amountToStake, uint192 amountToSlash) public {
    vm.assume(amountToStake > stakeToken.MIN_ASSETS_REMAINING());
    vm.assume(amountToSlash > 0 && amountToSlash < amountToStake);
    vm.assume(amountToStake - amountToSlash >= stakeToken.MIN_ASSETS_REMAINING());
    vm.assume(uint256(amountToStake) * 2 - amountToSlash < type(uint192).max);

    _deposit(amountToStake, user, user);

    vm.startPrank(slashingAdmin);

    stakeToken.slash(someone, amountToSlash);

    vm.stopPrank();

    _deposit(amountToStake, user, user);

    assertEq(underlying.balanceOf(someone), amountToSlash);
    assertEq(underlying.balanceOf(address(stakeToken)), 2 * amountToStake - amountToSlash);

    assertEq(
      stakeToken.convertToAssets(stakeToken.balanceOf(user)),
      2 * amountToStake - amountToSlash
    );
  }
}
