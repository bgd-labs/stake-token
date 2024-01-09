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
  function setUp() public {
    _initializeStkToken(3000);
  }

  /**
   * cooldown should activate for a given block.timestamp and cooldown the currently held amount
   */
  function test_cooldown(uint104 amountToStake, uint104 amountToRedeem, address user) public {
    vm.assume(amountToStake >= amountToRedeem && amountToRedeem > 0);
    vm.assume(user != address(proxyAdmin) && user != address(0));

    _stake(amountToStake, user);

    vm.startPrank(user);
    stakeToken.cooldown();
    (uint40 cooldownBefore, uint216 cooldownAmountBefore) = stakeToken.stakersCooldowns(user);
    assertEq(cooldownBefore, block.timestamp);
    assertEq(cooldownAmountBefore, amountToStake);

    vm.warp(block.timestamp + stakeToken.getCooldownSeconds());
    _redeem(amountToRedeem, user, user);

    (, uint216 cooldownAmountAfterRedeem) = stakeToken.stakersCooldowns(user);
    assertEq(cooldownAmountAfterRedeem, amountToStake - amountToRedeem);
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

    (uint40 cooldownBefore, uint216 cooldownAmountBefore) = stakeToken.stakersCooldowns(user);

    // increase amount
    _stake(amountToTopUp, user);

    (uint40 cooldownAfter, uint216 cooldownAmountAfter) = stakeToken.stakersCooldowns(user);
    assertEq(cooldownBefore, cooldownAfter);
    assertEq(cooldownAmountBefore, cooldownAmountAfter);
    assertEq(cooldownAfter, block.timestamp);
    assertEq(cooldownAmountAfter, amountToStake);
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

    (uint40 cooldownBefore, uint216 cooldownAmountBefore) = stakeToken.stakersCooldowns(user);

    // Receiving token should not affect the amount
    _stake(amountToStakeOther, otherUser);
    vm.prank(otherUser);
    stakeToken.transfer(user, amountToStakeOther);
    (uint40 cooldownAfterReceive, uint216 cooldownAmountAfterReceive) = stakeToken.stakersCooldowns(
      user
    );
    assertEq(cooldownBefore, cooldownAfterReceive, 'MISMATCH_BEFORE_COOLDOWN');
    assertEq(cooldownAmountBefore, cooldownAmountAfterReceive, 'MISMATCH_BEFORE_COOLDOWN_AMOUNT');

    // Sending token should not affect the amount as long as balance > amount
    vm.prank(user);
    stakeToken.transfer(otherUser, amountToStakeOther);
    (uint40 cooldownAfterSent1, uint216 cooldownAmountAfterSent1) = stakeToken.stakersCooldowns(
      user
    );
    assertEq(cooldownBefore, cooldownAfterSent1, 'MISMATCH_COOLDOWN');
    assertEq(cooldownAmountBefore, cooldownAmountAfterSent1, 'MISMATCH_COOLDOWN_AMOUNT');

    // Sending token should decrease the cooldown amount when balance <= amount
    vm.startPrank(user);
    stakeToken.transfer(otherUser, amountToStake);
    vm.stopPrank();
    (uint40 cooldownAfterSent2, uint216 cooldownAmountAfterSent2) = stakeToken.stakersCooldowns(
      user
    );
    assertEq(cooldownAfterSent2, 0, 'MISMATCH_AFTER_COOLDOWN');
    assertEq(cooldownAmountAfterSent2, 0, 'MISMATCH_AFTER_COOLDOWN_AMOUNT');
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
      secondsAfterCooldownActivation > stakeToken.getCooldownSeconds() + stakeToken.UNSTAKE_WINDOW()
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
        destination != address(0) &&
        destination != address(stakeToken)
    );

    _stake(amountToStake, user);
    vm.prank(user);
    stakeToken.cooldown();
    _stake(amountToTopUp, user);
    (, uint216 cooldownAmountAfterSecondStake) = stakeToken.stakersCooldowns(user);
    assertEq(cooldownAmountAfterSecondStake, amountToStake, 'STAKE_SHOULD_NOT_ALTER_COOLDOWN');
    vm.warp(block.timestamp + stakeToken.getCooldownSeconds());
    _redeem(amountToUnstake, user, destination);

    assertEq(underlyingToken.balanceOf(destination), amountToStake, 'WRONG_AMOUNT_REDEEMED');
    assertEq(stakeToken.balanceOf(user), amountToTopUp, 'WRONG_AMOUNT_LEFT');
  }
}
