// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {StakeToken} from '../src/contracts/StakeToken.sol';
import {ERC20} from 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import {ProxyAdmin} from 'openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {IERC20Errors} from 'openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol';
import {PausableUpgradeable} from 'openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol';
import {StkTestUtils} from './StkTestUtils.t.sol';

contract Pause is StkTestUtils {
  function test_setPaused() external {
    assertEq(stakeToken.paused(), false);
    _setPaused(true);
    assertEq(stakeToken.paused(), true);
    _setPaused(false);
    assertEq(stakeToken.paused(), false);
  }

  function test_cooldown_should_revert() external {
    _setPaused(true);

    vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
    stakeToken.cooldown();
  }

  function test_stake_should_revert() external {
    _setPaused(true);

    vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
    vm.prank(USER);
    stakeToken.stake(USER, 0);
  }

  function test_stakeWithPermit_should_revert() external {
    _setPaused(true);

    vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
    vm.prank(USER);
    stakeToken.stakeWithPermit(0, 0, 0, bytes32(0), bytes32(0));
  }

  function test_redeem_should_revert() external {
    _setPaused(true);
    vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
    _redeem(1 ether, USER, USER);
  }

  function test_redeemOnBehalf_should_revert() external {
    _setPaused(true);
    vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
    stakeToken.redeemOnBehalf(USER, USER, 1 ether);
  }

  function test_slash_should_revert() external {
    _setPaused(true);
    vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
    _slash(USER, 1 ether);
  }

  function test_transfer_should_revert() external {
      _stake(1 ether, USER);
      _setPaused(true);

      vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
      vm.prank(USER);
      stakeToken.transfer(USER, 1 ether);
  }

  function _setPaused(bool paused) internal {
    vm.prank(admin);
    stakeToken.setPaused(paused);
  }
}
