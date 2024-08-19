// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {StakeToken} from '../src/contracts/StakeToken.sol';
import {IStakeToken} from '../src/contracts/interfaces/IStakeToken.sol';

import {ERC20} from 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import {ProxyAdmin} from 'openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {StakeTestBase} from './utils/StakeTestBase.sol';

contract Cooldown is StakeTestBase {
  /**
   * cooldown should activate for a given block.timestamp and cooldown the currently held amount
   */
  function test_cooldown(uint104 amountToStake, uint104 amountToRedeem, address fuzzUser) public {
    vm.assume(amountToStake >= amountToRedeem && amountToRedeem > 0);
    vm.assume(fuzzUser != address(proxyAdmin) && fuzzUser != address(0));

    _stake(amountToStake, fuzzUser);

    vm.startPrank(fuzzUser);
    stakeToken.cooldown();
    IStakeToken.CooldownSnapshot memory snapshotBefore = stakeToken.stakersCooldowns(fuzzUser);
    assertEq(snapshotBefore.cooldownEnd, block.timestamp + stakeToken.getDefaultCooldownSeconds());
    assertEq(snapshotBefore.amount, amountToStake);

    vm.warp(block.timestamp + stakeToken.getDefaultCooldownSeconds());
    _redeem(amountToRedeem, fuzzUser, fuzzUser);

    IStakeToken.CooldownSnapshot memory snapshotAfter = stakeToken.stakersCooldowns(fuzzUser);
    assertEq(snapshotAfter.amount, amountToStake - amountToRedeem);
  }

  function test_cooldownNoIncreaseInAmount(
    uint104 amountToStake,
    uint104 amountToTopUp,
    address fuzzUser
  ) public {
    vm.assume(
      amountToStake > 0 && amountToTopUp > 0 && type(uint104).max - amountToStake > amountToTopUp
    );
    vm.assume(fuzzUser != address(proxyAdmin) && fuzzUser != address(0));

    _stake(amountToStake, fuzzUser);
    vm.startPrank(fuzzUser);
    stakeToken.cooldown();

    IStakeToken.CooldownSnapshot memory snapshotBefore = stakeToken.stakersCooldowns(fuzzUser);

    // increase amount
    _stake(amountToTopUp, fuzzUser);

    IStakeToken.CooldownSnapshot memory snapshotAfter = stakeToken.stakersCooldowns(fuzzUser);
    assertEq(snapshotBefore.cooldownEnd, snapshotAfter.cooldownEnd);
    assertEq(snapshotBefore.amount, snapshotAfter.amount);
    assertEq(snapshotAfter.cooldownEnd, block.timestamp + stakeToken.getDefaultCooldownSeconds());
    assertEq(snapshotAfter.amount, amountToStake);
  }

  function test_cooldownOnTransfer(
    uint104 amountToStake,
    uint104 amountToStakeOther,
    address fuzzUser,
    address otherUser
  ) public {
    vm.assume(
      amountToStake > 0 &&
        amountToStakeOther > 0 &&
        type(uint104).max - amountToStake > amountToStakeOther
    );
    vm.assume(fuzzUser != address(proxyAdmin) && fuzzUser != address(0) && fuzzUser != otherUser);
    vm.assume(otherUser != address(0) && otherUser != address(proxyAdmin));

    _stake(amountToStake, fuzzUser);
    vm.startPrank(fuzzUser);
    stakeToken.cooldown();

    IStakeToken.CooldownSnapshot memory snapshot0 = stakeToken.stakersCooldowns(fuzzUser);

    // Receiving token should not affect the amount
    _stake(amountToStakeOther, otherUser);
    vm.prank(otherUser);
    stakeToken.transfer(fuzzUser, amountToStakeOther);
    IStakeToken.CooldownSnapshot memory snapshot1 = stakeToken.stakersCooldowns(fuzzUser);
    assertEq(snapshot0.cooldownEnd, snapshot1.cooldownEnd, 'MISMATCH_BEFORE_COOLDOWN');
    assertEq(snapshot0.amount, snapshot1.amount, 'MISMATCH_BEFORE_COOLDOWN_AMOUNT');

    // Sending token should not affect the amount as long as balance > amount
    vm.prank(fuzzUser);
    stakeToken.transfer(otherUser, amountToStakeOther);
    IStakeToken.CooldownSnapshot memory snapshot2 = stakeToken.stakersCooldowns(fuzzUser);
    assertEq(snapshot0.cooldownEnd, snapshot2.cooldownEnd, 'MISMATCH_COOLDOWN');
    assertEq(snapshot0.amount, snapshot2.amount, 'MISMATCH_COOLDOWN_AMOUNT');

    // Sending token should decrease the cooldown amount when balance <= amount
    vm.startPrank(fuzzUser);
    stakeToken.transfer(otherUser, amountToStake);
    vm.stopPrank();
    IStakeToken.CooldownSnapshot memory snapshot3 = stakeToken.stakersCooldowns(fuzzUser);
    assertEq(snapshot3.cooldownEnd, 0, 'MISMATCH_AFTER_COOLDOWN');
    assertEq(snapshot3.amount, 0, 'MISMATCH_AFTER_COOLDOWN_AMOUNT');
  }

  function test_cooldownInsufficient_shouldRevert(
    uint104 amountToStake,
    uint104 amountToUnstake,
    uint40 secondsAfterCooldownActivation,
    address fuzzUser,
    address destination
  ) public {
    vm.assume(amountToUnstake != 0 && amountToStake >= amountToUnstake);
    vm.assume(secondsAfterCooldownActivation < stakeToken.getDefaultCooldownSeconds());
    vm.assume(
      fuzzUser != address(proxyAdmin) && fuzzUser != address(0) && destination != address(0)
    );

    _stake(amountToStake, fuzzUser);
    vm.prank(fuzzUser);
    stakeToken.cooldown();

    vm.warp(block.timestamp + secondsAfterCooldownActivation);
    uint256 cooldownEnd = stakeToken.stakersCooldowns(fuzzUser).cooldownEnd;
    vm.prank(fuzzUser);
    vm.expectRevert(abi.encodeWithSelector(IStakeToken.CooldownNotReady.selector, cooldownEnd));
    stakeToken.redeem(destination, amountToUnstake);
  }

  function test_cooldownWindowClosed_shouldRevert(
    uint104 amountToStake,
    uint104 amountToUnstake,
    uint40 secondsAfterCooldownActivation,
    address fuzzUser,
    address destination
  ) public {
    vm.assume(amountToUnstake != 0 && amountToStake >= amountToUnstake);
    vm.assume(
      secondsAfterCooldownActivation >
        stakeToken.getDefaultCooldownSeconds() + stakeToken.getWithdrawalWindow()
    );
    vm.assume(
      fuzzUser != address(proxyAdmin) && fuzzUser != address(0) && destination != address(0)
    );

    _stake(amountToStake, fuzzUser);
    vm.prank(fuzzUser);
    stakeToken.cooldown();

    vm.warp(block.timestamp + secondsAfterCooldownActivation);
    IStakeToken.CooldownSnapshot memory snapshot = stakeToken.stakersCooldowns(fuzzUser);
    vm.prank(fuzzUser);
    vm.expectRevert(abi.encodeWithSelector(IStakeToken.CooldownExpired.selector, snapshot.cooldownEnd + snapshot.withdrawalWindowSeconds));
    stakeToken.redeem(destination, amountToUnstake);
  }

  function test_redeemMoreThenCooldown_shouldRedeemMax(
    uint104 amountToStake,
    uint104 amountToTopUp,
    uint104 amountToUnstake,
    address fuzzUser,
    address destination
  ) public {
    vm.assume(amountToStake != 0 && amountToUnstake >= amountToStake);
    vm.assume(amountToTopUp != 0 && type(uint104).max - amountToTopUp >= amountToStake);
    vm.assume(
      fuzzUser != address(proxyAdmin) &&
        fuzzUser != address(0) &&
        fuzzUser != address(stakeToken) &&
        destination != address(0) &&
        destination != address(stakeToken)
    );

    _stake(amountToStake, fuzzUser);
    vm.prank(fuzzUser);
    stakeToken.cooldown();
    _stake(amountToTopUp, fuzzUser);
    IStakeToken.CooldownSnapshot memory snapshotAfterSecondStake = stakeToken.stakersCooldowns(
      fuzzUser
    );
    assertEq(snapshotAfterSecondStake.amount, amountToStake, 'STAKE_SHOULD_NOT_ALTER_COOLDOWN');
    vm.warp(block.timestamp + stakeToken.getDefaultCooldownSeconds());
    _redeem(amountToUnstake, fuzzUser, destination);

    assertEq(underlying.balanceOf(destination), amountToStake, 'WRONG_AMOUNT_REDEEMED');
    assertEq(stakeToken.balanceOf(fuzzUser), amountToTopUp, 'WRONG_AMOUNT_LEFT');
  }
}
