// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {StakeToken} from '../src/contracts/StakeToken.sol';
import {ERC20} from 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import {ProxyAdmin} from 'openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {IERC20Errors} from 'openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol';
import {PausableUpgradeable} from 'openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol';
import {StakeTestBase} from './utils/StakeTestBase.sol';

contract PauseTests is StakeTestBase {
  function test_setPauseByGuardian() external {
    assertEq(PausableUpgradeable(address(stakeToken)).paused(), false);

    vm.startPrank(guardian);

    stakeToken.setPause(true);

    assertEq(PausableUpgradeable(address(stakeToken)).paused(), true);

    stakeToken.setPause(false);

    assertEq(PausableUpgradeable(address(stakeToken)).paused(), false);
  }

  function test_setPauseByAdmin() external {
    assertEq(PausableUpgradeable(address(stakeToken)).paused(), false);

    vm.startPrank(admin);

    stakeToken.setPause(true);

    assertEq(PausableUpgradeable(address(stakeToken)).paused(), true);

    stakeToken.setPause(false);

    assertEq(PausableUpgradeable(address(stakeToken)).paused(), false);
  }

  function test_shouldRevertWhenPauseIsActive() external {
    _deposit(1e18, user, user);
    _dealUnderlying(1e18, user);

    vm.startPrank(user);

    stakeToken.cooldown();
    stakeToken.approve(someone, 1000);
    underlying.approve(address(stakeToken), 1e18);

    skip(stakeToken.getCooldownSeconds());

    vm.stopPrank();
    vm.startPrank(admin);

    stakeToken.setPause(true);

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
    vm.startPrank(slashingAdmin);

    vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
    stakeToken.slash(someone, 1);
  }
}
