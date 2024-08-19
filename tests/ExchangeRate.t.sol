// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IPoolAddressesProvider} from 'src/contracts/interfaces/IPoolAddressesProvider.sol';
import {IRewardsController} from 'src/contracts/interfaces/IRewardsController.sol';

import {MockToken} from './utils/mock/MockTokenForExchangeRate.sol';

import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';

contract ExchangeRateTest is Test {
  using SafeCast for uint256;

  MockToken public mock;

  function setUp() public {
    mock = new MockToken(IRewardsController(address(0)), IPoolAddressesProvider(address(0)));
  }

  /// forge-config: default.fuzz.runs = 100000
  function test_precisionLossStartingWithAssets(uint128 assets, uint128 exchangeRate) public {
    // Since initial exchange rate is 1e18 and after slash it should increase only
    vm.assume(assets > 0 && exchangeRate >= 1e18);
    mock.setExchangeRate(exchangeRate);

    uint256 shares = mock.previewDeposit(assets);
    uint128 assetsAfterRedeem = mock.previewRedeem(shares).toUint128();

    assert(assetsAfterRedeem <= assets);
    assert(assets - assetsAfterRedeem < 2);
  }

  /// forge-config: default.fuzz.runs = 100000
  function test_precisionLossStartingWithShares(uint128 sharesToMint, uint128 exchangeRate) public {
    // Since initial exchange rate is 1e18 and after slash it should increase only
    vm.assume(sharesToMint > 0 && exchangeRate >= 1e18);
    mock.setExchangeRate(exchangeRate);

    // mint function have some troubles with precision and results in worse results
    uint256 assets = mock.previewMint(sharesToMint);
    uint256 sharesFromDeposit = mock.previewDeposit(assets);

    assert(sharesFromDeposit >= sharesToMint);

    // withdraw have the same problems
    uint256 sharesAfterWithdraw = mock.previewWithdraw(assets);
    uint256 assetsAfterRedeem = mock.previewRedeem(sharesFromDeposit);

    assert(assets >= assetsAfterRedeem);
    assert(sharesAfterWithdraw >= sharesFromDeposit);
  }
}
