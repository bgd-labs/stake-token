// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {StakeToken} from '../src/contracts/StakeToken.sol';
import {ERC20} from 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import {ProxyAdmin} from 'openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {IERC20Errors} from 'openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol';
import {StakeTestBase} from './utils/StakeTestBase.sol';

// @pavelvm5 in this file shares are messed with assets, so I think we should fix these tests in future
// cause they are not valid + add more complex tests with slashing to find out the order of error
contract ERC20Std is StakeTestBase {
  function test_name() external {
    assertEq('Stake Test', stakeToken.name());
  }

  function test_symbol() external {
    assertEq('stkTest', stakeToken.symbol());
  }

  // mint
  function test_stake(uint104 amount) public {
    vm.assume(amount > 0);
    _stake(amount, user);
    assertEq(stakeToken.totalAssets(), amount);
    assertEq(stakeToken.totalAssets(), stakeToken.balanceOf(user));
  }

  // burn
  function test_redeem(uint104 amountStaked, uint104 amountRedeemed) public {
    vm.assume(amountStaked > 0);
    vm.assume(amountRedeemed != 0 && amountRedeemed <= amountStaked);
    address destination = vm.addr(100);

    _stake(amountStaked, user);
    assertEq(stakeToken.balanceOf(user), stakeToken.convertToShares(amountStaked));

    vm.prank(user);
    stakeToken.cooldown();
    vm.warp(block.timestamp + stakeToken.getDefaultCooldownSeconds());
    _redeem(amountRedeemed, user, destination);

    assertEq(stakeToken.totalAssets(), amountStaked - amountRedeemed);
    assertEq(stakeToken.balanceOf(user), stakeToken.convertToAssets(amountStaked - amountRedeemed));
    assertEq(underlying.balanceOf(destination), amountRedeemed);
  }

  function test_approve(uint256 amount) public {
    assertTrue(stakeToken.approve(user, amount));
    assertEq(stakeToken.allowance(address(this), user), amount);
  }

  function test_resetApproval(uint256 amount) public {
    test_approve(amount);
    assertTrue(stakeToken.approve(user, 0));
    assertEq(stakeToken.allowance(address(this), user), 0);
  }

  function test_transfer(uint104 amountStake, uint104 amountTransfer, address otherUser) external {
    vm.assume(otherUser != address(proxyAdmin) && otherUser != user && otherUser != address(0));
    vm.assume(amountStake > 1);
    vm.assume(amountTransfer <= amountStake);
    test_stake(amountStake);
    vm.startPrank(user);
    stakeToken.transfer(otherUser, amountTransfer);
    assertEq(stakeToken.balanceOf(otherUser), amountTransfer);
    assertEq(stakeToken.balanceOf(user), amountStake - amountTransfer);
    vm.stopPrank();
  }

  function test_transferFrom(
    uint104 amountStake,
    uint104 amountTransfer,
    address otherUser
  ) external {
    vm.assume(otherUser != address(proxyAdmin) && otherUser != user && otherUser != address(0));
    vm.assume(amountTransfer <= amountStake);
    test_stake(amountStake);
    vm.prank(user);
    stakeToken.approve(address(this), amountStake);
    assertTrue(stakeToken.transferFrom(user, otherUser, amountTransfer));
    assertEq(stakeToken.allowance(user, address(this)), amountStake - amountTransfer);
    assertEq(stakeToken.balanceOf(user), amountStake - amountTransfer);
    assertEq(stakeToken.balanceOf(otherUser), amountTransfer);
  }

  function test_stakeToZeroShouldRevert() external {
    uint104 amount = 100;
    deal(address(underlying), user, amount);
    vm.startPrank(user);
    underlying.approve(address(stakeToken), amount);
    vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0)));
    stakeToken.deposit(amount, address(0));
    vm.stopPrank();
  }
}
