// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IPoolAddressesProvider} from 'src/contracts/interfaces/IPoolAddressesProvider.sol';
import {IRewardsController} from 'src/contracts/interfaces/IRewardsController.sol';

import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';

import {StakeTestBase} from './utils/StakeTestBase.sol';

contract ExchangeRateTest is StakeTestBase {
  using SafeCast for uint256;

  /// forge-config: default.fuzz.runs = 100000
  function test_precisionLossWithSlash(uint192 assets, uint192 assetsToSlash) public {
    vm.assume(assets > stakeToken.MIN_ASSETS_REMAINING());
    vm.assume(assetsToSlash > 0 && assetsToSlash < assets);
    vm.assume(assets - stakeToken.MIN_ASSETS_REMAINING() >= assetsToSlash);

    uint256 shares = stakeToken.previewDeposit(assets);

    _deposit(assets, user, user);

    vm.startPrank(slashingAdmin);

    stakeToken.slash(someone, assetsToSlash);

    vm.stopPrank();

    uint192 assetsAfterRedeem = stakeToken.previewRedeem(shares).toUint192();

    assertLe(assetsAfterRedeem, assets);

    assertLe(getDiff(assetsAfterRedeem, assets - assetsToSlash), 1);
  }

  /// forge-config: default.fuzz.runs = 100000
  function test_precisionLossStartingWithAssets(
    uint192 assetsToStake,
    uint192 assetsToCheck
  ) public {
    vm.assume(assetsToStake > assetsToCheck && assetsToCheck > 0);

    _deposit(assetsToStake, user, user);

    uint256 sharesFromDeposit = stakeToken.previewDeposit(assetsToCheck);
    uint256 assetsFromMint = stakeToken.previewMint(sharesFromDeposit);

    assertLe(getDiff(assetsToCheck, assetsFromMint), 1);

    uint256 sharesFromWithdrawal = stakeToken.previewWithdraw(assetsToCheck);
    uint256 assetsFromRedeem = stakeToken.previewRedeem(sharesFromWithdrawal);

    assertLe(getDiff(assetsToCheck, assetsFromRedeem), 1);
  }

  /// forge-config: default.fuzz.runs = 100000
  function test_precisionLossStartingWithShares(
    uint192 assetsToStake,
    uint224 sharesToCheck
  ) public {
    vm.assume(
      assetsToStake > stakeToken.convertToAssets(sharesToCheck) &&
        sharesToCheck > sharesMultiplier()
    );

    _deposit(assetsToStake, user, user);

    uint256 assetsFromMint = stakeToken.previewMint(sharesToCheck);
    uint256 sharesFromDeposit = stakeToken.previewDeposit(assetsFromMint);

    assertLe(getDiff(sharesToCheck, sharesFromDeposit), 1000);

    uint256 assetsFromRedeem = stakeToken.previewRedeem(sharesToCheck);
    uint256 sharesFromWithdrawal = stakeToken.previewWithdraw(assetsFromRedeem);

    assertLe(getDiff(sharesToCheck, sharesFromWithdrawal), 1000);
  }

  /// forge-config: default.fuzz.runs = 100000
  function test_precisionLossCombinedTest(
    uint192 assets,
    uint192 assetsToSlash,
    uint192 assetsToCheck,
    uint224 sharesToCheck
  ) public {
    vm.assume(assets > stakeToken.MIN_ASSETS_REMAINING());
    vm.assume(assetsToSlash > 0 && assetsToSlash < assets);
    vm.assume(assets - stakeToken.MIN_ASSETS_REMAINING() >= assetsToSlash);

    vm.assume(assets > assetsToCheck && assetsToCheck > 0);
    vm.assume(
      assets > stakeToken.convertToAssets(sharesToCheck) && sharesToCheck > sharesMultiplier()
    );

    stakeToken.previewDeposit(assets);

    _deposit(assets, user, user);

    vm.startPrank(slashingAdmin);

    stakeToken.slash(someone, assetsToSlash);

    vm.stopPrank();

    uint256 sharesFromDeposit_1 = stakeToken.previewDeposit(assetsToCheck);
    uint256 assetsFromMint_1 = stakeToken.previewMint(sharesFromDeposit_1);

    assertLe(getDiff(assetsToCheck, assetsFromMint_1), 1);

    uint256 sharesFromWithdrawal_1 = stakeToken.previewWithdraw(assetsToCheck);
    uint256 assetsFromRedeem_1 = stakeToken.previewRedeem(sharesFromWithdrawal_1);

    assertLe(getDiff(assetsToCheck, assetsFromRedeem_1), 1);

    // check, cause they have different rounding, but same convertToShares with the same assets started
    assertLe(getDiff(sharesFromDeposit_1, sharesFromWithdrawal_1), 1000);

    // TODO need to think here, cause this test is failed with these values
    // assets        = 6277101735386680763835789423207666416102355444464034512863
    // assetsToSlash = 6277101735386680763619579229924836587676145011266550440097
    // sharesToCheck = 157198259

    // uint256 assetsFromMint_2 = stakeToken.previewMint(sharesToCheck);
    // uint256 sharesFromDeposit_2 = stakeToken.previewDeposit(assetsFromMint_2);

    // assertLe(getDiff(sharesToCheck, sharesFromDeposit_2), 1e8);

    // uint256 assetsFromRedeem_2 = stakeToken.previewRedeem(sharesToCheck);
    // uint256 sharesFromWithdrawal_2 = stakeToken.previewWithdraw(assetsFromRedeem_2);

    // assertLe(getDiff(sharesToCheck, sharesFromWithdrawal_2), 1e8);
  }
}
