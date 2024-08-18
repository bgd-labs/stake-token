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
import {StakeTestBase} from '../utils/StakeTestBase.sol';

contract Cooldown is StakeTestBase {
  function test_maxWithdraw(uint104 amountToStake, address fuzzUser) public {
    vm.assume(amountToStake > 0);
    vm.assume(fuzzUser != address(proxyAdmin) && fuzzUser != address(0));

    _stake(amountToStake, fuzzUser);

    uint256 zeroAssetsDueToCooldown = stakeToken.maxWithdraw(fuzzUser);
    assertEq(zeroAssetsDueToCooldown, 0);

    vm.startPrank(fuzzUser);
    stakeToken.cooldown();

    uint256 allAssets = stakeToken.maxWithdraw(fuzzUser);
    assertEq(amountToStake, allAssets);
  }

  function test_maxRedeem(uint104 amountToStake, address fuzzUser) public {
    vm.assume(amountToStake > 0);
    vm.assume(fuzzUser != address(proxyAdmin) && fuzzUser != address(0));

    uint256 sharesToMint = stakeToken.convertToShares(amountToStake);
    _stake(amountToStake, fuzzUser);

    uint256 zeroSharesDueToCooldown = stakeToken.maxRedeem(fuzzUser);
    assertEq(zeroSharesDueToCooldown, 0);

    vm.startPrank(fuzzUser);
    stakeToken.cooldown();

    uint256 allShares = stakeToken.maxWithdraw(fuzzUser);
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

  function test_deposit(uint104 amount, address fuzzUser) public {
    vm.assume(amount > 0);
    vm.assume(fuzzUser != address(proxyAdmin) && fuzzUser != address(0));

    deal(address(underlying), fuzzUser, amount);
    vm.startPrank(fuzzUser);
    underlying.approve(address(stakeToken), amount);

    uint256 numberOfShares = stakeToken.deposit(amount, fuzzUser);
    vm.stopPrank();

    assertEq(stakeToken.totalAssets(), amount);
    assertEq(stakeToken.totalAssets(), stakeToken.balanceOf(fuzzUser));

    assertEq(stakeToken.totalSupply(), numberOfShares);
  }

  function test_mint(uint104 amount, address fuzzUser) public {
    vm.assume(amount > 0);
    vm.assume(fuzzUser != address(proxyAdmin) && fuzzUser != address(0));

    uint256 shares = stakeToken.convertToShares(amount);

    deal(address(underlying), fuzzUser, amount);
    vm.startPrank(fuzzUser);
    underlying.approve(address(stakeToken), amount);

    stakeToken.mint(shares, fuzzUser);
    vm.stopPrank();

    assertEq(stakeToken.totalAssets(), amount);
    assertEq(stakeToken.totalAssets(), stakeToken.balanceOf(fuzzUser));

    assertEq(stakeToken.totalSupply(), shares);
  }

  function test_redeem(uint104 amountStaked, uint104 amountRedeemed, address fuzzUser) public {
    vm.assume(amountStaked > 0);
    vm.assume(amountRedeemed != 0 && amountRedeemed <= amountStaked);
    vm.assume(fuzzUser != address(proxyAdmin) && fuzzUser != address(0));

    address destination = vm.addr(100);
    uint256 shares = stakeToken.convertToShares(amountStaked);
    uint256 sharesToRedeem = stakeToken.convertToShares(amountRedeemed);

    _stake(amountStaked, fuzzUser);
    assertEq(stakeToken.balanceOf(fuzzUser), shares);

    vm.prank(fuzzUser);
    stakeToken.cooldown();
    vm.warp(block.timestamp + stakeToken.getCooldownSeconds());

    vm.startPrank(fuzzUser);
    stakeToken.redeem(sharesToRedeem, destination, fuzzUser);
    vm.stopPrank();

    assertEq(stakeToken.totalAssets(), amountStaked - amountRedeemed);
    assertEq(
      stakeToken.balanceOf(fuzzUser),
      stakeToken.convertToShares(amountStaked - amountRedeemed)
    );

    assertEq(stakeToken.totalSupply(), stakeToken.balanceOf(fuzzUser));
    assertEq(underlying.balanceOf(destination), amountRedeemed);
  }

  function test_redeemWithApprove(
    uint104 amountStaked,
    uint104 amountRedeemed,
    address fuzzUser
  ) public {
    vm.assume(amountStaked > 0);
    vm.assume(amountRedeemed != 0 && amountRedeemed <= amountStaked);
    vm.assume(fuzzUser != address(proxyAdmin) && fuzzUser != address(0) && fuzzUser != user);

    address destination = vm.addr(100);
    uint256 shares = stakeToken.convertToShares(amountStaked);
    uint256 sharesToRedeem = stakeToken.convertToShares(amountRedeemed);

    _stake(amountStaked, fuzzUser);
    assertEq(stakeToken.balanceOf(fuzzUser), shares);

    vm.prank(fuzzUser);
    stakeToken.cooldown();
    vm.warp(block.timestamp + stakeToken.getCooldownSeconds());

    vm.startPrank(fuzzUser);
    stakeToken.approve(user, sharesToRedeem);
    vm.stopPrank();

    vm.startPrank(user);
    stakeToken.redeem(sharesToRedeem, destination, fuzzUser);
    vm.stopPrank();

    assertEq(stakeToken.totalAssets(), amountStaked - amountRedeemed);
    assertEq(
      stakeToken.balanceOf(fuzzUser),
      stakeToken.convertToShares(amountStaked - amountRedeemed)
    );

    assertEq(stakeToken.totalSupply(), stakeToken.balanceOf(fuzzUser));
    assertEq(underlying.balanceOf(destination), amountRedeemed);
  }

  function test_redeemWithoutApprove(
    uint104 amountStaked,
    uint104 amountRedeemed,
    address fuzzUser
  ) public {
    vm.assume(amountStaked > 0);
    vm.assume(amountRedeemed != 0 && amountRedeemed <= amountStaked);
    vm.assume(fuzzUser != address(proxyAdmin) && fuzzUser != address(0) && fuzzUser != user);

    address destination = vm.addr(100);
    uint256 shares = stakeToken.convertToShares(amountStaked);
    uint256 sharesToRedeem = stakeToken.convertToShares(amountRedeemed);

    _stake(amountStaked, fuzzUser);
    assertEq(stakeToken.balanceOf(fuzzUser), shares);

    vm.prank(fuzzUser);
    stakeToken.cooldown();
    vm.warp(block.timestamp + stakeToken.getCooldownSeconds());

    vm.startPrank(user);
    vm.expectRevert(
      abi.encodeWithSelector(
        IERC20Errors.ERC20InsufficientAllowance.selector,
        address(user),
        0,
        sharesToRedeem
      )
    );
    stakeToken.redeem(sharesToRedeem, destination, fuzzUser);
  }

  function test_withdraw(uint104 amountStaked, uint104 amountRedeemed, address fuzzUser) public {
    vm.assume(amountStaked > 0);
    vm.assume(amountRedeemed != 0 && amountRedeemed <= amountStaked);
    vm.assume(fuzzUser != address(proxyAdmin) && fuzzUser != address(0));

    address destination = vm.addr(100);
    uint256 shares = stakeToken.convertToShares(amountStaked);

    _stake(amountStaked, fuzzUser);
    assertEq(stakeToken.balanceOf(fuzzUser), shares);

    vm.startPrank(fuzzUser);
    stakeToken.cooldown();
    vm.warp(block.timestamp + stakeToken.getCooldownSeconds());
    stakeToken.withdraw(amountRedeemed, destination, fuzzUser);
    vm.stopPrank();

    assertEq(stakeToken.totalAssets(), amountStaked - amountRedeemed);
    assertEq(
      stakeToken.balanceOf(fuzzUser),
      stakeToken.convertToShares(amountStaked - amountRedeemed)
    );

    assertEq(stakeToken.totalSupply(), stakeToken.balanceOf(fuzzUser));
    assertEq(underlying.balanceOf(destination), amountRedeemed);
  }

  function test_withdrawWithApprove(
    uint104 amountStaked,
    uint104 amountRedeemed,
    address fuzzUser
  ) public {
    vm.assume(amountStaked > 0);
    vm.assume(amountRedeemed != 0 && amountRedeemed <= amountStaked);
    vm.assume(fuzzUser != address(proxyAdmin) && fuzzUser != address(0) && fuzzUser != user);

    address destination = vm.addr(100);
    uint256 shares = stakeToken.convertToShares(amountStaked);
    uint256 sharesToRedeem = stakeToken.convertToShares(amountRedeemed);

    _stake(amountStaked, fuzzUser);
    assertEq(stakeToken.balanceOf(fuzzUser), shares);

    vm.prank(fuzzUser);
    stakeToken.cooldown();
    vm.warp(block.timestamp + stakeToken.getCooldownSeconds());

    vm.startPrank(fuzzUser);
    stakeToken.approve(user, sharesToRedeem);
    vm.stopPrank();

    vm.startPrank(user);
    stakeToken.withdraw(amountRedeemed, destination, fuzzUser);
    vm.stopPrank();

    assertEq(stakeToken.totalAssets(), amountStaked - amountRedeemed);
    assertEq(
      stakeToken.balanceOf(fuzzUser),
      stakeToken.convertToShares(amountStaked - amountRedeemed)
    );

    assertEq(stakeToken.totalSupply(), stakeToken.balanceOf(fuzzUser));
    assertEq(underlying.balanceOf(destination), amountRedeemed);
  }

  function test_withdrawWithoutApprove(
    uint104 amountStaked,
    uint104 amountRedeemed,
    address fuzzUser
  ) public {
    vm.assume(amountStaked > 0);
    vm.assume(amountRedeemed != 0 && amountRedeemed <= amountStaked);
    vm.assume(fuzzUser != address(proxyAdmin) && fuzzUser != address(0) && fuzzUser != user);

    address destination = vm.addr(100);
    uint256 shares = stakeToken.convertToShares(amountStaked);
    uint256 sharesToRedeem = stakeToken.convertToShares(amountRedeemed);

    _stake(amountStaked, fuzzUser);
    assertEq(stakeToken.balanceOf(fuzzUser), shares);

    vm.startPrank(fuzzUser);
    stakeToken.cooldown();
    vm.warp(block.timestamp + stakeToken.getCooldownSeconds());
    vm.stopPrank();

    vm.startPrank(user);

    vm.expectRevert(
      abi.encodeWithSelector(
        IERC20Errors.ERC20InsufficientAllowance.selector,
        address(user),
        0,
        sharesToRedeem
      )
    );

    stakeToken.withdraw(amountRedeemed, destination, fuzzUser);
  }
}
