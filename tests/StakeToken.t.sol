// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {StakeToken} from '../src/contracts/StakeToken.sol';
import {ERC20} from 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import {ProxyAdmin} from 'openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {IERC20Errors} from 'openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol';
import {StkTestUtils} from './StkTestUtils.t.sol';

contract StakeTokenTest is StkTestUtils {
  function setUp() public {
    _initializeStkToken(3000);
  }

  function test_totalAssets() public {
    uint64 stakeAmount = 10 ether;
    uint64 slashAmount = 1 ether;
    assertEq(stakeToken.totalAssets(), 0);
    _stake(stakeAmount, USER);
    assertEq(stakeToken.totalAssets(), stakeAmount, 'WRONG_AMOUNT_STAKED');
    _slash(USER, slashAmount);
    assertEq(stakeToken.totalAssets(), stakeAmount - slashAmount);
  }
}
