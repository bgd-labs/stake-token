// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {StakeToken} from 'src/contracts/StakeToken.sol';
import {IStakeToken} from 'src/contracts/interfaces/IStakeToken.sol';

import {IERC20Errors} from 'openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {ERC20} from 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import {ProxyAdmin} from 'openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';

import {StakeTestBase} from './utils/StakeTestBase.sol';

contract Cooldown is StakeTestBase {
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

  function test_deposit(uint104 amountToStake) public {
    vm.assume(amountToStake > 0);

    uint256 shares = _deposit(amountToStake, user, user);

    assertEq(stakeToken.totalAssets(), amountToStake);
    assertEq(stakeToken.totalAssets(), underlying.balanceOf(address(stakeToken)));

    assertEq(stakeToken.totalSupply(), shares);
    assertEq(stakeToken.balanceOf(user), shares);
  }

  function test_depositToSomeone(uint104 amountToStake) public {
    vm.assume(amountToStake > 0);

    uint256 shares = _deposit(amountToStake, user, someone);

    assertEq(stakeToken.totalAssets(), amountToStake);
    assertEq(stakeToken.totalAssets(), underlying.balanceOf(address(stakeToken)));

    assertEq(stakeToken.totalSupply(), shares);
    assertEq(stakeToken.balanceOf(someone), shares);
  }

  function test_mint(uint104 amountOfShares) public {
    vm.assume(amountOfShares > 0);

    uint256 amountToStake = stakeToken.convertToAssets(amountOfShares);
    uint256 assets = _mint(amountOfShares, user, user);

    assertEq(assets, amountToStake);

    assertEq(stakeToken.totalAssets(), amountToStake);
    assertEq(stakeToken.totalAssets(), underlying.balanceOf(address(stakeToken)));

    assertEq(stakeToken.totalSupply(), amountOfShares);
    assertEq(stakeToken.balanceOf(user), amountOfShares);
  }

  function test_mintToSomeone(uint104 amountOfShares) public {
    vm.assume(amountOfShares > 0);

    uint256 amountToStake = stakeToken.convertToAssets(amountOfShares);
    uint256 assets = _mint(amountOfShares, user, someone);

    assertEq(assets, amountToStake);

    assertEq(stakeToken.totalAssets(), amountToStake);
    assertEq(stakeToken.totalAssets(), underlying.balanceOf(address(stakeToken)));

    assertEq(stakeToken.totalSupply(), amountOfShares);
    assertEq(stakeToken.balanceOf(someone), amountOfShares);
  }

  function test_maxWithdraw(uint104 amountToStake) public {
    vm.assume(amountToStake > 0);

    deal(address(underlying), user, amountToStake);

    _deposit(amountToStake, user, user);

    uint256 zeroAssetsBeforeCooldown = stakeToken.maxWithdraw(user);
    assertEq(zeroAssetsBeforeCooldown, 0);

    vm.startPrank(user);
    stakeToken.cooldown();

    uint256 assetsAvailable = stakeToken.maxWithdraw(user);
    assertEq(assetsAvailable, 0);

    skip(stakeToken.getCooldownSeconds());

    assetsAvailable = stakeToken.maxWithdraw(user);
    assertEq(assetsAvailable, amountToStake);
  }

  function test_maxRedeem(uint104 amountToStake) public {
    vm.assume(amountToStake > 0);

    uint256 shares = _deposit(amountToStake, user, user);

    uint256 zeroSharesBeforeCooldown = stakeToken.maxRedeem(user);
    assertEq(zeroSharesBeforeCooldown, 0);

    vm.startPrank(user);
    stakeToken.cooldown();

    uint256 sharesAvailable = stakeToken.maxRedeem(user);
    assertEq(sharesAvailable, 0);

    skip(stakeToken.getCooldownSeconds());

    sharesAvailable = stakeToken.maxRedeem(user);
    assertEq(sharesAvailable, shares);
  }

  function test_redeem(uint104 amountStaked, uint104 amountRedeemed) public {
    vm.assume(amountStaked > 0);
    vm.assume(amountRedeemed != 0 && amountRedeemed <= amountStaked);

    uint256 shares = _deposit(amountStaked, user, user);
    uint256 sharesToRedeem = stakeToken.convertToShares(amountRedeemed);

    vm.startPrank(user);

    stakeToken.cooldown();

    skip(stakeToken.getCooldownSeconds());

    stakeToken.redeem(sharesToRedeem, user, user);

    assertEq(stakeToken.totalAssets(), amountStaked - amountRedeemed);
    assertEq(underlying.balanceOf(user), amountRedeemed);

    assertEq(stakeToken.totalSupply(), stakeToken.balanceOf(user));
    assertEq(stakeToken.balanceOf(user), stakeToken.convertToShares(amountStaked - amountRedeemed));
  }

  function test_redeemToSomeone(uint104 amountStaked, uint104 amountRedeemed) public {
    vm.assume(amountStaked > 0);
    vm.assume(amountRedeemed != 0 && amountRedeemed <= amountStaked);

    _deposit(amountStaked, user, user);
    uint256 sharesToRedeem = stakeToken.convertToShares(amountRedeemed);

    vm.startPrank(user);

    stakeToken.cooldown();

    skip(stakeToken.getCooldownSeconds());

    stakeToken.redeem(sharesToRedeem, someone, user);

    assertEq(stakeToken.totalAssets(), amountStaked - amountRedeemed);
    assertEq(underlying.balanceOf(someone), amountRedeemed);

    assertEq(stakeToken.totalSupply(), stakeToken.balanceOf(user));
    assertEq(stakeToken.balanceOf(user), stakeToken.convertToShares(amountStaked - amountRedeemed));
  }

  function test_redeemWithApprove(uint104 amountStaked, uint104 amountRedeemed) public {
    vm.assume(amountStaked > 0);
    vm.assume(amountRedeemed != 0 && amountRedeemed <= amountStaked);

    _deposit(amountStaked, user, user);
    uint256 sharesToRedeem = stakeToken.convertToShares(amountRedeemed);

    vm.startPrank(user);

    stakeToken.cooldown();
    skip(stakeToken.getCooldownSeconds());
    stakeToken.approve(someone, sharesToRedeem);

    vm.stopPrank();
    vm.startPrank(someone);

    stakeToken.redeem(sharesToRedeem, someone, user);

    assertEq(stakeToken.totalAssets(), amountStaked - amountRedeemed);
    assertEq(underlying.balanceOf(someone), amountRedeemed);

    assertEq(stakeToken.totalSupply(), stakeToken.balanceOf(user));
    assertEq(stakeToken.balanceOf(user), stakeToken.convertToShares(amountStaked - amountRedeemed));
  }

  function test_redeemWithoutApprove(uint104 amountStaked, uint104 amountRedeemed) public {
    vm.assume(amountStaked > 0);
    vm.assume(amountRedeemed != 0 && amountRedeemed <= amountStaked);

    _deposit(amountStaked, user, user);
    uint256 sharesToRedeem = stakeToken.convertToShares(amountRedeemed);

    vm.prank(user);

    stakeToken.cooldown();
    skip(stakeToken.getCooldownSeconds());

    vm.stopPrank();
    vm.startPrank(someone);

    vm.expectRevert(
      abi.encodeWithSelector(
        IERC20Errors.ERC20InsufficientAllowance.selector,
        address(someone),
        0,
        sharesToRedeem
      )
    );
    stakeToken.redeem(sharesToRedeem, someone, user);
  }

  function test_withdraw(uint104 amountStaked, uint104 amountRedeemed) public {
    vm.assume(amountStaked > 0);
    vm.assume(amountRedeemed != 0 && amountRedeemed <= amountStaked);

    uint256 shares = _deposit(amountStaked, user, user);
    uint256 sharesToRedeem = stakeToken.convertToShares(amountRedeemed);

    vm.startPrank(user);

    stakeToken.cooldown();

    skip(stakeToken.getCooldownSeconds());

    uint256 sharesRedeemed = stakeToken.withdraw(amountRedeemed, user, user);

    assertEq(sharesToRedeem, sharesRedeemed);

    assertEq(stakeToken.totalAssets(), amountStaked - amountRedeemed);
    assertEq(underlying.balanceOf(user), amountRedeemed);

    assertEq(stakeToken.totalSupply(), stakeToken.balanceOf(user));
    assertEq(stakeToken.balanceOf(user), stakeToken.convertToShares(amountStaked - amountRedeemed));
  }

  function test_withdrawToSomeone(uint104 amountStaked, uint104 amountRedeemed) public {
    vm.assume(amountStaked > 0);
    vm.assume(amountRedeemed != 0 && amountRedeemed <= amountStaked);

    uint256 shares = _deposit(amountStaked, user, user);
    uint256 sharesToRedeem = stakeToken.convertToShares(amountRedeemed);

    vm.startPrank(user);

    stakeToken.cooldown();

    skip(stakeToken.getCooldownSeconds());

    uint256 sharesRedeemed = stakeToken.withdraw(amountRedeemed, someone, user);

    assertEq(sharesToRedeem, sharesRedeemed);

    assertEq(stakeToken.totalAssets(), amountStaked - amountRedeemed);
    assertEq(underlying.balanceOf(someone), amountRedeemed);

    assertEq(stakeToken.totalSupply(), stakeToken.balanceOf(user));
    assertEq(stakeToken.balanceOf(user), stakeToken.convertToShares(amountStaked - amountRedeemed));
  }

  function test_withdrawWithApprove(
    uint104 amountStaked,
    uint104 amountRedeemed,
    address fuzzUser
  ) public {
    vm.assume(amountStaked > 0);
    vm.assume(amountRedeemed != 0 && amountRedeemed <= amountStaked);

    _deposit(amountStaked, user, user);
    uint256 sharesToRedeem = stakeToken.convertToShares(amountRedeemed);

    vm.startPrank(user);

    stakeToken.cooldown();
    skip(stakeToken.getCooldownSeconds());
    stakeToken.approve(someone, sharesToRedeem);

    vm.stopPrank();
    vm.startPrank(someone);

    uint256 sharesRedeemed = stakeToken.withdraw(amountRedeemed, someone, user);

    assertEq(sharesRedeemed, sharesToRedeem);

    assertEq(stakeToken.totalAssets(), amountStaked - amountRedeemed);
    assertEq(underlying.balanceOf(someone), amountRedeemed);

    assertEq(stakeToken.totalSupply(), stakeToken.balanceOf(user));
    assertEq(stakeToken.balanceOf(user), stakeToken.convertToShares(amountStaked - amountRedeemed));
  }

  function test_withdrawWithoutApprove(uint104 amountStaked, uint104 amountRedeemed) public {
    vm.assume(amountStaked > 0);
    vm.assume(amountRedeemed != 0 && amountRedeemed <= amountStaked);

    _deposit(amountStaked, user, user);
    uint256 sharesToRedeem = stakeToken.convertToShares(amountRedeemed);

    vm.startPrank(user);

    stakeToken.cooldown();
    skip(stakeToken.getCooldownSeconds());

    vm.stopPrank();
    vm.startPrank(someone);

    vm.expectRevert(
      abi.encodeWithSelector(
        IERC20Errors.ERC20InsufficientAllowance.selector,
        address(someone),
        0,
        sharesToRedeem
      )
    );

    stakeToken.withdraw(amountRedeemed, someone, user);
  }
}
