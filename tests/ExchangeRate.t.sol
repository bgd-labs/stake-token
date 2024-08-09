// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {StakeToken} from '../src/contracts/StakeToken.sol';
import {ERC20} from 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import {ProxyAdmin} from 'openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {IERC20Errors} from 'openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol';
import {PausableUpgradeable} from 'openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol';
import {StakeTestBase} from './utils/StakeTestBase.sol';
import {ActionsLibrary, IStakeToken} from './utils/ActionsLibrary.sol';
import {WadRayMath} from 'aave-v3-origin/core/contracts/protocol/libraries/math/WadRayMath.sol';
import {IPoolAddressesProvider} from 'aave-v3-origin/core/contracts/interfaces/IPoolAddressesProvider.sol';
import {IRewardsController} from '../src/contracts/interfaces/IRewardsController.sol';

/**
 * Testing the effects of certain indexes on deposit/withdrawal behavior
 */
contract ExchangeRateTest is StakeToken, Test {
  using WadRayMath for uint256;

  constructor() StakeToken(IRewardsController(address(0)), IPoolAddressesProvider(address(0))) {}

  /// forge-config: default.fuzz.runs = 100000
  function test_liquidityIndex(uint256 amount, uint256 index) public pure {
    amount = bound(amount, 1, type(uint104).max);
    index = bound(index, 1e27, 1e29);
    uint256 scaledBalance = amount.rayDiv(index);
    uint256 scaledUpBalance = scaledBalance.rayMul(index);
    assertApproxEqAbs(amount, scaledUpBalance, 1e2);
  }

  function test_liquidityIndex_maxIndex() external pure {
    test_liquidityIndex(type(uint104).max - 1, 1e29 - 1);
  }

  function test_liquidityIndex_minIndex() external pure {
    test_liquidityIndex(type(uint104).max - 1, 1e27);
  }

  /// forge-config: default.fuzz.runs = 100000
  function test_exchangeRate(uint256 amount, uint256 exchangeRate) external {
    amount = bound(amount, 1, type(uint104).max);
    exchangeRate = bound(exchangeRate, INITIAL_EXCHANGE_RATE, 1e29);

    StakeTokenStorage storage $ = _getStakeTokenStorage();
    $._currentExchangeRate = uint192(exchangeRate);
    uint256 shares = previewDeposit(amount);
    uint256 assets = previewRedeem(shares);
    assertApproxEqAbs(amount, assets, 3);
  }

  function test_exchangeRate_maxExchangeRate() external {
    this.test_exchangeRate(type(uint104).max - 1, 1e29 - 1);
  }
}
