// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {StakeToken, IStakeToken} from '../src/contracts/StakeToken.sol';
import {ERC20} from 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import {ProxyAdmin} from 'openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {StkTestUtils} from './StkTestUtils.t.sol';
import {OwnableUpgradeable} from 'openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol';

contract Slashing is StkTestUtils {
  function setUp() public {
    _initializeStkToken(3000);
  }

  /**
   * Slashing below 1 unit of assets should be impossible
   */
  function test_slash9999bps() public {
    address destination = vm.addr(100);
    _stake(50 ether, USER);

    vm.startPrank(admin);
    try stakeToken.slash(destination, 45.5 ether) {} catch Error(string memory reason) {
      require(keccak256(bytes(reason)) == keccak256(bytes('REMAINING_LT_MINIMUM')));
    }
  }

  /**
   * Slashing 20% of funds should change the exchangeRate accordingly
   */
  function test_slash2000bps() public {
    address destination = vm.addr(100);
    _stake(100 ether, USER);
    _slash(destination, 20 ether);

    assertEq(underlyingToken.balanceOf(destination), 20 ether);
    assertEq(stakeToken.getExchangeRate(), 1.25 ether);
  }

  /**
   * Staking after slash should properly incorporate the exchangeRate and adjust the stake token received
   */
  function test_stakeAfterSlash() public {
    address destination = vm.addr(100);
    _stake(100 ether, USER);
    _slash(destination, 20 ether);

    address newUser = vm.addr(1000);
    _stake(100 ether, newUser);
    assertEq(stakeToken.balanceOf(newUser), 125 ether);
  }

  function test_changeSlashingAdmin() public {
    address newUser = vm.addr(1000);
    vm.expectRevert(
      abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, address(this))
    );
    stakeToken.setSlashingAdmin(newUser);
    vm.startPrank(admin);
    stakeToken.setSlashingAdmin(newUser);
  }
}
