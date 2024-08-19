// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {IERC20Permit} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol';
import {IERC20Metadata} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import {IERC4626} from 'openzeppelin-contracts/contracts/interfaces/IERC4626.sol';

import {IAccessControl} from 'openzeppelin-contracts/contracts/access/IAccessControl.sol';

import {IPoolAddressesProvider} from './interfaces/IPoolAddressesProvider.sol';
import {IRewardsController} from './interfaces/IRewardsController.sol';

import {Initializable} from 'openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol';
import {ERC20Upgradeable} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol';
import {ERC20PausableUpgradeable} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PausableUpgradeable.sol';
import {ERC20PermitUpgradeable} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol';
import {ERC4626Upgradeable} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol';

import {UpgradeableOwnableWithGuardian} from 'solidity-utils/contracts/access-control/UpgradeableOwnableWithGuardian.sol';

import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';
import {Math} from 'openzeppelin-contracts/contracts/utils/math/Math.sol';

import {StakeTokenUpgradeable} from './extension/StakeTokenUpgradeable.sol';

contract StakeToken is
  Initializable,
  ERC20PausableUpgradeable,
  ERC20PermitUpgradeable,
  ERC4626Upgradeable,
  UpgradeableOwnableWithGuardian,
  StakeTokenUpgradeable
{
  using SafeERC20 for IERC20;
  using SafeCast for uint256;
  using Math for uint256;

  uint256 public constant MIN_ASSETS_REMAINING = 1e6;

  IRewardsController public immutable REWARDS_CONTROLLER;
  IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

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
    __ERC20Pausable_init();
    __ERC20Permit_init(name);

    __ERC4626_init(stakedToken);

    __Ownable_init(owner);
    __Ownable_With_Guardian_init(guardian);

    __StakeTokenUpgradable_init(cooldown_.toUint32(), unstakeWindow_.toUint32());
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

    _updateExchangeRate(_getExchangeRate(balance - amount, currentShares).toUint192());

    IERC20(asset()).safeTransfer(destination, amount);

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
      if (IERC20(asset()).allowance(msg.sender, address(this)) < assets) {
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
    _setUnstakeWindow(newUnstakeWindow.toUint32());
  }

  function setCooldown(uint256 newCooldown) external onlyOwner {
    _setCooldown(newCooldown.toUint32());
  }

  function pause() external onlyOwnerOrGuardian {
    _pause();
  }

  function unpause() external onlyOwnerOrGuardian {
    _unpause();
  }

  function maxWithdraw(
    address owner
  ) public view override(ERC4626Upgradeable, IERC4626) returns (uint256) {
    return _convertToAssets(maxRedeem(owner), Math.Rounding.Floor);
  }

  function maxRedeem(
    address owner
  ) public view override(ERC4626Upgradeable, IERC4626) returns (uint256) {
    SmConfig memory smConfig = getSmConfig();
    CooldownSnapshot memory cooldownSnapshot = getStakerCooldown(owner);

    if (
      block.timestamp >= cooldownSnapshot.timestamp &&
      block.timestamp - cooldownSnapshot.timestamp <= smConfig.unstakeWindow
    ) {
      return cooldownSnapshot.amount;
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
    return super.decimals();
  }

  function _cooldown(address from) internal whenNotPaused {
    uint256 amount = balanceOf(from);

    if (amount == 0) {
      revert ZeroBalanceInStaking();
    }

    SmConfig memory smConfig = getSmConfig();

    uint32 timeToUnlock = (block.timestamp + smConfig.cooldown).toUint32();

    _setStakerCooldown(from, amount.toUint224(), timeToUnlock);
  }

  function _update(
    address from,
    address to,
    uint256 value
  ) internal override(ERC20PausableUpgradeable, ERC20Upgradeable) {
    uint256 cachedTotalSupply = totalSupply();

    // stake & transfer
    if (to != address(0)) {
      REWARDS_CONTROLLER.handleAction(to, cachedTotalSupply, balanceOf(to));
    }

    // redeem & transfer
    if (from != address(0) && from != to) {
      uint256 balanceOfFrom = balanceOf(from);
      REWARDS_CONTROLLER.handleAction(from, cachedTotalSupply, balanceOfFrom);

      CooldownSnapshot memory cooldownSnapshot = getStakerCooldown(from);

      if (cooldownSnapshot.timestamp != 0) {
        if (to == address(0)) {
          // redeem
          if (cooldownSnapshot.amount == value) {
            _deleteStakerCooldown(from);
          } else {
            _setStakerCooldownAmount(from, (cooldownSnapshot.amount - value.toUint224()));
          }
        } else {
          // transfer
          uint224 balanceAfter = (balanceOfFrom - value).toUint224();

          if (balanceAfter == 0) {
            _deleteStakerCooldown(from);
          } else if (balanceAfter < cooldownSnapshot.amount) {
            _setStakerCooldownAmount(from, balanceAfter);
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
    return assets.mulDiv(getExchangeRate(), EXCHANGE_RATE_UNIT, rounding);
  }

  function _convertToAssets(
    uint256 shares,
    Math.Rounding rounding
  ) internal view override returns (uint256) {
    return shares.mulDiv(EXCHANGE_RATE_UNIT, getExchangeRate(), rounding);
  }
}
