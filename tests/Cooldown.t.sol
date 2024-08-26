// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ERC4626Upgradeable} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol';

import {IERC4626StakeToken} from 'src/contracts/interfaces/IERC4626StakeToken.sol';

import {StakeTestBase} from './utils/StakeTestBase.sol';

contract CooldownTests is StakeTestBase {
  function test_cooldown(uint192 amountToStake, uint192 amountToWithdraw) public {
    vm.assume(amountToStake > amountToWithdraw && amountToWithdraw > 0);

    _deposit(amountToStake, user, user);

    vm.startPrank(user);

    stakeToken.cooldown();
    IERC4626StakeToken.CooldownSnapshot memory snapshotBefore = stakeToken.getStakerCooldown(user);

    assertEq(snapshotBefore.timestamp, block.timestamp + stakeToken.getCooldown());
    assertEq(snapshotBefore.amount, stakeToken.convertToShares(amountToStake));

    skip(stakeToken.getCooldown());

    stakeToken.withdraw(amountToWithdraw, user, user);

    IERC4626StakeToken.CooldownSnapshot memory snapshotAfter = stakeToken.getStakerCooldown(user);

    assertEq(snapshotAfter.amount, stakeToken.convertToShares(amountToStake - amountToWithdraw));
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

    IERC4626StakeToken.CooldownSnapshot memory snapshotBefore = stakeToken.getStakerCooldown(user);

    _deposit(amountToTopUp, user, user);

    IERC4626StakeToken.CooldownSnapshot memory snapshotAfter = stakeToken.getStakerCooldown(user);

    assertEq(snapshotBefore.timestamp, snapshotAfter.timestamp);
    assertEq(snapshotBefore.amount, snapshotAfter.amount);

    assertEq(snapshotAfter.timestamp, block.timestamp + stakeToken.getCooldown());
    assertEq(snapshotAfter.amount, stakeToken.convertToShares(amountToStake));

    _deposit(amountToTopUp, someone, someone);

    vm.stopPrank();
    vm.startPrank(someone);

    stakeToken.transfer(user, stakeToken.convertToShares(amountToTopUp));

    IERC4626StakeToken.CooldownSnapshot memory snapshotAfterSecondTopUp = stakeToken
      .getStakerCooldown(user);

    assertEq(snapshotBefore.timestamp, snapshotAfterSecondTopUp.timestamp);
    assertEq(snapshotBefore.amount, snapshotAfterSecondTopUp.amount);

    assertEq(snapshotAfterSecondTopUp.timestamp, block.timestamp + stakeToken.getCooldown());
    assertEq(snapshotAfterSecondTopUp.amount, stakeToken.convertToShares(amountToStake));
  }

  function test_cooldownChangeOnTransfer(uint192 amountToStake, uint224 sharesToTransfer) public {
    vm.assume(stakeToken.convertToShares(amountToStake) > sharesToTransfer && sharesToTransfer > 0);

    _deposit(amountToStake, user, user);

    vm.startPrank(user);
    stakeToken.cooldown();

    IERC4626StakeToken.CooldownSnapshot memory snapshot0 = stakeToken.getStakerCooldown(user);

    stakeToken.transfer(someone, sharesToTransfer);

    IERC4626StakeToken.CooldownSnapshot memory snapshot1 = stakeToken.getStakerCooldown(user);

    assertEq(snapshot0.timestamp, snapshot1.timestamp);
    assertEq(snapshot0.amount, snapshot1.amount + sharesToTransfer);

    stakeToken.transfer(someone, stakeToken.balanceOf(user));

    IERC4626StakeToken.CooldownSnapshot memory snapshot2 = stakeToken.getStakerCooldown(user);

    assertEq(snapshot2.timestamp, 0);
    assertEq(snapshot2.amount, 0);
  }

  function test_cooldownChangeOnRedeem(uint192 amountToStake, uint224 sharesToRedeem) public {
    vm.assume(stakeToken.convertToShares(amountToStake) > sharesToRedeem && sharesToRedeem > 0);

    _deposit(amountToStake, user, user);

    vm.startPrank(user);
    stakeToken.cooldown();

    IERC4626StakeToken.CooldownSnapshot memory snapshot0 = stakeToken.getStakerCooldown(user);

    skip(stakeToken.getCooldown());

    stakeToken.redeem(sharesToRedeem, user, user);

    IERC4626StakeToken.CooldownSnapshot memory snapshot1 = stakeToken.getStakerCooldown(user);

    assertEq(snapshot0.timestamp, snapshot1.timestamp);
    assertEq(snapshot0.amount, snapshot1.amount + sharesToRedeem);

    stakeToken.redeem(stakeToken.balanceOf(user), user, user);

    IERC4626StakeToken.CooldownSnapshot memory snapshot2 = stakeToken.getStakerCooldown(user);

    assertEq(snapshot2.timestamp, 0);
    assertEq(snapshot2.amount, 0);
  }

  function test_cooldownInsufficientTime(
    uint192 amountToStake,
    uint32 afterCooldownActivation
  ) public {
    vm.assume(amountToStake > 0);
    vm.assume(afterCooldownActivation < stakeToken.getCooldown());

    _deposit(amountToStake, user, user);

    vm.startPrank(user);
    stakeToken.cooldown();

    skip(afterCooldownActivation);

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

  function test_cooldownWindowClosed(uint192 amountToStake, uint32 greaterThanNeeded) public {
    vm.assume(amountToStake > 0);
    vm.assume(greaterThanNeeded > stakeToken.getCooldown() + stakeToken.getUnstakeWindow());

    _deposit(amountToStake, user, user);

    vm.startPrank(user);

    stakeToken.cooldown();

    skip(greaterThanNeeded);

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

  function test_cooldownOnBehalf(uint192 amountToStake, uint224 sharesToRedeem) public {
    vm.assume(stakeToken.convertToShares(amountToStake) > sharesToRedeem && sharesToRedeem > 0);

    _deposit(amountToStake, user, user);

    vm.startPrank(user);

    stakeToken.approve(someone, stakeToken.convertToShares(amountToStake));

    vm.stopPrank();
    vm.startPrank(someone);

    stakeToken.cooldownOnBehalfOf(user);

    IERC4626StakeToken.CooldownSnapshot memory snapshotBefore = stakeToken.getStakerCooldown(user);

    assertEq(snapshotBefore.timestamp, block.timestamp + stakeToken.getCooldown());
    assertEq(snapshotBefore.amount, stakeToken.convertToShares(amountToStake));

    skip(stakeToken.getCooldown());

    stakeToken.redeem(sharesToRedeem, someone, user);

    IERC4626StakeToken.CooldownSnapshot memory snapshotAfter = stakeToken.getStakerCooldown(user);

    assertEq(snapshotAfter.amount + sharesToRedeem, snapshotBefore.amount);
    assertEq(snapshotAfter.timestamp, snapshotBefore.timestamp);
  }

  function test_cooldownOnBehalfNotApproved(uint192 amountToStake) public {
    vm.assume(amountToStake > 0);

    _deposit(amountToStake, user, user);

    vm.startPrank(someone);

    vm.expectRevert(
      abi.encodeWithSelector(IERC4626StakeToken.NotApprovedForCooldown.selector, user, someone)
    );
    stakeToken.cooldownOnBehalfOf(user);
  }

  function test_cooldownZeroAmount() public {
    vm.startPrank(user);

    vm.expectRevert(abi.encodeWithSelector(IERC4626StakeToken.ZeroBalanceInStaking.selector));
    stakeToken.cooldown();
  }
}
