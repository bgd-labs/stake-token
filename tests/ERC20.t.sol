// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC20Errors} from 'openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol';

import {StakeTestBase} from './utils/StakeTestBase.sol';

contract ERC20Tests is StakeTestBase {
  function test_name() external view {
    assertEq('Stake Test', stakeToken.name());
  }

  function test_symbol() external view {
    assertEq('stkTest', stakeToken.symbol());
  }

  // mint
  function test_mint(uint192 amount) public {
    vm.assume(amount > 0);

    _mint(amount, user, user);

    assertEq(stakeToken.totalAssets(), underlying.balanceOf(address(stakeToken)));
    assertEq(stakeToken.totalSupply(), stakeToken.balanceOf(user));

    assertLe(
      getDiff(stakeToken.previewRedeem(amount), underlying.balanceOf(address(stakeToken))),
      10
    );
  }

  // burn
  function test_withdraw(uint192 amountStaked, uint192 amountWithdraw) public {
    vm.assume(amountStaked > amountWithdraw && amountWithdraw > 0);

    _deposit(amountStaked, user, user);

    vm.startPrank(user);

    stakeToken.cooldown();
    skip(stakeToken.getCooldown());

    stakeToken.withdraw(amountWithdraw, user, user);

    assertEq(stakeToken.totalAssets(), amountStaked - amountWithdraw);
    assertEq(underlying.balanceOf(user), amountWithdraw);

    assertEq(stakeToken.balanceOf(user), stakeToken.totalSupply());
    assertEq(stakeToken.balanceOf(user), stakeToken.convertToShares(amountStaked - amountWithdraw));
  }

  function test_approve(uint192 amount) public {
    assertTrue(stakeToken.approve(user, amount));
    assertEq(stakeToken.allowance(address(this), user), amount);
  }

  function test_resetApproval(uint192 amount) public {
    assertTrue(stakeToken.approve(user, amount));
    assertTrue(stakeToken.approve(user, 0));
    assertEq(stakeToken.allowance(address(this), user), 0);
  }

  function test_transferWithoutCooldownInStake(
    uint192 amountStake,
    uint224 sharesTransfer
  ) external {
    vm.assume(amountStake > 0);
    vm.assume(sharesTransfer <= stakeToken.convertToShares(amountStake));

    _deposit(amountStake, user, user);

    vm.startPrank(user);

    stakeToken.transfer(someone, sharesTransfer);

    assertEq(stakeToken.balanceOf(someone), sharesTransfer);
    assertEq(stakeToken.balanceOf(user), stakeToken.convertToShares(amountStake) - sharesTransfer);
  }

  function test_transferWithCooldownInStake(uint192 amountStake, uint224 sharesTransfer) external {
    vm.assume(amountStake > 0);
    vm.assume(sharesTransfer <= stakeToken.convertToShares(amountStake));

    _deposit(amountStake, user, user);

    vm.startPrank(user);

    stakeToken.cooldown();

    skip(1);

    stakeToken.transfer(someone, sharesTransfer);

    assertEq(stakeToken.balanceOf(someone), sharesTransfer);
    assertEq(stakeToken.balanceOf(user), stakeToken.convertToShares(amountStake) - sharesTransfer);
  }

  function test_transferFrom(uint192 amountStake, uint224 sharesTransfer) external {
    vm.assume(amountStake > 0);
    vm.assume(sharesTransfer <= stakeToken.convertToShares(amountStake));

    uint256 sharesMinted = _deposit(amountStake, user, user);

    vm.startPrank(user);

    stakeToken.approve(someone, sharesTransfer);

    vm.stopPrank();
    vm.startPrank(someone);

    assertTrue(stakeToken.transferFrom(user, someone, sharesTransfer));

    vm.stopPrank();

    assertEq(stakeToken.allowance(user, someone), 0);

    assertEq(stakeToken.balanceOf(user), sharesMinted - sharesTransfer);
    assertEq(stakeToken.balanceOf(someone), sharesTransfer);
  }

  function test_transferFromWithoutApprove(uint192 amountStake, uint224 sharesTransfer) external {
    vm.assume(amountStake > 0);
    vm.assume(0 < sharesTransfer && sharesTransfer <= stakeToken.convertToShares(amountStake));

    _deposit(amountStake, user, user);

    vm.startPrank(someone);

    vm.expectRevert(
      abi.encodeWithSelector(
        IERC20Errors.ERC20InsufficientAllowance.selector,
        someone,
        0,
        sharesTransfer
      )
    );
    stakeToken.transferFrom(user, someone, sharesTransfer);
  }
}
