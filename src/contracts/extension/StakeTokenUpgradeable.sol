// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {IERC4626} from 'openzeppelin-contracts/contracts/interfaces/IERC4626.sol';
import {IAccessControl} from 'openzeppelin-contracts/contracts/access/IAccessControl.sol';

import {IPoolAddressesProvider} from '../interfaces/IPoolAddressesProvider.sol';
import {IRewardsController} from '../interfaces/IRewardsController.sol';
import {IStakeToken} from '../interfaces/IStakeToken.sol';

import {ERC4626Upgradeable} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol';

import {Initializable} from 'openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol';
import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {Math} from 'openzeppelin-contracts/contracts/utils/math/Math.sol';

abstract contract StakeTokenUpgradeable is Initializable, ERC4626Upgradeable, IStakeToken {
  using SafeERC20 for IERC20;
  using SafeCast for uint256;
  using Math for uint256;

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

  uint256 public constant MIN_ASSETS_REMAINING = 1e6;

  uint256 public constant EXCHANGE_RATE_UNIT = 1e18;
  uint192 public constant INITIAL_EXCHANGE_RATE = 1e18;

  IRewardsController public immutable REWARDS_CONTROLLER;

  constructor(IRewardsController rewardsController) {
    REWARDS_CONTROLLER = rewardsController;
  }

  function __StakeTokenUpgradable_init(
    IERC20 stakedToken,
    uint256 cooldown_,
    uint256 unstakeWindow_
  ) internal onlyInitializing {
    __ERC4626_init(stakedToken);

    _setCooldown(cooldown_);
    _setUnstakeWindow(unstakeWindow_);

    _updateExchangeRate(INITIAL_EXCHANGE_RATE);
  }

  function cooldown() external {
    _cooldown(_msgSender());
  }

  function cooldownOnBehalfOf(address owner) external {
    if (allowance(owner, _msgSender()) == 0) {
      revert NotApprovedForCooldown(owner, _msgSender());
    }

    _cooldown(owner);
  }

  function _handleAction(address from, address to, uint256 value) internal {
    uint256 cachedTotalSupply = totalSupply();

    // stake & transfer
    if (to != address(0)) {
      REWARDS_CONTROLLER.handleAction(to, cachedTotalSupply, balanceOf(to));
    }

    // redeem & transfer
    if (from != address(0) && from != to) {
      uint256 balanceOfFrom = balanceOf(from);
      REWARDS_CONTROLLER.handleAction(from, cachedTotalSupply, balanceOfFrom);

      StakeTokenStorage storage $ = _getStakeTokenStorage();
      CooldownSnapshot memory cooldownSnapshot = $._stakerCooldown[from];

      if (cooldownSnapshot.timestamp != 0) {
        if (to == address(0)) {
          // redeem
          if (cooldownSnapshot.amount == value) {
            delete $._stakerCooldown[from];

            emit StakerCooldownDeleted(from);
          } else {
            uint224 amount = cooldownSnapshot.amount - value.toUint224();

            $._stakerCooldown[from].amount = amount;

            emit StakerCooldownAmountChanged(from, amount);
          }
        } else {
          // transfer
          uint224 balanceAfter = (balanceOfFrom - value).toUint224();

          if (balanceAfter == 0) {
            delete $._stakerCooldown[from];

            emit StakerCooldownDeleted(from);
          } else if (balanceAfter < cooldownSnapshot.amount) {
            $._stakerCooldown[from].amount = balanceAfter;

            emit StakerCooldownAmountChanged(from, balanceAfter);
          }
        }
      }
    }
  }

  function _slash(address destination, uint256 amount) internal returns (uint256) {
    if (amount == 0) {
      revert ZeroAmountSlashing();
    }

    uint256 maxSlashable = getMaxSlashableAssets();

    if (maxSlashable == 0) {
      revert ZeroFundsAvailable();
    }

    if (amount > maxSlashable) {
      amount = maxSlashable;
    }

    uint256 currentShares = totalSupply();
    uint256 balance = convertToAssets(currentShares);

    _updateExchangeRate(_getExchangeRate(balance - amount, currentShares).toUint192());

    IERC20(asset()).safeTransfer(destination, amount);

    emit Slashed(destination, amount);

    return amount;
  }

  function getMaxSlashableAssets() public view returns (uint256) {
    uint256 currentAssets = totalAssets();
    return MIN_ASSETS_REMAINING > currentAssets ? 0 : currentAssets - MIN_ASSETS_REMAINING;
  }

  function maxWithdraw(
    address owner
  ) public view override(ERC4626Upgradeable, IERC4626) returns (uint256) {
    return _convertToAssets(maxRedeem(owner), Math.Rounding.Floor);
  }

  function maxRedeem(
    address owner
  ) public view override(ERC4626Upgradeable, IERC4626) returns (uint256) {
    StakeTokenStorage storage $ = _getStakeTokenStorage();
    CooldownSnapshot memory cooldownSnapshot = $._stakerCooldown[owner];

    if (
      block.timestamp >= cooldownSnapshot.timestamp &&
      block.timestamp - cooldownSnapshot.timestamp <= $._smConfig.unstakeWindow
    ) {
      return cooldownSnapshot.amount;
    }

    return 0;
  }

  function getExchangeRate() public view returns (uint256) {
    return _getStakeTokenStorage()._currentExchangeRate;
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

  function _cooldown(address from) internal virtual {
    uint256 amount = balanceOf(from);

    if (amount == 0) {
      revert ZeroBalanceInStaking();
    }

    StakeTokenStorage storage $ = _getStakeTokenStorage();

    uint32 timeToUnlock = (block.timestamp + $._smConfig.cooldown).toUint32();

    $._stakerCooldown[from] = CooldownSnapshot({
      amount: amount.toUint224(),
      timestamp: timeToUnlock
    });

    emit CooldownSet(from, amount, timeToUnlock);
  }

  function _setUnstakeWindow(uint256 newUnstakeWindow) internal {
    _getStakeTokenStorage()._smConfig.unstakeWindow = newUnstakeWindow.toUint32();

    emit UnstakeWindowChanged(newUnstakeWindow);
  }

  function _setCooldown(uint256 newCooldown) internal {
    _getStakeTokenStorage()._smConfig.cooldown = newCooldown.toUint32();

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

  function _convertToShares(
    uint256 assets,
    Math.Rounding rounding
  ) internal view override returns (uint256) {
    return assets.mulDiv(getExchangeRate(), EXCHANGE_RATE_UNIT, rounding);
  }

  function _convertToAssets(
    uint256 shares,
    Math.Rounding rounding
  ) internal view override returns (uint256) {
    return shares.mulDiv(EXCHANGE_RATE_UNIT, getExchangeRate(), rounding);
  }
}
