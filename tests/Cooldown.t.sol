// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IStakeToken} from 'src/contracts/interfaces/IStakeToken.sol';

import {ERC4626Upgradeable} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol';

import {StakeTestBase} from './utils/StakeTestBase.sol';

contract CooldownTests is StakeTestBase {
  function test_cooldown(uint192 amountToStake, uint192 amountToRedeem) public {
    vm.assume(amountToStake > amountToRedeem && amountToRedeem > 0);

    _deposit(amountToStake, user, user);

    vm.startPrank(user);

    stakeToken.cooldown();
    IStakeToken.CooldownSnapshot memory snapshotBefore = stakeToken.getStakerCooldown(user);

    assertEq(snapshotBefore.timestamp, block.timestamp + stakeToken.getCooldown());
    assertEq(snapshotBefore.amount, amountToStake);

    skip(stakeToken.getCooldown());

    stakeToken.withdraw(amountToRedeem, user, user);

    IStakeToken.CooldownSnapshot memory snapshotAfter = stakeToken.getStakerCooldown(user);

    assertEq(snapshotAfter.amount, amountToStake - amountToRedeem);
    assertEq(snapshotAfter.timestamp, snapshotBefore.timestamp);
  }

  function test_cooldownNoIncreaseInAmount(uint192 amountToStake, uint192 amountToTopUp) public {
    vm.assume(
      amountToStake > 0 &&
        amountToTopUp > 0 &&
        uint256(type(uint192).max) > 2 * uint256(amountToTopUp) + amountToStake
    );

    _deposit(amountToStake, user, user);

    vm.startPrank(user);
    stakeToken.cooldown();

    IStakeToken.CooldownSnapshot memory snapshotBefore = stakeToken.getStakerCooldown(user);

    _deposit(amountToTopUp, user, user);

    IStakeToken.CooldownSnapshot memory snapshotAfter = stakeToken.getStakerCooldown(user);

    assertEq(snapshotBefore.timestamp, snapshotAfter.timestamp);
    assertEq(snapshotBefore.amount, snapshotAfter.amount);

    assertEq(snapshotAfter.timestamp, block.timestamp + stakeToken.getCooldown());
    assertEq(snapshotAfter.amount, amountToStake);

    _deposit(amountToTopUp, someone, someone);

    vm.stopPrank();
    vm.startPrank(someone);

    stakeToken.transfer(user, stakeToken.convertToShares(amountToTopUp));

    IStakeToken.CooldownSnapshot memory snapshotAfterSecondTopUp = stakeToken.getStakerCooldown(
      user
    );

    assertEq(snapshotBefore.timestamp, snapshotAfterSecondTopUp.timestamp);
    assertEq(snapshotBefore.amount, snapshotAfterSecondTopUp.amount);

    assertEq(snapshotAfterSecondTopUp.timestamp, block.timestamp + stakeToken.getCooldown());
    assertEq(snapshotAfterSecondTopUp.amount, amountToStake);
  }

  function test_cooldownChangeOnTransfer(uint192 amountToStake, uint192 amountToTransfer) public {
    vm.assume(amountToStake > 0);
    vm.assume(amountToTransfer > 0 && amountToStake > amountToTransfer);

    _deposit(amountToStake, user, user);

    vm.startPrank(user);
    stakeToken.cooldown();

    IStakeToken.CooldownSnapshot memory snapshot0 = stakeToken.getStakerCooldown(user);

    stakeToken.transfer(someone, amountToTransfer);

    IStakeToken.CooldownSnapshot memory snapshot1 = stakeToken.getStakerCooldown(user);

    assertEq(snapshot0.timestamp, snapshot1.timestamp);
    assertEq(snapshot0.amount, snapshot1.amount + amountToTransfer);

    stakeToken.transfer(someone, amountToStake - amountToTransfer);

    IStakeToken.CooldownSnapshot memory snapshot2 = stakeToken.getStakerCooldown(user);

    assertEq(snapshot2.timestamp, 0);
    assertEq(snapshot2.amount, 0);
  }

  function test_cooldownChangeOnRedeem(uint192 amountToStake, uint192 amountToRedeem) public {
    vm.assume(amountToStake > 0);
    vm.assume(amountToRedeem > 0 && amountToStake > amountToRedeem);

    _deposit(amountToStake, user, user);

    vm.startPrank(user);
    stakeToken.cooldown();

    IStakeToken.CooldownSnapshot memory snapshot0 = stakeToken.getStakerCooldown(user);

    skip(stakeToken.getCooldown());

    stakeToken.redeem(amountToRedeem, user, user);

    IStakeToken.CooldownSnapshot memory snapshot1 = stakeToken.getStakerCooldown(user);

    assertEq(snapshot0.timestamp, snapshot1.timestamp);
    assertEq(snapshot0.amount, snapshot1.amount + amountToRedeem);

    stakeToken.redeem(amountToStake - amountToRedeem, user, user);

    IStakeToken.CooldownSnapshot memory snapshot2 = stakeToken.getStakerCooldown(user);

    assertEq(snapshot2.timestamp, 0);
    assertEq(snapshot2.amount, 0);
  }

  function test_cooldownInsufficientTime(
    uint192 amountToStake,
    uint32 AfterCooldownActivation
  ) public {
    vm.assume(amountToStake > 0);
    vm.assume(AfterCooldownActivation < stakeToken.getCooldown());

    _deposit(amountToStake, user, user);

    vm.startPrank(user);
    stakeToken.cooldown();

    skip(AfterCooldownActivation);

    vm.expectRevert();

    vm.expectRevert(
      abi.encodeWithSelector(
        ERC4626Upgradeable.ERC4626ExceededMaxWithdraw.selector,
        address(user),
        1,
        0
      )
    );

    stakeToken.withdraw(1, user, user);
  }

  function test_cooldownWindowClosed(uint192 amountToStake, uint32 GreaterThanNeeded) public {
    vm.assume(amountToStake > 0);
    vm.assume(GreaterThanNeeded > stakeToken.getCooldown() + stakeToken.getUnstakeWindow());

    _deposit(amountToStake, user, user);

    vm.startPrank(user);

    stakeToken.cooldown();

    skip(GreaterThanNeeded);

    vm.expectRevert(
      abi.encodeWithSelector(
        ERC4626Upgradeable.ERC4626ExceededMaxWithdraw.selector,
        address(user),
        1,
        0
      )
    );

    stakeToken.withdraw(1, user, user);
  }

  function test_cooldownOnBehalf(uint192 amountToStake, uint192 amountToRedeem) public {
    vm.assume(amountToStake > amountToRedeem && amountToRedeem > 0);

    _deposit(amountToStake, user, user);

    vm.startPrank(user);

    stakeToken.approve(someone, stakeToken.convertToShares(amountToStake));

    vm.stopPrank();
    vm.startPrank(someone);

    stakeToken.cooldownOnBehalfOf(user);

    IStakeToken.CooldownSnapshot memory snapshotBefore = stakeToken.getStakerCooldown(user);

    assertEq(snapshotBefore.timestamp, block.timestamp + stakeToken.getCooldown());
    assertEq(snapshotBefore.amount, amountToStake);

    skip(stakeToken.getCooldown());

    stakeToken.withdraw(amountToRedeem, someone, user);

    IStakeToken.CooldownSnapshot memory snapshotAfter = stakeToken.getStakerCooldown(user);

    assertEq(snapshotAfter.amount, amountToStake - amountToRedeem);
    assertEq(snapshotAfter.timestamp, snapshotBefore.timestamp);
  }

  function test_cooldownOnBehalfNotApproved(uint192 amountToStake) public {
    vm.assume(amountToStake > 0);

    _deposit(amountToStake, user, user);

    vm.startPrank(someone);

    vm.expectRevert(
      abi.encodeWithSelector(IStakeToken.NotApprovedForCooldown.selector, user, someone)
    );
    stakeToken.cooldownOnBehalfOf(user);
  }

  function test_cooldownZeroAmount() public {
    vm.startPrank(user);

    vm.expectRevert(abi.encodeWithSelector(IStakeToken.ZeroBalanceInStaking.selector));
    stakeToken.cooldown();
  }
}
