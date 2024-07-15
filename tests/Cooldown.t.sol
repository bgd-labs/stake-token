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
    IStakeToken.CooldownSetup memory cooldownBefore = stakeToken.stakersCooldowns(user);
    // @pavelvm5 rewrite here, cause now we set time for redeem unlock, not when cooldown was called
    assertEq(cooldownBefore.timestamp, block.timestamp + stakeToken.getDefaultCooldownSeconds());
    assertEq(cooldownBefore.amount, amountToStake);

    vm.warp(block.timestamp + stakeToken.getDefaultCooldownSeconds());
    _redeem(amountToRedeem, user, user);

    IStakeToken.CooldownSetup memory cooldownAfter = stakeToken.stakersCooldowns(user);
    assertEq(cooldownAfter.amount, amountToStake - amountToRedeem);
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

    IStakeToken.CooldownSetup memory cooldownBefore = stakeToken.stakersCooldowns(user);

    // increase amount
    _stake(amountToTopUp, user);

    IStakeToken.CooldownSetup memory cooldownAfter = stakeToken.stakersCooldowns(user);
    assertEq(cooldownBefore.timestamp, cooldownAfter.timestamp);
    assertEq(cooldownBefore.amount, cooldownAfter.amount);
    assertEq(cooldownAfter.timestamp, block.timestamp + stakeToken.getDefaultCooldownSeconds());
    assertEq(cooldownAfter.amount, amountToStake);
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

    IStakeToken.CooldownSetup memory cooldown0 = stakeToken.stakersCooldowns(user);

    // Receiving token should not affect the amount
    _stake(amountToStakeOther, otherUser);
    vm.prank(otherUser);
    stakeToken.transfer(user, amountToStakeOther);
    IStakeToken.CooldownSetup memory cooldown1 = stakeToken.stakersCooldowns(user);

    assertEq(cooldown0.timestamp, cooldown1.timestamp, 'MISMATCH_BEFORE_COOLDOWN');
    assertEq(cooldown0.amount, cooldown1.amount, 'MISMATCH_BEFORE_COOLDOWN_AMOUNT');

    // Sending token should not affect the amount as long as balance > amount
    vm.prank(user);
    stakeToken.transfer(otherUser, amountToStakeOther);
    IStakeToken.CooldownSetup memory cooldown2 = stakeToken.stakersCooldowns(user);
    assertEq(cooldown1.timestamp, cooldown2.timestamp, 'MISMATCH_COOLDOWN');
    assertEq(cooldown0.amount, cooldown2.amount, 'MISMATCH_COOLDOWN_AMOUNT');

    // Sending token should decrease the cooldown amount when balance <= amount
    vm.startPrank(user);
    stakeToken.transfer(otherUser, amountToStake);
    vm.stopPrank();
    IStakeToken.CooldownSetup memory cooldown3 = stakeToken.stakersCooldowns(user);
    assertEq(cooldown3.timestamp, 0, 'MISMATCH_AFTER_COOLDOWN');
    assertEq(cooldown3.amount, 0, 'MISMATCH_AFTER_COOLDOWN_AMOUNT');
  }

  function test_cooldownInsufficient_shouldRevert(
    uint104 amountToStake,
    uint104 amountToUnstake,
    uint40 secondsAfterCooldownActivation,
    address user,
    address destination
  ) public {
    vm.assume(amountToUnstake != 0 && amountToStake >= amountToUnstake);
    vm.assume(secondsAfterCooldownActivation < stakeToken.getDefaultCooldownSeconds());
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
        stakeToken.getDefaultCooldownSeconds() + stakeToken.getUnstakeWindow()
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
    IStakeToken.CooldownSetup memory cooldownAfterSecondStake = stakeToken.stakersCooldowns(user);
    assertEq(cooldownAfterSecondStake.amount, amountToStake, 'STAKE_SHOULD_NOT_ALTER_COOLDOWN');

    vm.warp(block.timestamp + stakeToken.getDefaultCooldownSeconds());
    _redeem(amountToUnstake, user, destination);

    assertEq(underlyingToken.balanceOf(destination), amountToStake, 'WRONG_AMOUNT_REDEEMED');
    assertEq(stakeToken.balanceOf(user), amountToTopUp, 'WRONG_AMOUNT_LEFT');
  }

  // @pavelvm5 fast-withdrawal tests start here, check only impact using reducedCooldown function, redeem/transfer process is the same
  function test_reducedCooldown(
    uint104 amountToStake,
    uint104 amountToRedeem,
    address user
  ) public {
    uint256 fee = (amountToStake * maxFee) / 10_000;

    vm.assume(amountToStake >= amountToRedeem + fee && amountToRedeem > 0);
    vm.assume(user != address(proxyAdmin) && user != address(0) && user != treasury);

    _stake(amountToStake, user);

    vm.startPrank(user);

    uint256 maxReductionSeconds = stakeToken.getMaxReductionSeconds();
    stakeToken.reducedCooldown(maxReductionSeconds);

    IStakeToken.CooldownSetup memory cooldownBefore = stakeToken.stakersCooldowns(user);

    uint256 cooldownSeconds = stakeToken.getDefaultCooldownSeconds() - maxReductionSeconds;

    assertEq(cooldownBefore.timestamp, block.timestamp + cooldownSeconds);

    assertEq(cooldownBefore.amount, amountToStake - fee);

    vm.warp(block.timestamp + cooldownSeconds);
    _redeem(amountToRedeem, user, user);

    IStakeToken.CooldownSetup memory cooldownAfter = stakeToken.stakersCooldowns(user);

    console.log(cooldownAfter.amount);
    console.log(amountToStake);
    console.log(fee);
    console.log(amountToRedeem);

    assertEq(cooldownAfter.amount, amountToStake - fee - amountToRedeem);
  }

  function test_reducedCooldownTreasuryFees(
    uint104 amountToStake,
    uint104 amountToRedeem,
    address user
  ) public {
    uint256 fee = (amountToStake * maxFee) / 10_000;

    vm.assume(amountToStake >= amountToRedeem + fee && amountToRedeem > 0);
    vm.assume(user != address(proxyAdmin) && user != address(0) && user != treasury);

    _stake(amountToStake, user);

    vm.startPrank(user);

    uint256 totalSupplyBefore = stakeToken.totalSupply();

    uint256 balanceTreasuryBefore = underlyingToken.balanceOf(treasury);
    uint256 underlyingFeesToTreasury = stakeToken.previewRedeem(fee);

    uint256 maxReductionSeconds = stakeToken.getMaxReductionSeconds();
    stakeToken.reducedCooldown(maxReductionSeconds);

    uint256 totalSupplyAfter = stakeToken.totalSupply();

    assertEq(totalSupplyBefore - totalSupplyAfter, fee);

    uint256 balanceTreasuryAfter = underlyingToken.balanceOf(treasury);

    assertEq(balanceTreasuryAfter - balanceTreasuryBefore, underlyingFeesToTreasury);
  }

  function test_reducedCooldownDifferentTime(
    uint104 amountToStake,
    uint104 amountToRedeem,
    address user,
    uint32 reducedTime
  ) public {
    uint256 maxReductionSeconds = stakeToken.getMaxReductionSeconds();
    uint256 fee = (amountToStake * maxFee * reducedTime) / maxReductionSeconds / 10_000;

    vm.assume(amountToStake >= amountToRedeem + fee && amountToRedeem > 0);
    vm.assume(user != address(proxyAdmin) && user != address(0) && user != treasury);
    vm.assume(reducedTime <= maxReductionSeconds);

    _stake(amountToStake, user);

    vm.startPrank(user);

    uint256 balanceTreasuryBefore = underlyingToken.balanceOf(treasury);
    uint256 underlyingFeesToTreasury = stakeToken.previewRedeem(fee);

    stakeToken.reducedCooldown(reducedTime);

    uint256 balanceTreasuryAfter = underlyingToken.balanceOf(treasury);

    assertEq(balanceTreasuryAfter - balanceTreasuryBefore, underlyingFeesToTreasury);

    IStakeToken.CooldownSetup memory cooldownBefore = stakeToken.stakersCooldowns(user);

    uint256 cooldownSeconds = stakeToken.getDefaultCooldownSeconds() - reducedTime;

    assertEq(cooldownBefore.timestamp, block.timestamp + cooldownSeconds);

    assertEq(cooldownBefore.amount, amountToStake - fee);

    vm.warp(block.timestamp + cooldownSeconds);
    _redeem(amountToRedeem, user, user);

    IStakeToken.CooldownSetup memory cooldownAfter = stakeToken.stakersCooldowns(user);
    assertEq(cooldownAfter.amount, amountToStake - fee - amountToRedeem);
  }
}
