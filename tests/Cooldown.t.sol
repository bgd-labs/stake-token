// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {StakeToken} from '../src/contracts/StakeToken.sol';
import {IStakeToken} from '../src/contracts/IStakeToken.sol';

import {ERC20} from 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import {ProxyAdmin} from 'openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {StkTestUtils} from './StkTestUtils.t.sol';

contract Cooldown is StkTestUtils {
  /**
   * cooldown should activate for a given block.timestamp and cooldown the currently held amount
   */
  function test_cooldown(uint104 amountToStake, uint104 amountToRedeem, address user) public {
    vm.assume(amountToStake >= amountToRedeem && amountToRedeem > 0);
    vm.assume(user != address(proxyAdmin) && user != address(0));

    _stake(amountToStake, user);

    vm.startPrank(user);
    stakeToken.cooldown();
    IStakeToken.CooldownSnapshot memory snapshotBefore = stakeToken.stakersCooldowns(user);
    assertEq(snapshotBefore.timestamp, block.timestamp);
    assertEq(snapshotBefore.amount, amountToStake);

    vm.warp(block.timestamp + stakeToken.getCooldownSeconds());
    _redeem(amountToRedeem, user, user);

    IStakeToken.CooldownSnapshot memory snapshotAfter = stakeToken.stakersCooldowns(user);
    assertEq(snapshotAfter.amount, amountToStake - amountToRedeem);
  }

  function test_cooldownNoIncreaseInAmount(
    uint104 amountToStake,
    uint104 amountToTopUp,
    address user
  ) public {
    vm.assume(
      amountToStake > 0 && amountToTopUp > 0 && type(uint104).max - amountToStake > amountToTopUp
    );
    vm.assume(user != address(proxyAdmin) && user != address(0));

    _stake(amountToStake, user);
    vm.startPrank(user);
    stakeToken.cooldown();

    IStakeToken.CooldownSnapshot memory snapshotBefore = stakeToken.stakersCooldowns(user);

    // increase amount
    _stake(amountToTopUp, user);

    IStakeToken.CooldownSnapshot memory snapshotAfter = stakeToken.stakersCooldowns(user);
    assertEq(snapshotBefore.timestamp, snapshotAfter.timestamp);
    assertEq(snapshotBefore.amount, snapshotAfter.amount);
    assertEq(snapshotAfter.timestamp, block.timestamp);
    assertEq(snapshotAfter.amount, amountToStake);
  }

  function test_cooldownOnTransfer(
    uint104 amountToStake,
    uint104 amountToStakeOther,
    address user,
    address otherUser
  ) public {
    vm.assume(
      amountToStake > 0 &&
        amountToStakeOther > 0 &&
        type(uint104).max - amountToStake > amountToStakeOther
    );
    vm.assume(user != address(proxyAdmin) && user != address(0) && user != otherUser);
    vm.assume(otherUser != address(0) && otherUser != address(proxyAdmin));

    _stake(amountToStake, user);
    vm.startPrank(user);
    stakeToken.cooldown();

    IStakeToken.CooldownSnapshot memory snapshot0 = stakeToken.stakersCooldowns(user);

    // Receiving token should not affect the amount
    _stake(amountToStakeOther, otherUser);
    vm.prank(otherUser);
    stakeToken.transfer(user, amountToStakeOther);
    IStakeToken.CooldownSnapshot memory snapshot1 = stakeToken.stakersCooldowns(user);
    assertEq(snapshot0.timestamp, snapshot1.timestamp, 'MISMATCH_BEFORE_COOLDOWN');
    assertEq(snapshot0.amount, snapshot1.amount, 'MISMATCH_BEFORE_COOLDOWN_AMOUNT');

    // Sending token should not affect the amount as long as balance > amount
    vm.prank(user);
    stakeToken.transfer(otherUser, amountToStakeOther);
    IStakeToken.CooldownSnapshot memory snapshot2 = stakeToken.stakersCooldowns(user);
    assertEq(snapshot0.timestamp, snapshot2.timestamp, 'MISMATCH_COOLDOWN');
    assertEq(snapshot0.amount, snapshot2.amount, 'MISMATCH_COOLDOWN_AMOUNT');

    // Sending token should decrease the cooldown amount when balance <= amount
    vm.startPrank(user);
    stakeToken.transfer(otherUser, amountToStake);
    vm.stopPrank();
    IStakeToken.CooldownSnapshot memory snapshot3 = stakeToken.stakersCooldowns(user);
    assertEq(snapshot3.timestamp, 0, 'MISMATCH_AFTER_COOLDOWN');
    assertEq(snapshot3.amount, 0, 'MISMATCH_AFTER_COOLDOWN_AMOUNT');
  }

  function test_cooldownInsufficient_shouldRevert(
    uint104 amountToStake,
    uint104 amountToUnstake,
    uint40 secondsAfterCooldownActivation,
    address user,
    address destination
  ) public {
    vm.assume(amountToUnstake != 0 && amountToStake >= amountToUnstake);
    vm.assume(secondsAfterCooldownActivation < stakeToken.getCooldownSeconds());
    vm.assume(user != address(proxyAdmin) && user != address(0) && destination != address(0));

    _stake(amountToStake, user);
    vm.prank(user);
    stakeToken.cooldown();

    vm.warp(block.timestamp + secondsAfterCooldownActivation);
    vm.prank(user);
    vm.expectRevert('INSUFFICIENT_COOLDOWN');
    stakeToken.redeem(destination, amountToUnstake);
  }

  function test_cooldownWindowClosed_shouldRevert(
    uint104 amountToStake,
    uint104 amountToUnstake,
    uint40 secondsAfterCooldownActivation,
    address user,
    address destination
  ) public {
    vm.assume(amountToUnstake != 0 && amountToStake >= amountToUnstake);
    vm.assume(
      secondsAfterCooldownActivation >
        stakeToken.getCooldownSeconds() + stakeToken.getUnstakeWindow()
    );
    vm.assume(user != address(proxyAdmin) && user != address(0) && destination != address(0));

    _stake(amountToStake, user);
    vm.prank(user);
    stakeToken.cooldown();

    vm.warp(block.timestamp + secondsAfterCooldownActivation);
    vm.prank(user);
    vm.expectRevert('UNSTAKE_WINDOW_FINISHED');
    stakeToken.redeem(destination, amountToUnstake);
  }

  function test_redeemMoreThenCooldown_shouldRedeemMax(
    uint104 amountToStake,
    uint104 amountToTopUp,
    uint104 amountToUnstake,
    address user,
    address destination
  ) public {
    vm.assume(amountToStake != 0 && amountToUnstake >= amountToStake);
    vm.assume(amountToTopUp != 0 && type(uint104).max - amountToTopUp >= amountToStake);
    vm.assume(
      user != address(proxyAdmin) &&
        user != address(0) &&
        user != address(stakeToken) &&
        destination != address(0) &&
        destination != address(stakeToken)
    );

    _stake(amountToStake, user);
    vm.prank(user);
    stakeToken.cooldown();
    _stake(amountToTopUp, user);
    IStakeToken.CooldownSnapshot memory snapshotAfterSecondStake = stakeToken.stakersCooldowns(
      user
    );
    assertEq(snapshotAfterSecondStake.amount, amountToStake, 'STAKE_SHOULD_NOT_ALTER_COOLDOWN');
    vm.warp(block.timestamp + stakeToken.getCooldownSeconds());
    _redeem(amountToUnstake, user, destination);

    assertEq(underlyingToken.balanceOf(destination), amountToStake, 'WRONG_AMOUNT_REDEEMED');
    assertEq(stakeToken.balanceOf(user), amountToTopUp, 'WRONG_AMOUNT_LEFT');
  }
}
