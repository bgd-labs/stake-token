// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {StakeToken} from '../src/contracts/StakeToken.sol';
import {ERC20} from 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import {ProxyAdmin} from 'openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {IERC20Errors} from 'openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol';
import {StkTestUtils} from './StkTestUtils.t.sol';

contract Pause is StkTestUtils {
  function test_cooldown_should_revert() external {
    _setPaused(true);

    vm.expectRevert('PAUSED');
    stakeToken.cooldown();
  }

  function test_stake_should_revert() external {
    _setPaused(true);

    vm.expectRevert('PAUSED');
    vm.prank(USER);
    stakeToken.stake(USER, 1 ether);
  }

  function test_redeem_should_revert() external {
    _setPaused(true);
    vm.expectRevert('PAUSED');
    _redeem(1 ether, USER, USER);
  }

  function test_slash_should_revert() external {
    _setPaused(true);
    vm.expectRevert('PAUSED');
    _slash(USER, 1 ether);
  }

  function _setPaused(bool paused) internal {
    vm.prank(admin);
    stakeToken.setPaused(paused);
  }
}
