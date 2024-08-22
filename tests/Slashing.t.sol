// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {OwnableUpgradeable} from 'openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol';

import {StakeToken} from 'src/contracts/StakeToken.sol';
import {IERC4626StakeToken} from 'src/contracts/interfaces/IERC4626StakeToken.sol';

import {StakeTestBase} from './utils/StakeTestBase.sol';

contract SlashingTests is StakeTestBase {
  function test_slashNotByAdmin(address anyone) external {
    vm.assume(anyone != admin);

    vm.startPrank(anyone);

    vm.expectRevert(
      abi.encodeWithSelector(
        OwnableUpgradeable.OwnableUnauthorizedAccount.selector,
        address(anyone)
      )
    );
    stakeToken.slash(user, type(uint256).max);
  }

  function test_slash_shouldRevertWithAmountZero() public {
    vm.startPrank(admin);

    vm.expectRevert(IERC4626StakeToken.ZeroAmountSlashing.selector);
    stakeToken.slash(user, 0);
  }

  function test_slash_shouldRevertWithFundsLteMinimum(uint256 amount) public {
    vm.assume(amount > 0 && amount <= stakeToken.MIN_ASSETS_REMAINING());

    _deposit(amount, user, user);

    vm.startPrank(admin);

    vm.expectRevert(IERC4626StakeToken.ZeroFundsAvailable.selector);
    stakeToken.slash(someone, type(uint256).max);
  }

  function test_slash(uint192 amountToStake, uint192 amountToSlash) public {
    vm.assume(amountToStake > stakeToken.MIN_ASSETS_REMAINING());
    vm.assume(amountToSlash > 0 && amountToSlash < amountToStake);
    vm.assume(amountToStake - stakeToken.MIN_ASSETS_REMAINING() >= amountToSlash);

    _deposit(amountToStake, user, user);

    vm.startPrank(admin);

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

    vm.startPrank(admin);

    stakeToken.slash(someone, amountToSlash);

    vm.stopPrank();

    _deposit(amountToStake, user, user);

    assertEq(underlying.balanceOf(someone), amountToSlash);
    assertEq(underlying.balanceOf(address(stakeToken)), 2 * uint256(amountToStake) - amountToSlash);

    assertEq(
      stakeToken.convertToAssets(stakeToken.balanceOf(user)),
      2 * uint256(amountToStake) - amountToSlash
    );
  }
}
