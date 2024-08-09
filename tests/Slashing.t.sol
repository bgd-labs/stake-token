// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {StakeToken, IStakeToken} from '../src/contracts/StakeToken.sol';
import {ERC20} from 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import {ProxyAdmin} from 'openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {OwnableUpgradeable} from 'openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol';
import {StakeTestBase} from './utils/StakeTestBase.sol';

contract Slashing is StakeTestBase {
  function test_slash_shouldRevertWithWrongCaller(address caller) external {
    vm.assume(caller != address(proxyAdmin) && caller != slashingAdmin);
    address destination = vm.addr(100);

    vm.startPrank(caller);
    vm.expectRevert(abi.encodeWithSelector(IStakeToken.OnlySlashingAdmin.selector, caller));
    stakeToken.slash(destination, type(uint256).max);
  }

  function test_slash_shouldRevertWithAmountZero() public {
    address destination = vm.addr(100);

    vm.startPrank(slashingAdmin);
    vm.expectRevert(abi.encodeWithSelector(IStakeToken.ZeroAmount.selector));
    stakeToken.slash(destination, 0);
  }

  function test_slash_shouldRevertWithFundsLteMinimum(uint256 amount) public {
    vm.assume(amount != 0 && amount <= stakeToken.MIN_ASSETS_REMAINING());
    address destination = vm.addr(100);
    _stake(amount, user);

    vm.startPrank(slashingAdmin);
    vm.expectRevert(abi.encodeWithSelector(IStakeToken.NoFundsAvailable.selector));
    stakeToken.slash(destination, type(uint256).max);
  }

  /**
   * Slashing 20% of funds should change the exchangeRate accordingly
   */
  function test_slash2000bps() public {
    address destination = vm.addr(100);
    _stake(100 ether, user);
    _slash(destination, 20 ether);

    assertEq(underlying.balanceOf(destination), 20 ether);
    assertEq(stakeToken.getExchangeRate(), 1.25 ether);
  }

  /**
   * Staking after slash should properly incorporate the exchangeRate and adjust the stake token received
   */
  function test_stakeAfterSlash() public {
    address destination = vm.addr(100);
    _stake(100 ether, user);
    _slash(destination, 20 ether);

    address newUser = vm.addr(1000);
    _stake(100 ether, newUser);
    assertEq(stakeToken.balanceOf(newUser), 125 ether);
  }
}
