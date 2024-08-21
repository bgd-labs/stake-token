// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IERC20Errors} from 'openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol';

import {StakeTestBase} from './utils/StakeTestBase.sol';

contract ERC20Tests is StakeTestBase {
  function test_name() external view {
    assertEq('Stake Test', stakeToken.name());
  }

  function test_symbol() external view {
    assertEq('stkTest', stakeToken.symbol());
  }

  // mint
  function test_mint(uint192 amount) public {
    vm.assume(amount > 0);

    _mint(amount, user, user);

    assertEq(stakeToken.totalAssets(), amount);
    assertEq(stakeToken.totalSupply(), stakeToken.balanceOf(user));
  }

  // burn
  function test_redeem(uint192 amountStaked, uint192 amountRedeemed) public {
    vm.assume(amountStaked > 0);
    vm.assume(amountRedeemed != 0 && amountRedeemed <= amountStaked);

    _mint(amountStaked, user, user);

    vm.startPrank(user);

    stakeToken.cooldown();
    skip(stakeToken.getCooldown());

    stakeToken.redeem(amountRedeemed, user, user);

    assertEq(stakeToken.totalAssets(), amountStaked - amountRedeemed);
    assertEq(underlying.balanceOf(user), amountRedeemed);

    assertEq(stakeToken.balanceOf(user), stakeToken.totalSupply());
    assertEq(stakeToken.balanceOf(user), stakeToken.convertToShares(amountStaked - amountRedeemed));
  }

  function test_approve(uint192 amount) public {
    assertTrue(stakeToken.approve(user, amount));
    assertEq(stakeToken.allowance(address(this), user), amount);
  }

  function test_resetApproval(uint192 amount) public {
    assertTrue(stakeToken.approve(user, amount));
    assertTrue(stakeToken.approve(user, 0));
    assertEq(stakeToken.allowance(address(this), user), 0);
  }

  function test_transferWithoutCooldownInStake(
    uint192 amountStake,
    uint192 amountTransfer
  ) external {
    vm.assume(amountStake > 0);
    vm.assume(amountTransfer <= stakeToken.convertToShares(amountStake));

    _deposit(amountStake, user, user);

    vm.startPrank(user);

    stakeToken.transfer(someone, amountTransfer);

    assertEq(stakeToken.balanceOf(someone), stakeToken.convertToShares(amountTransfer));
    assertEq(stakeToken.balanceOf(user), stakeToken.convertToShares(amountStake - amountTransfer));
  }

  function test_transferWithCooldownInStake(uint192 amountStake, uint192 amountTransfer) external {
    vm.assume(amountStake > 0);
    vm.assume(amountTransfer <= stakeToken.convertToShares(amountStake));

    _deposit(amountStake, user, user);

    vm.startPrank(user);

    stakeToken.cooldown();

    skip(1);

    stakeToken.transfer(someone, amountTransfer);

    assertEq(stakeToken.balanceOf(someone), stakeToken.convertToShares(amountTransfer));
    assertEq(stakeToken.balanceOf(user), amountStake - amountTransfer);
  }

  function test_transferFrom(uint192 amountStake, uint192 amountTransfer) external {
    vm.assume(amountStake > 0);
    vm.assume(amountTransfer <= stakeToken.convertToShares(amountStake));

    _deposit(amountStake, user, user);

    vm.startPrank(user);

    stakeToken.approve(someone, amountStake);

    vm.stopPrank();
    vm.startPrank(someone);

    assertTrue(stakeToken.transferFrom(user, someone, amountTransfer));

    vm.stopPrank();

    assertEq(stakeToken.allowance(user, someone), amountStake - amountTransfer);

    assertEq(stakeToken.balanceOf(user), amountStake - amountTransfer);
    assertEq(stakeToken.balanceOf(someone), amountTransfer);
  }

  function test_transferFromWithoutApprove(uint192 amountStake, uint192 amountTransfer) external {
    vm.assume(amountStake > 0);
    vm.assume(0 < amountTransfer && amountTransfer <= stakeToken.convertToShares(amountStake));

    _deposit(amountStake, user, user);

    vm.startPrank(someone);

    vm.expectRevert(
      abi.encodeWithSelector(
        IERC20Errors.ERC20InsufficientAllowance.selector,
        someone,
        0,
        amountTransfer
      )
    );
    stakeToken.transferFrom(user, someone, amountTransfer);
  }
}
