// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {StakeToken} from '../../src/contracts/StakeToken.sol';
import {IStakeToken} from '../../src/contracts/interfaces/IStakeToken.sol';

import {IERC20Errors} from 'openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {ERC20} from 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import {ProxyAdmin} from 'openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {StkTestUtils} from '../StkTestUtils.t.sol';

contract Cooldown is StkTestUtils {
  function test_maxWithdraw(uint104 amountToStake, address user) public {
    vm.assume(amountToStake > 0);
    vm.assume(user != address(proxyAdmin) && user != address(0));

    _stake(amountToStake, user);

    uint256 zeroAssetsDueToCooldown = stakeToken.maxWithdraw(user);
    assertEq(zeroAssetsDueToCooldown, 0);

    vm.startPrank(user);
    stakeToken.cooldown();

    uint256 allAssets = stakeToken.maxWithdraw(user);
    assertEq(amountToStake, allAssets);
  }

  function test_maxRedeem(uint104 amountToStake, address user) public {
    vm.assume(amountToStake > 0);
    vm.assume(user != address(proxyAdmin) && user != address(0));

    uint256 sharesToMint = stakeToken.convertToShares(amountToStake);
    _stake(amountToStake, user);

    uint256 zeroSharesDueToCooldown = stakeToken.maxRedeem(user);
    assertEq(zeroSharesDueToCooldown, 0);

    vm.startPrank(user);
    stakeToken.cooldown();

    uint256 allShares = stakeToken.maxWithdraw(user);
    assertEq(allShares, sharesToMint);
  }

  // Due to default 1e18 exchange rate there's no rounding here at all, so I checked these values striclty
  function test_previewFunctions(uint104 assets) public view {
    uint256 shares = stakeToken.convertToShares(assets);

    uint256 previewDeposit = stakeToken.previewDeposit(assets);
    assertEq(previewDeposit, shares);

    uint256 previewMint = stakeToken.previewMint(shares);
    assertEq(previewMint, assets);

    uint256 previewWithdraw = stakeToken.previewWithdraw(assets);
    assertEq(previewWithdraw, shares);

    uint256 previewRedeem = stakeToken.previewRedeem(shares);
    assertEq(previewRedeem, assets);
  }

  function test_deposit(uint104 amount, address user) public {
    vm.assume(amount > 0);
    vm.assume(user != address(proxyAdmin) && user != address(0));

    deal(address(underlyingToken), user, amount);
    vm.startPrank(user);
    underlyingToken.approve(address(stakeToken), amount);

    uint256 numberOfShares = stakeToken.deposit(amount, user);
    vm.stopPrank();

    assertEq(stakeToken.totalAssets(), amount);
    assertEq(stakeToken.totalAssets(), stakeToken.balanceOf(user));

    assertEq(stakeToken.totalSupply(), numberOfShares);
  }

  function test_mint(uint104 amount, address user) public {
    vm.assume(amount > 0);
    vm.assume(user != address(proxyAdmin) && user != address(0));

    uint256 shares = stakeToken.convertToShares(amount);

    deal(address(underlyingToken), user, amount);
    vm.startPrank(user);
    underlyingToken.approve(address(stakeToken), amount);

    stakeToken.mint(shares, user);
    vm.stopPrank();

    assertEq(stakeToken.totalAssets(), amount);
    assertEq(stakeToken.totalAssets(), stakeToken.balanceOf(user));

    assertEq(stakeToken.totalSupply(), shares);
  }

  function test_redeem(uint104 amountStaked, uint104 amountRedeemed, address user) public {
    vm.assume(amountStaked > 0);
    vm.assume(amountRedeemed != 0 && amountRedeemed <= amountStaked);
    vm.assume(user != address(proxyAdmin) && user != address(0));

    address destination = vm.addr(100);
    uint256 shares = stakeToken.convertToShares(amountStaked);
    uint256 sharesToRedeem = stakeToken.convertToShares(amountRedeemed);

    _stake(amountStaked, user);
    assertEq(stakeToken.balanceOf(user), shares);

    vm.prank(user);
    stakeToken.cooldown();
    vm.warp(block.timestamp + stakeToken.getCooldownSeconds());

    vm.startPrank(user);
    stakeToken.redeem(sharesToRedeem, destination, user);
    vm.stopPrank();

    assertEq(stakeToken.totalAssets(), amountStaked - amountRedeemed);
    assertEq(stakeToken.balanceOf(user), stakeToken.convertToShares(amountStaked - amountRedeemed));

    assertEq(stakeToken.totalSupply(), stakeToken.balanceOf(user));
    assertEq(underlyingToken.balanceOf(destination), amountRedeemed);
  }

  function test_redeemWithApprove(
    uint104 amountStaked,
    uint104 amountRedeemed,
    address user
  ) public {
    vm.assume(amountStaked > 0);
    vm.assume(amountRedeemed != 0 && amountRedeemed <= amountStaked);
    vm.assume(user != address(proxyAdmin) && user != address(0) && user != USER);

    address destination = vm.addr(100);
    uint256 shares = stakeToken.convertToShares(amountStaked);
    uint256 sharesToRedeem = stakeToken.convertToShares(amountRedeemed);

    _stake(amountStaked, user);
    assertEq(stakeToken.balanceOf(user), shares);

    vm.prank(user);
    stakeToken.cooldown();
    vm.warp(block.timestamp + stakeToken.getCooldownSeconds());

    vm.startPrank(user);
    stakeToken.approve(USER, sharesToRedeem);
    vm.stopPrank();

    vm.startPrank(USER);
    stakeToken.redeem(sharesToRedeem, destination, user);
    vm.stopPrank();

    assertEq(stakeToken.totalAssets(), amountStaked - amountRedeemed);
    assertEq(stakeToken.balanceOf(user), stakeToken.convertToShares(amountStaked - amountRedeemed));

    assertEq(stakeToken.totalSupply(), stakeToken.balanceOf(user));
    assertEq(underlyingToken.balanceOf(destination), amountRedeemed);
  }

  function test_redeemWithoutApprove(
    uint104 amountStaked,
    uint104 amountRedeemed,
    address user
  ) public {
    vm.assume(amountStaked > 0);
    vm.assume(amountRedeemed != 0 && amountRedeemed <= amountStaked);
    vm.assume(user != address(proxyAdmin) && user != address(0) && user != USER);

    address destination = vm.addr(100);
    uint256 shares = stakeToken.convertToShares(amountStaked);
    uint256 sharesToRedeem = stakeToken.convertToShares(amountRedeemed);

    _stake(amountStaked, user);
    assertEq(stakeToken.balanceOf(user), shares);

    vm.prank(user);
    stakeToken.cooldown();
    vm.warp(block.timestamp + stakeToken.getCooldownSeconds());

    vm.startPrank(USER);
    vm.expectRevert(
      abi.encodeWithSelector(
        IERC20Errors.ERC20InsufficientAllowance.selector,
        address(USER),
        0,
        sharesToRedeem
      )
    );
    stakeToken.redeem(sharesToRedeem, destination, user);
  }

  function test_withdraw(uint104 amountStaked, uint104 amountRedeemed, address user) public {
    vm.assume(amountStaked > 0);
    vm.assume(amountRedeemed != 0 && amountRedeemed <= amountStaked);
    vm.assume(user != address(proxyAdmin) && user != address(0));

    address destination = vm.addr(100);
    uint256 shares = stakeToken.convertToShares(amountStaked);

    _stake(amountStaked, user);
    assertEq(stakeToken.balanceOf(user), shares);

    vm.startPrank(user);
    stakeToken.cooldown();
    vm.warp(block.timestamp + stakeToken.getCooldownSeconds());
    stakeToken.withdraw(amountRedeemed, destination, user);
    vm.stopPrank();

    assertEq(stakeToken.totalAssets(), amountStaked - amountRedeemed);
    assertEq(stakeToken.balanceOf(user), stakeToken.convertToShares(amountStaked - amountRedeemed));

    assertEq(stakeToken.totalSupply(), stakeToken.balanceOf(user));
    assertEq(underlyingToken.balanceOf(destination), amountRedeemed);
  }

  function test_withdrawWithApprove(
    uint104 amountStaked,
    uint104 amountRedeemed,
    address user
  ) public {
    vm.assume(amountStaked > 0);
    vm.assume(amountRedeemed != 0 && amountRedeemed <= amountStaked);
    vm.assume(user != address(proxyAdmin) && user != address(0) && user != USER);

    address destination = vm.addr(100);
    uint256 shares = stakeToken.convertToShares(amountStaked);
    uint256 sharesToRedeem = stakeToken.convertToShares(amountRedeemed);

    _stake(amountStaked, user);
    assertEq(stakeToken.balanceOf(user), shares);

    vm.prank(user);
    stakeToken.cooldown();
    vm.warp(block.timestamp + stakeToken.getCooldownSeconds());

    vm.startPrank(user);
    stakeToken.approve(USER, sharesToRedeem);
    vm.stopPrank();

    vm.startPrank(USER);
    stakeToken.withdraw(amountRedeemed, destination, user);
    vm.stopPrank();

    assertEq(stakeToken.totalAssets(), amountStaked - amountRedeemed);
    assertEq(stakeToken.balanceOf(user), stakeToken.convertToShares(amountStaked - amountRedeemed));

    assertEq(stakeToken.totalSupply(), stakeToken.balanceOf(user));
    assertEq(underlyingToken.balanceOf(destination), amountRedeemed);
  }

  function test_withdrawWithoutApprove(
    uint104 amountStaked,
    uint104 amountRedeemed,
    address user
  ) public {
    vm.assume(amountStaked > 0);
    vm.assume(amountRedeemed != 0 && amountRedeemed <= amountStaked);
    vm.assume(user != address(proxyAdmin) && user != address(0) && user != USER);

    address destination = vm.addr(100);
    uint256 shares = stakeToken.convertToShares(amountStaked);
    uint256 sharesToRedeem = stakeToken.convertToShares(amountRedeemed);

    _stake(amountStaked, user);
    assertEq(stakeToken.balanceOf(user), shares);

    vm.startPrank(user);
    stakeToken.cooldown();
    vm.warp(block.timestamp + stakeToken.getCooldownSeconds());
    vm.stopPrank();

    vm.startPrank(USER);

    vm.expectRevert(
      abi.encodeWithSelector(
        IERC20Errors.ERC20InsufficientAllowance.selector,
        address(USER),
        0,
        sharesToRedeem
      )
    );

    stakeToken.withdraw(amountRedeemed, destination, user);
  }
}
