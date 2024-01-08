// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {StakeToken, IStakeToken} from '../src/contracts/StakeToken.sol';
import {ERC20} from 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import {ProxyAdmin} from 'openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {StkTestUtils} from './StkTestUtils.t.sol';

contract Slashing is StkTestUtils {
  function setUp() public {
    _initializeStkToken(3000);
  }

  /**
   * Set max slashing should properly set max slashing
   */
  function test_setMaxSlashingTo9999bps() public {
    vm.startPrank(admin);
    stakeToken.setMaxSlashablePercentage(9999);
    vm.stopPrank();

    assertEq(stakeToken.getMaxSlashablePercentage(), 9999);
  }

  /**
   * Setting max slashing should revert when not being called as admin
   */
  function test_setMaxSlashingNonAdmin_shouldRevert() public {
    try stakeToken.setMaxSlashablePercentage(10000) {} catch Error(string memory reason) {
      require(keccak256(bytes(reason)) == keccak256(bytes('CALLER_NOT_SLASHING_ADMIN')));
    }
  }

  /**
   * Setting max slashing should revert when setting >= 100%
   */
  function test_setMaxSlashingGe10000bps_shouldRevert() public {
    vm.startPrank(admin);
    try stakeToken.setMaxSlashablePercentage(10000) {} catch Error(string memory reason) {
      require(keccak256(bytes(reason)) == keccak256(bytes('INVALID_SLASHING_PERCENTAGE')));
    }

    try stakeToken.setMaxSlashablePercentage(10001) {} catch Error(string memory reason) {
      require(keccak256(bytes(reason)) == keccak256(bytes('INVALID_SLASHING_PERCENTAGE')));
    }
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
   * As max slashing is set to 3000 bps, a maximum of 30% should be slashed
   */
  function test_slash4000bps() public {
    address destination = vm.addr(100);
    _stake(100 ether, USER);
    _slash(destination, 40 ether);

    assertEq(underlyingToken.balanceOf(destination), 30 ether);
    assertApproxEqAbs(stakeToken.getExchangeRate(), 1.428 ether, 0.001 ether);
  }

  /**
   * After a slashing occured, redemption should be possible immediately
   */
  function test_redeemAfterSlash() public {
    address destination = vm.addr(100);
    _stake(100 ether, USER);
    _slash(destination, 20 ether);
    _redeem(100 ether, USER, USER);
    assertEq(underlyingToken.balanceOf(USER), 80 ether);
  }

  /**
   * After a slashing occured, redemption should be possible immediately
   * even with a pending cooldown everything should be redeemable
   */
  function test_redeemAfterSlash_pendingCooldown(
    uint256 initialStake,
    uint256 stakeAfterCooldown,
    uint256 amountToRedeem
  ) public {
    vm.assume(
      initialStake < type(uint104).max &&
        stakeAfterCooldown < type(uint104).max &&
        initialStake + stakeAfterCooldown < type(uint104).max
    );
    vm.assume(initialStake + stakeAfterCooldown >= amountToRedeem);
    vm.assume(amountToRedeem != 0);
    vm.assume(initialStake > 0);
    vm.assume(stakeAfterCooldown > 0);
    vm.assume(initialStake + stakeAfterCooldown > 5 ether);

    address destination = vm.addr(100);
    _stake(initialStake, USER);
    vm.prank(USER);
    stakeToken.cooldown();
    vm.warp(block.timestamp + stakeToken.getCooldownSeconds() + 1);
    _stake(stakeAfterCooldown, USER);
    _slash(destination, (initialStake + stakeAfterCooldown) / 5); // ~20%
    _redeem(amountToRedeem, USER, USER);

    (uint40 timestamp, uint216 amount) = stakeToken.stakersCooldowns(USER);
    assertApproxEqAbs(underlyingToken.balanceOf(USER), (uint256(amountToRedeem) * 80) / 100, 100);
    if (amountToRedeem < initialStake) {
      assertEq(timestamp != 0, true);
      assertEq(amount, initialStake - amountToRedeem);
    } else {
      assertEq(timestamp, 0, 'TIMESTAMP_NOT_ZERO');
      assertEq(amount, 0, 'AMOUNT_NON_ZERO');
    }
  }

  /**
   * After a slashing is settled cooldown mechanics should revert to defaul
   */
  function test_redeemAfterSlashingSettled() public {
    address destination = vm.addr(100);
    _stake(100 ether, USER);
    _slash(destination, 20 ether);
    _settleSlashing();

    vm.startPrank(USER);
    vm.expectRevert('INSUFFICIENT_COOLDOWN');
    stakeToken.redeem(USER, 100 ether);
    stakeToken.cooldown();
    vm.warp(block.timestamp + stakeToken.getCooldownSeconds());
    stakeToken.redeem(USER, 100 ether);
    assertEq(underlyingToken.balanceOf(USER), 80 ether);
  }

  /**
   * Staking after slash should properly incorporate the exchangeRate and adjust the stake token received
   */
  function test_stakeAfterSlash() public {
    address destination = vm.addr(100);
    _stake(100 ether, USER);
    _slash(destination, 20 ether);
    _settleSlashing();

    address newUser = vm.addr(1000);
    _stake(100 ether, newUser);
    assertEq(stakeToken.balanceOf(newUser), 125 ether);
  }

  function test_changeSlashingAdmin() public {
    address newUser = vm.addr(1000);
    try stakeToken.setPendingAdmin(stakeToken.SLASH_ADMIN_ROLE(), newUser) {} catch Error(
      string memory reason
    ) {
      require(keccak256(bytes(reason)) == keccak256(bytes('CALLER_NOT_ROLE_ADMIN')));
    }
    vm.startPrank(admin);
    stakeToken.setPendingAdmin(stakeToken.SLASH_ADMIN_ROLE(), newUser);
    vm.startPrank(newUser);
    stakeToken.claimRoleAdmin(stakeToken.SLASH_ADMIN_ROLE());
  }

  /**
   * The exchangeRate should positively reflect when funds are returned to the stk
   */
  function test_returnFunds() public {
    _stake(100 ether, USER);

    uint256 amount = 100 ether;
    deal(address(underlyingToken), address(this), amount);
    underlyingToken.approve(address(stakeToken), amount);
    stakeToken.returnFunds(amount);

    assertEq(stakeToken.getExchangeRate(), 0.5 ether);
  }

  /**
   * Return funds should revert when there are <1 shares
   */
  function test_returnFundsSharesLtBound_shouldRevert() public {
    _stake(1 ether - 1, USER);

    uint256 amount = 100 ether;
    deal(address(underlyingToken), address(this), amount);
    underlyingToken.approve(address(stakeToken), amount);

    vm.expectRevert('SHARES_LT_MINIMUM');
    stakeToken.returnFunds(amount);
  }

  /**
   * Return funds should revert when amoutn returned is smaller 1 unit
   */
  function test_returnFundsAmountLtBound_shouldRevert() public {
    uint256 amount = 0.5 ether;
    deal(address(underlyingToken), address(this), amount);
    underlyingToken.approve(address(stakeToken), amount);

    vm.expectRevert('AMOUNT_LT_MINIMUM');
    stakeToken.returnFunds(amount);
  }
}
