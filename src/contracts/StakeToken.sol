// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from 'aave-v3-origin/core/contracts/interfaces/IPoolAddressesProvider.sol';
import {IAccessControl} from 'aave-v3-origin/core/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol';

import {UpgradableOwnableWithGuardian} from 'solidity-utils/contracts/access-control/UpgradableOwnableWithGuardian.sol';

import {Initializable} from 'openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol';
import {ERC20PermitUpgradeable, ERC20Upgradeable, IERC20Permit} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol';
import {ERC4626Upgradeable, IERC20Metadata, IERC20, Math, IERC4626} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol';
import {ERC20PausableUpgradeable} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PausableUpgradeable.sol';

import {IERC20 as SafeIERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';

import {IRewardsController} from './interfaces/IRewardsController.sol';
import {IStakeToken} from './interfaces/IStakeToken.sol';

contract StakeToken is
  Initializable,
  ERC20PermitUpgradeable,
  ERC20PausableUpgradeable,
  ERC4626Upgradeable,
  UpgradableOwnableWithGuardian,
  IStakeToken
{
  using SafeERC20 for SafeIERC20;
  using SafeCast for uint256;
  using Math for uint256;

  uint256 public constant MIN_ASSETS_REMAINING = 1e6;

  uint216 public constant INITIAL_EXCHANGE_RATE = 1e18;
  uint256 public constant EXCHANGE_RATE_UNIT = 1e18;

  IRewardsController public immutable REWARDS_CONTROLLER;
  IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

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

  function _getStakeTokenStorage() internal pure returns (StakeTokenStorage storage $) {
    assembly {
      $.slot := StakeTokenStorageLocation
    }
  }

  modifier onlySlashingAdmin() {
    if (
      !IAccessControl(ADDRESSES_PROVIDER.getACLManager()).hasRole('SLASHING_ADMIN', _msgSender())
    ) {
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
    address guardian,
    uint256 cooldown_,
    uint256 unstakeWindow_
  ) external virtual initializer {
    __ERC20_init(name, symbol);
    __ERC20Permit_init(name);
    __ERC20Pausable_init();
    __ERC4626_init(stakedToken);

    __Ownable_init(owner);
    __Ownable_With_Guardian_init(guardian);

    _setCooldown(cooldown_);
    _setUnstakeWindow(unstakeWindow_);
    _updateExchangeRate(INITIAL_EXCHANGE_RATE);
  }

  function slash(
    address destination,
    uint256 amount
  ) external onlySlashingAdmin whenNotPaused returns (uint256) {
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

  function depositWithPermit(
    uint256 assets,
    address receiver,
    uint256 deadline,
    SignatureParams memory sig
  ) public returns (uint256) {
    try
      IERC20Permit(asset()).permit(
        _msgSender(),
        address(this),
        assets,
        deadline,
        sig.v,
        sig.r,
        sig.s
      )
    {} catch {
      if (IERC20Metadata(asset()).allowance(msg.sender, address(this)) < assets) {
        revert PermitNotSucceded();
      }
    }

    return deposit(assets, receiver);
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

  function setUnstakeWindow(uint256 newUnstakeWindow) external onlyOwner {
    _setUnstakeWindow(newUnstakeWindow);
  }

  function setCooldown(uint256 newCooldown) external onlyOwner {
    _setCooldown(newCooldown);
  }

  function setPause(bool pause) external onlyOwnerOrGuardian {
    if (pause) {
      _pause();
    } else {
      _unpause();
    }
  }

  function getExchangeRate() external view returns (uint256) {
    return _getStakeTokenStorage()._currentExchangeRate;
  }

  function getCooldown() external view returns (uint256) {
    return _getStakeTokenStorage()._smConfig.cooldown;
  }

  function getUnstakeWindow() external view returns (uint256) {
    return _getStakeTokenStorage()._smConfig.unstakeWindow;
  }

  function getStakerCooldown(address user) external view returns (CooldownSnapshot memory) {
    return _getStakeTokenStorage()._stakerCooldown[user];
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
      return $._stakerCooldown[owner].amount;
    }

    return 0;
  }

  function getMaxSlashableAssets() public view returns (uint256) {
    uint256 currentAssets = totalAssets();
    return MIN_ASSETS_REMAINING > currentAssets ? 0 : currentAssets - MIN_ASSETS_REMAINING;
  }

  function decimals()
    public
    view
    override(ERC20Upgradeable, ERC4626Upgradeable, IERC20Metadata)
    returns (uint8)
  {
    return ERC4626Upgradeable.decimals();
  }

  function _cooldown(address from) internal whenNotPaused {
    uint256 amount = balanceOf(from);

    if (amount == 0) {
      revert ZeroBalanceInStaking();
    }

    StakeTokenStorage storage $ = _getStakeTokenStorage();

    uint32 timeForRedemption = (block.timestamp + $._smConfig.cooldown).toUint32();

    $._stakerCooldown[from] = CooldownSnapshot({
      timestamp: timeForRedemption,
      amount: amount.toUint224()
    });

    emit Cooldown(from, amount, timeForRedemption);
  }

  function _setUnstakeWindow(uint256 newUnstakeWindow) internal {
    _getStakeTokenStorage()._smConfig.unstakeWindow = newUnstakeWindow.toUint32();

    emit UnstakeWindowChanged(newUnstakeWindow);
  }

  function _setCooldown(uint256 newCooldown) internal {
    _getStakeTokenStorage()._smConfig.cooldown = newCooldown.toUint32();

    emit CooldownChanged(newCooldown);
  }

  function _updateExchangeRate(uint256 newExchangeRate) internal {
    if (newExchangeRate == 0) {
      revert ZeroExchangeRate();
    }

    _getStakeTokenStorage()._currentExchangeRate = newExchangeRate.toUint192();

    emit ExchangeRateChanged(newExchangeRate);
  }

  function _update(
    address from,
    address to,
    uint256 value
  ) internal override(ERC20PausableUpgradeable, ERC20Upgradeable) whenNotPaused {
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
      CooldownSnapshot memory previousSenderCooldown = $._stakerCooldown[from];

      if (previousSenderCooldown.timestamp != 0) {
        if (to == address(0)) {
          // redeem
          if (previousSenderCooldown.amount == value) {
            delete $._stakerCooldown[from];
          } else {
            $._stakerCooldown[from].amount = (previousSenderCooldown.amount - value).toUint224();
          }
        } else {
          // transfer
          uint224 balanceAfter = (balanceOfFrom - value).toUint224();

          if (balanceAfter == 0) {
            delete $._stakerCooldown[from];
          } else if (balanceAfter < previousSenderCooldown.amount) {
            $._stakerCooldown[from].amount = balanceAfter;
          }
        }
      }
    }

    super._update(from, to, value);
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
}
