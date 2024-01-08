// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {StakeToken} from '../src/contracts/StakeToken.sol';
import {ERC20} from 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import {ProxyAdmin} from 'openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {IERC20Errors} from 'openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol';
import {StkTestUtils} from './StkTestUtils.t.sol';

contract ERC20Std is StkTestUtils {
  function setUp() public {
    _initializeStkToken(3000);
  }

  function test_name() external {
    assertEq('Stake Test', stakeToken.name());
  }

  function test_symbol() external {
    assertEq('stkTest', stakeToken.symbol());
  }

  // mint
  function test_stake(uint104 amount) public {
    vm.assume(amount > 0);
    _stake(amount, USER);
    assertEq(stakeToken.totalSupply(), amount);
    assertEq(stakeToken.totalSupply(), stakeToken.balanceOf(USER));
  }

  // burn
  function test_redeem(uint104 amountStaked, uint104 amountRedeemed) public {
    vm.assume(amountStaked > 0);
    vm.assume(amountRedeemed != 0 && amountRedeemed <= amountStaked);
    address destination = vm.addr(100);

    _stake(amountStaked, USER);
    assertEq(stakeToken.balanceOf(USER), amountStaked);

    vm.prank(USER);
    stakeToken.cooldown();
    vm.warp(block.timestamp + stakeToken.getCooldownSeconds());
    _redeem(amountRedeemed, USER, destination);

    assertEq(stakeToken.totalSupply(), amountStaked - amountRedeemed);
    assertEq(stakeToken.balanceOf(USER), amountStaked - amountRedeemed);
    assertEq(underlyingToken.balanceOf(destination), amountRedeemed);
  }

  function test_approve(uint256 amount) public {
    assertTrue(stakeToken.approve(USER, amount));
    assertEq(stakeToken.allowance(address(this), USER), amount);
  }

  function test_resetApprocal(uint256 amount) public {
    test_approve(amount);
    assertTrue(stakeToken.approve(USER, 0));
    assertEq(stakeToken.allowance(address(this), USER), 0);
  }

  function test_transfer(uint104 amountStake, uint104 amountTransfer, address otherUser) external {
    vm.assume(otherUser != address(proxyAdmin) && otherUser != USER && otherUser != address(0));
    vm.assume(amountStake > 1);
    vm.assume(amountTransfer <= amountStake);
    test_stake(amountStake);
    vm.startPrank(USER);
    stakeToken.transfer(otherUser, amountTransfer);
    assertEq(stakeToken.balanceOf(otherUser), amountTransfer);
    assertEq(stakeToken.balanceOf(USER), amountStake - amountTransfer);
    vm.stopPrank();
  }

  function test_transferFrom(
    uint104 amountStake,
    uint104 amountTransfer,
    address otherUser
  ) external {
    vm.assume(otherUser != address(proxyAdmin) && otherUser != USER && otherUser != address(0));
    vm.assume(amountTransfer <= amountStake);
    test_stake(amountStake);
    vm.prank(USER);
    stakeToken.approve(address(this), amountStake);
    assertTrue(stakeToken.transferFrom(USER, otherUser, amountTransfer));
    assertEq(stakeToken.allowance(USER, address(this)), amountStake - amountTransfer);
    assertEq(stakeToken.balanceOf(USER), amountStake - amountTransfer);
    assertEq(stakeToken.balanceOf(otherUser), amountTransfer);
  }

  function test_stakeToZeroShouldRevert() external {
    uint104 amount = 100;
    deal(address(underlyingToken), USER, amount);
    vm.startPrank(USER);
    underlyingToken.approve(address(stakeToken), amount);
    vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0)));
    stakeToken.stake(address(0), amount);
    vm.stopPrank();
  }
}
