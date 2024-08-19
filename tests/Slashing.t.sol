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

  function test_slash() public {
    _deposit(100 ether, user, user);

    vm.startPrank(slashingAdmin);

    stakeToken.slash(someone, 20 ether);

    vm.stopPrank();

    assertEq(underlying.balanceOf(someone), 20 ether);
    assertEq(underlying.balanceOf(address(stakeToken)), 80 ether);

    assertEq(stakeToken.getExchangeRate(), 1.25 ether);
    assertEq(stakeToken.convertToAssets(stakeToken.balanceOf(user)), 80 ether);
  }

  function test_stakeAfterSlash() public {
    uint256 shares = _deposit(100 ether, user, user);

    vm.startPrank(slashingAdmin);

    stakeToken.slash(someone, 20 ether);

    vm.stopPrank();

    _deposit(100 ether, someone, someone);

    assertEq(stakeToken.balanceOf(someone), 125 ether);
    assertEq(stakeToken.balanceOf(user), shares);

    assertEq(stakeToken.totalAssets(), 180 ether);
  }
}
