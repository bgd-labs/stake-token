// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from 'aave-v3-origin/core/contracts/interfaces/IPoolAddressesProvider.sol';
import {IAccessControl} from 'aave-v3-origin/core/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol';

import {IRewardsController} from './interfaces/IRewardsController.sol';
import {IStakeToken} from './interfaces/eIStakeToken.sol';

import {UpgradableOwnableWithGuardian} from 'solidity-utils/contracts/access-control/UpgradableOwnableWithGuardian.sol';

import {Initializable} from 'openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol';
import {ERC20PermitUpgradeable, ERC20Upgradeable} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol';
import {ERC4626Upgradeable, IERC20Metadata, IERC20, Math} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol';
import {ERC20PausableUpgradeable} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PausableUpgradeable.sol';

import {IERC20 as SafeIERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';

import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';

contract StakeToken is
  IStakeToken,
  Initializable,
  ERC20PermitUpgradeable,
  ERC20PausableUpgradeable,
  ERC4626Upgradeable,
  UpgradableOwnableWithGuardian
{
  using SafeERC20 for SafeIERC20;
  using SafeCast for uint256;
  using Math for uint256;

  // @audit-high @pavelvm5 this mechanic won't work at all with 1e4 if we will slash max amount, then deposit 1e18 and try to slash again we will have zero exchange_rate anyway
  // should be 1e18 or smth like that, due to the fact that we will use mostly stata-tokens
  // changed to 1e18
  uint256 public constant MIN_ASSETS_REMAINING = 1e18;

  uint216 public constant INITIAL_EXCHANGE_RATE = 1e18;
  uint256 public constant EXCHANGE_RATE_UNIT = 1e18;

  // keccak256(abi.encode(uint256(keccak256("aave.storage.StakeToken")) - 1)) & ~bytes32(uint256(0xff))
  bytes32 private constant StakeTokenStorageLocation =
    0x570b5e9089e57b3d227cfcd747a97877e3c5f12150099d7b38848c6202ca0a00;

  IRewardsController public immutable REWARDS_CONTROLLER;
  IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

  error ZeroExchangeRate();
  error ZeroBalanceOnCooldown();
  error ZeroAmountSlashing();
  error ZeroFundsAvailable();
  error CallerIsNotSlashingAdmin();
  error NotApprovedForCooldown(address owner, address spender);

  modifier onlySlashingAdmin() {
    if (!IAccessControl(ADDRESSES_PROVIDER.getACLManager()).hasRole('SLASHING_ADMIN', msg.sender)) {
      revert CallerIsNotSlashingAdmin();
    }
    _;
  }

  constructor(IRewardsController rewardsController, IPoolAddressesProvider provider) {
    REWARDS_CONTROLLER = rewardsController;
    ADDRESSES_PROVIDER = provider;

    _disableInitializers();
  }

  function initialize(
    IERC20 stakedToken,
    string calldata name,
    string calldata symbol,
    address owner,
    uint256 cooldownSeconds,
    uint256 unstakeWindow
  ) external virtual initializer {
    __ERC20_init(name, symbol);
    __ERC20Permit_init(name);
    __ERC20Pausable_init();
    __ERC4626_init(stakedToken);

    __Ownable_init(owner);

    _setCooldownSeconds(cooldownSeconds);
    _setUnstakeWindow(unstakeWindow);
    _updateExchangeRate(INITIAL_EXCHANGE_RATE);
  }

  function slash(
    address destination,
    uint256 amount
  ) external override onlySlashingAdmin returns (uint256) {
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

    _updateExchangeRate(_getExchangeRate(balance - amount, currentShares));

    SafeIERC20(asset()).safeTransfer(destination, amount);

    emit Slashed(destination, amount);

    return amount;
  }

  function cooldown() external override whenNotPaused {
    _cooldown(msg.sender);
  }

  function cooldownOnBehalfOf(address owner) external override whenNotPaused {
    if (allowance(owner, msg.sender) == 0) {
      revert NotApprovedForCooldown(owner, msg.sender);
    }

    _cooldown(owner);
  }

  function setUnstakeWindow(uint256 newUnstakeWindow) external override onlyOwner {
    _setUnstakeWindow(newUnstakeWindow);
  }

  function setCooldownSeconds(uint256 newCooldownSeconds) external override onlyOwner {
    _setCooldownSeconds(newCooldownSeconds);
  }

  function setPause(bool pause) external onlyOwnerOrGuardian {
    if (pause) {
      _pause();
    } else {
      _unpause();
    }
  }

  // @pavelvm5 why is it returning 216? changed to 256
  function getExchangeRate() external view override returns (uint256) {
    return _getStakeTokenStorage()._currentExchangeRate;
  }

  function getCooldownSeconds() external view override returns (uint256) {
    return _getStakeTokenStorage()._smConfig.cooldownSeconds;
  }

  function getUnstakeWindow() external view override returns (uint256) {
    return _getStakeTokenStorage()._smConfig.unstakeWindowSeconds;
  }

  function stakersCooldowns(address user) external view override returns (CooldownSnapshot memory) {
    return _getStakeTokenStorage()._stakersCooldowns[user];
  }

  function maxWithdraw(address owner) public view override returns (uint256) {
    return _convertToAssets(maxRedeem(owner), Math.Rounding.Floor);
  }

  function maxRedeem(address owner) public view override returns (uint256) {
    StakeTokenStorage storage $ = _getStakeTokenStorage();
    CooldownSnapshot memory cooldownSnapshot = $._stakersCooldowns[owner];

    if (
      block.timestamp >= cooldownSnapshot.timestamp &&
      block.timestamp - cooldownSnapshot.timestamp <= $._smConfig.unstakeWindowSeconds
    ) {
      return $._stakersCooldowns[owner].amount;
    }

    return 0;
  }

  function getMaxSlashableAssets() public view override returns (uint256) {
    uint256 currentAssets = totalAssets();
    return MIN_ASSETS_REMAINING > currentAssets ? 0 : currentAssets - MIN_ASSETS_REMAINING;
  }

  function decimals() public view override(ERC20Upgradeable, ERC4626Upgradeable) returns (uint8) {
    return ERC4626Upgradeable.decimals();
  }

  function _cooldown(address from) internal {
    uint256 amount = balanceOf(from);

    if (amount == 0) {
      revert ZeroBalanceOnCooldown();
    }

    StakeTokenStorage storage $ = _getStakeTokenStorage();

    uint32 timeForRedemption = (block.timestamp + $._smConfig.cooldownSeconds).toUint32();

    $._stakersCooldowns[from] = CooldownSnapshot({
      timestamp: timeForRedemption,
      amount: amount.toUint224()
    });

    emit Cooldown(from, amount);
  }

  function _setUnstakeWindow(uint256 newUnstakeWindow) internal {
    _getStakeTokenStorage()._smConfig.unstakeWindowSeconds = newUnstakeWindow.toUint32();

    emit UnstakeWindowChanged(newUnstakeWindow);
  }

  function _setCooldownSeconds(uint256 newCooldownSeconds) internal {
    _getStakeTokenStorage()._smConfig.unstakeWindowSeconds = newCooldownSeconds.toUint32();

    emit CooldownSecondsChanged(newCooldownSeconds);
  }

  function _updateExchangeRate(uint256 newExchangeRate) internal {
    if (newExchangeRate == 0) {
      revert ZeroExchangeRate();
    }

    _getStakeTokenStorage()._currentExchangeRate = newExchangeRate.toUint192();

    emit ExchangeRateChanged(newExchangeRate);
  }

  function _convertToShares(
    uint256 assets,
    Math.Rounding rounding
  ) internal view override returns (uint256) {
    StakeTokenStorage storage $ = _getStakeTokenStorage();
    return assets.mulDiv($._currentExchangeRate, EXCHANGE_RATE_UNIT, rounding);
  }

  function _convertToAssets(
    uint256 shares,
    Math.Rounding rounding
  ) internal view override returns (uint256) {
    StakeTokenStorage storage $ = _getStakeTokenStorage();
    return shares.mulDiv(EXCHANGE_RATE_UNIT, $._currentExchangeRate, rounding);
  }

  function _getExchangeRate(
    uint256 newTotalAssets,
    uint256 newTotalShares
  ) internal pure returns (uint256) {
    return newTotalShares.mulDiv(EXCHANGE_RATE_UNIT, newTotalAssets, Math.Rounding.Ceil);
  }

  // @pavelvm5 add from old stakeToken here handle action for reward controller
  function _update(
    address from,
    address to,
    uint256 value
  ) internal override(ERC20PausableUpgradeable, ERC20Upgradeable) whenNotPaused {
    super._update(from, to, value);
  }

  function _getStakeTokenStorage() internal pure returns (StakeTokenStorage storage $) {
    assembly {
      $.slot := StakeTokenStorageLocation
    }
  }
}
