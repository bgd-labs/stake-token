// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {IERC20Permit} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol';
import {IERC20Metadata} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import {IAccessControl} from 'openzeppelin-contracts/contracts/access/IAccessControl.sol';

import {IPoolAddressesProvider} from './interfaces/IPoolAddressesProvider.sol';
import {IRewardsController} from './interfaces/IRewardsController.sol';

import {Initializable} from 'openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol';
import {ERC20Upgradeable} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol';
import {ERC20PausableUpgradeable} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PausableUpgradeable.sol';
import {ERC20PermitUpgradeable} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol';
import {ERC4626Upgradeable} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol';

import {UpgradeableOwnableWithGuardian} from 'solidity-utils/contracts/access-control/UpgradeableOwnableWithGuardian.sol';

import {StakeTokenUpgradeable} from './extension/StakeTokenUpgradeable.sol';

contract StakeToken is
  Initializable,
  ERC20PausableUpgradeable,
  ERC20PermitUpgradeable,
  UpgradeableOwnableWithGuardian,
  StakeTokenUpgradeable
{
  IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

  modifier onlySlashingAdmin() {
    if (
      !IAccessControl(ADDRESSES_PROVIDER.getACLManager()).hasRole('SLASHING_ADMIN', _msgSender())
    ) {
      revert CallerIsNotSlashingAdmin();
    }
    _;
  }

  constructor(
    IRewardsController rewardsController,
    IPoolAddressesProvider provider
  ) StakeTokenUpgradeable(rewardsController) {
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
  ) external initializer {
    __ERC20_init(name, symbol);
    __ERC20Pausable_init();
    __ERC20Permit_init(name);

    __Ownable_init(owner);
    __Ownable_With_Guardian_init(guardian);

    __StakeTokenUpgradable_init(stakedToken, cooldown_, unstakeWindow_);
  }

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
    {} catch {
      if (IERC20(asset()).allowance(msg.sender, address(this)) < assets) {
        revert PermitNotSucceded();
      }
    }

    return deposit(assets, receiver);
  }

  function slash(
    address destination,
    uint256 amount
  ) external onlySlashingAdmin whenNotPaused returns (uint256) {
    return _slash(destination, amount);
  }

  function setUnstakeWindow(uint256 newUnstakeWindow) external onlyOwner {
    _setUnstakeWindow(newUnstakeWindow);
  }

  function setCooldown(uint256 newCooldown) external onlyOwner {
    _setCooldown(newCooldown);
  }

  function pause() external onlyOwnerOrGuardian {
    _pause();
  }

  function unpause() external onlyOwnerOrGuardian {
    _unpause();
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
  ) internal override(ERC20PausableUpgradeable, ERC20Upgradeable) {
    _handleAction(from, to, value);

    super._update(from, to, value);
  }

  function _cooldown(address from) internal override whenNotPaused {
    super._cooldown(from);
  }
}
