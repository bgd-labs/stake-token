// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {OwnableUpgradeable} from 'openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol';
import {PausableUpgradeable} from 'openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol';

import {StakeTestBase} from './utils/StakeTestBase.sol';

contract PauseTests is StakeTestBase {
  function test_setPauseByAdmin() external {
    assertEq(PausableUpgradeable(address(stakeToken)).paused(), false);

    vm.startPrank(admin);

    stakeToken.pause();

    assertEq(PausableUpgradeable(address(stakeToken)).paused(), true);

    stakeToken.unpause();

    assertEq(PausableUpgradeable(address(stakeToken)).paused(), false);
  }

  function test_setPauseNotByAdmin(address anyone) external {
    vm.assume(anyone != admin);

    assertEq(PausableUpgradeable(address(stakeToken)).paused(), false);

    vm.startPrank(anyone);

    vm.expectRevert(
      abi.encodeWithSelector(
        OwnableUpgradeable.OwnableUnauthorizedAccount.selector,
        address(anyone)
      )
    );
    stakeToken.pause();
  }

  function test_shouldRevertWhenPauseIsActive() external {
    _deposit(1e18, user, user);
    _dealUnderlying(1e18, user);

    vm.startPrank(user);

    stakeToken.cooldown();
    stakeToken.approve(someone, 1000);
    underlying.approve(address(stakeToken), 1e18);

    skip(stakeToken.getCooldown());

    vm.stopPrank();
    vm.startPrank(admin);

    stakeToken.pause();

    vm.stopPrank();
    vm.startPrank(someone);

    vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
    stakeToken.cooldownOnBehalfOf(user);

    vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
    stakeToken.transferFrom(user, someone, 1);

    vm.stopPrank();
    vm.startPrank(user);

    vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
    stakeToken.cooldown();

    vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
    stakeToken.deposit(1, user);

    vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
    stakeToken.mint(1, user);

    vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
    stakeToken.redeem(1, user, user);

    vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
    stakeToken.withdraw(1, user, user);

    vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
    stakeToken.transfer(someone, 1);

    vm.stopPrank();
    vm.startPrank(admin);

    vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
    stakeToken.slash(someone, 1);
  }
}
