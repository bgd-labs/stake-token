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

import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';

contract StakeToken is IStakeToken, Initializable, ERC20PermitUpgradeable, ERC20PausableUpgradeable, ERC4626Upgradeable, UpgradableOwnableWithGuardian {
  using SafeCast for uint256;
  using Math for uint256;

  // @audit-high @pavelvm5 this mechanic won't work at all if we will slash max amount, then deposit 1e18 and try to slash again we will have zero exchange_rate anyway
  // should be 1e18 or smth like that, due to the fact that we will use mostly stata-tokens
  uint256 public constant MIN_ASSETS_REMAINING = 1e4;

  uint216 public constant INITIAL_EXCHANGE_RATE = 1e18;
  uint256 public constant EXCHANGE_RATE_UNIT = 1e18;

  // keccak256(abi.encode(uint256(keccak256("aave.storage.StakeToken")) - 1)) & ~bytes32(uint256(0xff))
  bytes32 private constant StakeTokenStorageLocation =
    0x570b5e9089e57b3d227cfcd747a97877e3c5f12150099d7b38848c6202ca0a00;

  IRewardsController public immutable REWARDS_CONTROLLER;
  IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

  modifier onlySlashingAdmin() {
    require(
      IAccessControl(ADDRESSES_PROVIDER.getACLManager()).hasRole('SLASHING_ADMIN', msg.sender),
      'CALLER_NOT_SLASHING_ADMIN'
    );
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

  function slash(address destination, uint256 amount) external override returns (uint256) {}

  function cooldown() external override whenNotPaused {
    _cooldown(msg.sender);
  }

  function cooldownOnBehalfOf(address from) external override onlyOwner whenNotPaused {
    _cooldown(from);
  }

  // @pavelvm5 todo delete or add functionality
  function redeemOnBehalf(address from, address to, uint256 amount) external override onlyOwner {}

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

  function decimals()
    public
    view
    override(ERC20Upgradeable, ERC4626Upgradeable)
    returns (uint8)
  {
    return ERC4626Upgradeable.decimals();
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

  function maxWithdraw(address owner) public view override returns (uint256) {
    return _convertToAssets(_getStakeTokenStorage()._stakersCooldowns[owner].amount, Math.Rounding.Floor);
  }

  function maxRedeem(address owner) public view override returns (uint256) {
    return _getStakeTokenStorage()._stakersCooldowns[owner].amount;
  }

  function stakersCooldowns(
    address user
  ) external view override returns (CooldownSnapshot memory) {
    return _getStakeTokenStorage()._stakersCooldowns[user];
  }

  function getMaxSlashableAssets() external view override returns (uint256) {
    uint256 currentAssets = totalAssets();
    return MIN_ASSETS_REMAINING > currentAssets ? 0 : currentAssets - MIN_ASSETS_REMAINING;
  }

  function _cooldown(address from) internal {
    uint256 amount = balanceOf(from);

    require(amount != 0, 'INVALID_BALANCE_ON_COOLDOWN');

    StakeTokenStorage storage $ = _getStakeTokenStorage();

    uint40 timeForRedemption = (block.timestamp + $._smConfig.cooldownSeconds).toUint40();

    $._stakersCooldowns[from] = CooldownSnapshot({
      timestamp: timeForRedemption,
      amount: uint216(amount)
    });

    emit Cooldown(from, amount);
  }

  function _setUnstakeWindow(uint256 newUnstakeWindow) internal {
    _getStakeTokenStorage()._smConfig.unstakeWindowSeconds = newUnstakeWindow.toUint40();

    emit UnstakeWindowChanged(newUnstakeWindow);
  }

  function _setCooldownSeconds(uint256 newCooldownSeconds) internal {
    _getStakeTokenStorage()._smConfig.unstakeWindowSeconds = newCooldownSeconds.toUint40();

    emit CooldownSecondsChanged(newCooldownSeconds);
  }

  function _updateExchangeRate(uint216 newExchangeRate) internal {
    require(newExchangeRate != 0, 'ZERO_EXCHANGE_RATE');

    _getStakeTokenStorage()._currentExchangeRate = newExchangeRate;

    emit ExchangeRateChanged(newExchangeRate);
  }

  function _convertToShares(uint256 assets, Math.Rounding rounding) internal view override returns (uint256) {
    StakeTokenStorage storage $ = _getStakeTokenStorage();
    return assets.mulDiv($._currentExchangeRate, EXCHANGE_RATE_UNIT, rounding);
  }

  function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view override returns (uint256) {
    StakeTokenStorage storage $ = _getStakeTokenStorage();
    return shares.mulDiv(EXCHANGE_RATE_UNIT, $._currentExchangeRate, rounding);
  }

  // @pavelvm5 add from old stakeToken here
  function _update(address from, address to, uint256 value) internal override(ERC20PausableUpgradeable, ERC20Upgradeable) whenNotPaused {
    super._update(from, to, value);
  }

  function _getStakeTokenStorage() internal pure returns (StakeTokenStorage storage $) {
    assembly {
      $.slot := StakeTokenStorageLocation
    }
  }
}