// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {StakeToken} from '../src/contracts/StakeToken.sol';
import {IStakeToken} from '../src/contracts/interfaces/IStakeToken.sol';

import {ERC4626Upgradeable} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol';

import {ERC20} from 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import {ProxyAdmin} from 'openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';

import {StakeTestBase} from './utils/StakeTestBase.sol';

contract Cooldown is StakeTestBase {
  function test_cooldown(uint224 amountToStake, uint224 amountToRedeem) public {
    vm.assume(amountToStake > amountToRedeem && amountToRedeem > 0);

    _deposit(amountToStake, user, user);

    vm.startPrank(user);

    stakeToken.cooldown();
    IStakeToken.CooldownSnapshot memory snapshotBefore = stakeToken.getStakerCooldown(user);

    assertEq(snapshotBefore.timestamp, block.timestamp + stakeToken.getCooldownSeconds());
    assertEq(snapshotBefore.amount, amountToStake);

    skip(stakeToken.getCooldownSeconds());

    stakeToken.withdraw(amountToRedeem, user, user);

    IStakeToken.CooldownSnapshot memory snapshotAfter = stakeToken.getStakerCooldown(user);

    assertEq(snapshotAfter.amount, amountToStake - amountToRedeem);
    assertEq(snapshotAfter.timestamp, snapshotBefore.timestamp);
  }

  function test_cooldownNoIncreaseInAmount(uint224 amountToStake, uint224 amountToTopUp) public {
    vm.assume(
      amountToStake > 0 && amountToTopUp > 0 && type(uint224).max - amountToStake > amountToTopUp
    );

    _deposit(amountToStake, user, user);

    vm.startPrank(user);
    stakeToken.cooldown();

    IStakeToken.CooldownSnapshot memory snapshotBefore = stakeToken.getStakerCooldown(user);

    _deposit(amountToTopUp, user, user);

    IStakeToken.CooldownSnapshot memory snapshotAfter = stakeToken.getStakerCooldown(user);

    assertEq(snapshotBefore.timestamp, snapshotAfter.timestamp);
    assertEq(snapshotBefore.amount, snapshotAfter.amount);

    assertEq(snapshotAfter.timestamp, block.timestamp + stakeToken.getCooldownSeconds());
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

    assertEq(snapshotAfterSecondTopUp.timestamp, block.timestamp + stakeToken.getCooldownSeconds());
    assertEq(snapshotAfterSecondTopUp.amount, amountToStake);
  }

  function test_cooldownChangeOnTransfer(uint224 amountToStake, uint224 amountToTransfer) public {
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

  function test_cooldownChangeOnRedeem(uint224 amountToStake, uint224 amountToRedeem) public {
    vm.assume(amountToStake > 0);
    vm.assume(amountToRedeem > 0 && amountToStake > amountToRedeem);

    _deposit(amountToStake, user, user);

    vm.startPrank(user);
    stakeToken.cooldown();

    IStakeToken.CooldownSnapshot memory snapshot0 = stakeToken.getStakerCooldown(user);

    skip(stakeToken.getCooldownSeconds());

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
    uint224 amountToStake,
    uint32 secondsAfterCooldownActivation
  ) public {
    vm.assume(amountToStake > 0);
    vm.assume(secondsAfterCooldownActivation < stakeToken.getCooldownSeconds());

    _deposit(amountToStake, user, user);

    vm.startPrank(user);
    stakeToken.cooldown();

    skip(secondsAfterCooldownActivation);

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

  function test_cooldownWindowClosed(
    uint224 amountToStake,
    uint32 secondsGreaterThanNeeded
  ) public {
    vm.assume(amountToStake > 0);
    vm.assume(
      secondsGreaterThanNeeded > stakeToken.getCooldownSeconds() + stakeToken.getUnstakeWindow()
    );

    _deposit(amountToStake, user, user);

    vm.startPrank(user);

    stakeToken.cooldown();

    skip(secondsGreaterThanNeeded);

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
}
