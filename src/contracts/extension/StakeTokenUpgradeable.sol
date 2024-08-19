// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IAccessControl} from 'openzeppelin-contracts/contracts/access/IAccessControl.sol';

import {IPoolAddressesProvider} from '../interfaces/IPoolAddressesProvider.sol';
import {IRewardsController} from '../interfaces/IRewardsController.sol';
import {IStakeToken} from '../interfaces/IStakeToken.sol';

import {Initializable} from 'openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol';
import {Math} from 'openzeppelin-contracts/contracts/utils/math/Math.sol';

abstract contract StakeTokenUpgradeable is Initializable, IStakeToken {
  using Math for uint256;

  uint256 public constant EXCHANGE_RATE_UNIT = 1e18;
  uint192 public constant INITIAL_EXCHANGE_RATE = 1e18;

  /// @custom:storage-location erc7201:aave.storage.StakeToken
  struct StakeTokenStorage {
    /// @notice User cooldown options
    mapping(address => CooldownSnapshot) _stakerCooldown;
    /// @notice Cooldown parameters
    SmConfig _smConfig;
    /// @notice Current exchangeRate of the stk
    uint192 _currentExchangeRate;
  }

  // keccak256(abi.encode(uint256(keccak256("aave.storage.StakeToken")) - 1)) & ~bytes32(uint256(0xff))
  bytes32 private constant StakeTokenStorageLocation =
    0x570b5e9089e57b3d227cfcd747a97877e3c5f12150099d7b38848c6202ca0a00;

  function _getStakeTokenStorage() private pure returns (StakeTokenStorage storage $) {
    assembly {
      $.slot := StakeTokenStorageLocation
    }
  }

  function __StakeTokenUpgradable_init(
    uint32 cooldown_,
    uint32 unstakeWindow_
  ) internal onlyInitializing {
    _setCooldown(cooldown_);
    _setUnstakeWindow(unstakeWindow_);
    _updateExchangeRate(INITIAL_EXCHANGE_RATE);
  }

  function getExchangeRate() public view returns (uint256) {
    return _getStakeTokenStorage()._currentExchangeRate;
  }

  function getSmConfig() public view returns (SmConfig memory) {
    return _getStakeTokenStorage()._smConfig;
  }

  function getCooldown() public view returns (uint256) {
    return _getStakeTokenStorage()._smConfig.cooldown;
  }

  function getUnstakeWindow() public view returns (uint256) {
    return _getStakeTokenStorage()._smConfig.unstakeWindow;
  }

  function getStakerCooldown(address user) public view returns (CooldownSnapshot memory) {
    return _getStakeTokenStorage()._stakerCooldown[user];
  }

  function _setStakerCooldown(address from, uint224 amount, uint32 timestamp) internal {
    _getStakeTokenStorage()._stakerCooldown[from] = CooldownSnapshot({
      amount: amount,
      timestamp: timestamp
    });

    emit CooldownSet(from, amount, timestamp);
  }

  function _setStakerCooldownAmount(address from, uint224 value) internal {
    _getStakeTokenStorage()._stakerCooldown[from].amount = value;

    emit StakerCooldownAmountChanged(from, value);
  }

  function _deleteStakerCooldown(address from) internal {
    delete _getStakeTokenStorage()._stakerCooldown[from];

    emit StakerCooldownDeleted(from);
  }

  function _setUnstakeWindow(uint32 newUnstakeWindow) internal {
    _getStakeTokenStorage()._smConfig.unstakeWindow = newUnstakeWindow;

    emit UnstakeWindowChanged(newUnstakeWindow);
  }

  function _setCooldown(uint32 newCooldown) internal {
    _getStakeTokenStorage()._smConfig.cooldown = newCooldown;

    emit CooldownChanged(newCooldown);
  }

  function _updateExchangeRate(uint192 newExchangeRate) internal {
    if (newExchangeRate == 0) {
      revert ZeroExchangeRate();
    }

    _getStakeTokenStorage()._currentExchangeRate = newExchangeRate;

    emit ExchangeRateChanged(newExchangeRate);
  }

  function _getExchangeRate(
    uint256 newTotalAssets,
    uint256 newTotalShares
  ) internal pure returns (uint256) {
    return newTotalShares.mulDiv(EXCHANGE_RATE_UNIT, newTotalAssets, Math.Rounding.Ceil);
  }
}
