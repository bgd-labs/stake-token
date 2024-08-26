// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Initializable} from 'openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol';
import {OwnableUpgradeable} from 'openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol';
import {PausableUpgradeable} from 'openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol';
import {ERC20Upgradeable} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol';
import {ERC20PermitUpgradeable} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol';
import {ERC4626Upgradeable} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol';

import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {IERC20Permit} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol';
import {IERC20Metadata} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import {Rescuable, IRescuable} from 'solidity-utils/contracts/utils/Rescuable.sol';

import {IERC4626StakeToken} from './interfaces/IERC4626StakeToken.sol';
import {IRewardsController} from './interfaces/IRewardsController.sol';
import {ERC4626StakeTokenUpgradeable} from './extension/ERC4626StakeTokenUpgradeable.sol';

/**
 * @title StakeToken
 * @notice StakeToken is an `ERC-4626` contract that aims to supply assets as debt repayment in the event of a `Bad Debt`.
 * Stakers will be paid rewards through `REWARDS_CONTROLLER` for providing underlying assets. In a situation where a `Bad Debt`
 * exceeds a threshold value, the `slash()` function will be called, which will take the part of the assets
 * necessary for repayment from this vault and transfer them to the desired address.
 * @author BGD labs
 */
contract StakeToken is
  Initializable,
  PausableUpgradeable,
  ERC20PermitUpgradeable,
  ERC4626StakeTokenUpgradeable,
  OwnableUpgradeable,
  Rescuable
{
  constructor(
    IRewardsController rewardsController
  ) ERC4626StakeTokenUpgradeable(rewardsController) {
    _disableInitializers();
  }

  function initialize(
    IERC20 stakedToken,
    string calldata name,
    string calldata symbol,
    address owner,
    uint256 cooldown_,
    uint256 unstakeWindow_
  ) external initializer {
    __ERC20_init(name, symbol);
    __ERC20Permit_init(name);

    __Pausable_init();

    __Ownable_init(owner);

    __StakeTokenUpgradeable_init(stakedToken, cooldown_, unstakeWindow_);
  }

  /// @inheritdoc IERC4626StakeToken
  function depositWithPermit(
    uint256 assets,
    address receiver,
    uint256 deadline,
    SignatureParams memory sig
  ) external returns (uint256) {
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
    {} catch {}

    return deposit(assets, receiver);
  }

  /// @inheritdoc IERC4626StakeToken
  function pause() external onlyOwner {
    _pause();
  }

  /// @inheritdoc IERC4626StakeToken
  function unpause() external onlyOwner {
    _unpause();
  }

  /// @inheritdoc IERC4626StakeToken
  function slash(
    address destination,
    uint256 amount
  ) external override onlyOwner returns (uint256) {
    return _slash(destination, amount);
  }

  /// @inheritdoc IERC4626StakeToken
  function setUnstakeWindow(uint256 newUnstakeWindow) external override onlyOwner {
    _setUnstakeWindow(newUnstakeWindow);
  }

  /// @inheritdoc IERC4626StakeToken
  function setCooldown(uint256 newCooldown) external override onlyOwner {
    _setCooldown(newCooldown);
  }

  /// @inheritdoc IRescuable
  function whoCanRescue() public view override returns (address) {
    return owner();
  }

  function decimals()
    public
    view
    override(ERC20Upgradeable, ERC4626Upgradeable, IERC20Metadata)
    returns (uint8)
  {
    return super.decimals();
  }

  function _update(
    address from,
    address to,
    uint256 value
  ) internal override(ERC20Upgradeable, ERC4626StakeTokenUpgradeable) whenNotPaused {
    super._update(from, to, value);
  }

  function _slash(
    address destination,
    uint256 amount
  ) internal override whenNotPaused returns (uint256) {
    return super._slash(destination, amount);
  }

  function _cooldown(address from) internal override whenNotPaused {
    super._cooldown(from);
  }
}
