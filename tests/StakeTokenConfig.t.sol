// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {StakeToken} from '../src/contracts/StakeToken.sol';
import {IStakeToken} from '../src/contracts/interfaces/IStakeToken.sol';

import {ERC4626Upgradeable} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol';

import {ERC20} from 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import {ProxyAdmin} from 'openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';

import {StakeTestBase} from './utils/StakeTestBase.sol';

contract StakeTokenConfigTests is StakeTestBase {
  function test_setCooldown(uint32 cooldown) public {
    vm.startPrank(admin);

    stakeToken.setCooldown(cooldown);

    assertEq(stakeToken.getCooldown(), cooldown);
  }

  function test_setUnstakeWindow(uint32 unstakeWindow) public {
    vm.startPrank(admin);

    stakeToken.setUnstakeWindow(unstakeWindow);

    assertEq(stakeToken.getUnstakeWindow(), unstakeWindow);
  }

  function test_decimals() public view {
    assertEq(stakeToken.decimals(), 18);
  }
}
