// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {StakeToken} from '../src/contracts/StakeToken.sol';

import {ERC20} from 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import {ProxyAdmin} from 'openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {StkTestUtils} from './StkTestUtils.t.sol';

contract Rewards is StkTestUtils {
  uint256 public emissionPerDay = 1e18;

  function setUp() public {
    _initializeStkToken(3000);
    uint256 emissionPerSecond = emissionPerDay / (60 * 60 * 24);
    _setEmission(emissionPerSecond);
  }

  /**
   * As long as no time passed, rewards should be zero
   */
  function test_rewards_shouldBeZero(uint104 amountToStake, address user) public {
    vm.assume(amountToStake > 0);
    vm.assume(user != address(proxyAdmin) && user != address(0));

    _stake(amountToStake, user);
    assertEq(stakeToken.getTotalRewardsBalance(user), 0);
  }

  /**
   * The rewards should increase monotonously
   */
  function test_rewards_shouldIncreaseOverTime(
    uint104 amountToStake,
    uint80 emissionPerSecond,
    address user,
    uint32 timePassed
  ) public {
    vm.assume(amountToStake > 0 && emissionPerSecond > 0);
    vm.assume(user != address(proxyAdmin) && user != address(0));

    _setEmission(emissionPerSecond);
    _stake(amountToStake, user);
    uint256 distributionDuration = stakeToken.distributionEnd() - block.timestamp;
    vm.warp(block.timestamp + timePassed);

    uint256 timeWithRewards = distributionDuration > timePassed ? timePassed : distributionDuration;
    uint256 maxAccruedRewards = timeWithRewards * emissionPerSecond;
    uint256 minAccruedRewards = maxAccruedRewards - timeWithRewards;
    uint256 factualUserRewards = stakeToken.getTotalRewardsBalance(user);
    /**
     * Rewards are accrued as `balance * (indexChange) / 1e18`
     * Therefore the error is limited by the rounding error of the division itself
     */
    uint256 digits = _numDigits(amountToStake * maxAccruedRewards);
    if (digits >= 18)
      assertApproxEqAbs(
        factualUserRewards,
        timeWithRewards * emissionPerSecond,
        10 ** (digits - 18)
      );
    assertApproxEqAbs(factualUserRewards, timeWithRewards * emissionPerSecond, 10 ** digits);
  }

  function _numDigits(uint256 number) internal returns (uint8) {
    uint8 digits = 0;
    //if (number < 0) digits = 1; // enable this line if '-' counts as a digit
    while (number != 0) {
      number /= 10;
      digits++;
    }
    return digits;
  }

  function test_claimHalf() public {
    uint256 amount = 1000 ether;
    _stake(amount, USER);
    vm.warp(block.timestamp + 360 days);
    uint256 rewardsBalance = stakeToken.getTotalRewardsBalance(USER);

    vm.startPrank(USER);
    stakeToken.claimRewards(USER, rewardsBalance / 2);
    assertEq(rewardToken.balanceOf(USER), rewardsBalance / 2);
    assertEq(stakeToken.getTotalRewardsBalance(USER), rewardsBalance / 2);
  }

  function test_claimAll() public {
    uint256 amount = 1000 ether;
    _stake(amount, USER);
    vm.warp(block.timestamp + 360 days);
    uint256 rewardsBalance = stakeToken.getTotalRewardsBalance(USER);

    vm.startPrank(USER);
    stakeToken.claimRewards(USER, rewardsBalance);
    assertEq(rewardToken.balanceOf(USER), rewardsBalance);
    assertEq(stakeToken.getTotalRewardsBalance(USER), 0);
  }

  function test_claimMore_shouldClaimAll() public {
    uint256 amount = 1000 ether;
    _stake(amount, USER);
    vm.warp(block.timestamp + 360 days);
    uint256 rewardsBalance = stakeToken.getTotalRewardsBalance(USER);

    vm.startPrank(USER);
    stakeToken.claimRewards(USER, rewardsBalance * 2);
    assertEq(rewardToken.balanceOf(USER), rewardsBalance);
    assertEq(stakeToken.getTotalRewardsBalance(USER), 0);
  }

  function test_claim_shouldRevertIfZero() public {
    vm.warp(block.timestamp + 360 days);

    vm.startPrank(USER);
    vm.expectRevert('INVALID_ZERO_AMOUNT');
    stakeToken.claimRewards(USER, 1 ether);
  }

  function test_distributionEnd(
    uint104 amountToStake,
    uint80 emissionPerSecond,
    address user,
    uint32 timePassed
  ) public {
    vm.assume(amountToStake > 0 && emissionPerSecond > 0);
    vm.assume(user != address(proxyAdmin) && user != address(0));

    _setEmission(emissionPerSecond);
    _stake(amountToStake, user);
    uint256 distributionDuration = stakeToken.distributionEnd() - block.timestamp;
    vm.warp(block.timestamp + timePassed);

    // set distributionend in the future
    vm.prank(admin);
    stakeToken.setDistributionEnd(block.timestamp + timePassed);

    // warp to the exact end
    vm.warp(block.timestamp + timePassed);
    uint256 rewardsBeforeEmissionEnd = stakeToken.getTotalRewardsBalance(user);
    // warp another time
    vm.warp(block.timestamp + timePassed);
    uint256 rewardsAfterEmissionEnd = stakeToken.getTotalRewardsBalance(user);

    // rewards should stay equal
    assertEq(rewardsBeforeEmissionEnd, rewardsAfterEmissionEnd);
  }

  function test_distributionEndInPast_shouldRevert() public {
    vm.prank(admin);
    vm.expectRevert('END_MUST_BE_GE_NOW');
    stakeToken.setDistributionEnd(block.timestamp - 1);
  }
}
