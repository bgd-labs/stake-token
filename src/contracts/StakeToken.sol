// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Initializable} from 'openzeppelin-contracts/contracts/proxy/utils/Initializable.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';
import {IERC20Metadata} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {IERC20Permit} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol';
import {Rescuable} from 'solidity-utils/contracts/utils/Rescuable.sol';

import {ERC20Permit} from './ERC20Permit.sol';
import {IStakeToken} from './IStakeToken.sol';
import {IRewardsController} from './IRewardsController.sol';

import {PercentageMath} from './lib/PercentageMath.sol';

contract StakeToken is ERC20Permit, IStakeToken, Rescuable {
  using SafeERC20 for IERC20;
  using PercentageMath for uint256;
  using SafeCast for uint256;
  using SafeCast for uint104;

  uint216 public constant INITIAL_EXCHANGE_RATE = 1e18;
  uint256 public constant EXCHANGE_RATE_UNIT = 1e18;

  IERC20 public immutable STAKED_TOKEN;

  IRewardsController public immutable REWARDS_CONTROLLER;

  mapping(address => uint256) public stakerRewardsToClaim;
  mapping(address => CooldownSnapshot) public stakersCooldowns;

  CooldownConfig internal _cooldownConfig;
  /// @notice Mirror of latest snapshot value for cheaper access
  uint216 internal _currentExchangeRate;

  // TODO: might instead use ACL to allow multiple slashing admins etc
  address internal slashingAdmin;

  /// @notice minimum of funds that should remain after slashing to prevent excessive rounding issues
  uint256 public minAssetsRemaining;

  modifier onlySlashingAdmin() {
    require(msg.sender == slashingAdmin, 'CALLER_NOT_SLASHING_ADMIN');
    _;
  }

  constructor(
    string memory name,
    IERC20 stakedToken,
    IRewardsController rewardsController
  ) ERC20Permit(name) {
    uint256 decimals = IERC20Metadata(address(stakedToken)).decimals();
    STAKED_TOKEN = stakedToken;
    REWARDS_CONTROLLER = rewardsController;
  }

  function initialize(
    string calldata name,
    string calldata symbol,
    address newSlashingAdmin,
    uint256 cooldownSeconds,
    uint256 unstakeWindow
  ) external virtual initializer {
    _initializeMetadata(name, symbol);
    _transferOwnership(newSlashingAdmin);
    _setSlashingAdmin(newSlashingAdmin);
    _setCooldownSeconds(cooldownSeconds);
    _setUnstakeWindow(unstakeWindow);
    _updateExchangeRate(INITIAL_EXCHANGE_RATE);
    minAssetsRemaining = 10 ** decimals();
  }

  // TODO: reconsider as might not be needed with custom deployment
  // compatibility for RewardsController
  function scaledTotalSupply() external view returns (uint256) {
    return totalSupply();
  }

  function whoCanRescue() public view override returns (address) {
    return owner();
  }

  function setUnstakeWindow(uint256 newUnstakeWindow) external onlyOwner {
    _setUnstakeWindow(newUnstakeWindow);
  }

  function _setUnstakeWindow(uint256 newUnstakeWindow) internal {
    _cooldownConfig.unstakeWindowSeconds = newUnstakeWindow.toUint32();
    emit UnstakeWindowChanged(newUnstakeWindow);
  }

  function getUnstakeWindow() external view returns (uint256) {
    return _cooldownConfig.unstakeWindowSeconds;
  }

  function setSlashingAdmin(address newSlashingAdmin) external onlyOwner {
    _setSlashingAdmin(newSlashingAdmin);
  }

  function _setSlashingAdmin(address newSlashingAdmin) internal {
    slashingAdmin = newSlashingAdmin;
    emit SlashingAdminChanged(newSlashingAdmin);
  }

  /// @inheritdoc IStakeToken
  function previewStake(uint256 assets) public view returns (uint256) {
    return (assets * _currentExchangeRate) / EXCHANGE_RATE_UNIT;
  }

  /// @inheritdoc IStakeToken
  function stake(address to, uint256 amount) external {
    _stake(msg.sender, to, amount);
  }

  /// @inheritdoc IStakeToken
  function stakeWithPermit(
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    try
      IERC20Permit(address(STAKED_TOKEN)).permit(
        msg.sender,
        address(this),
        amount,
        deadline,
        v,
        r,
        s
      )
    {
      // do nothing
    } catch (bytes memory) {
      // do nothing
    }
    _stake(msg.sender, msg.sender, amount);
  }

  /// @inheritdoc IStakeToken
  function cooldown() external {
    _cooldown(msg.sender);
  }

  /// @inheritdoc IStakeToken
  function cooldownOnBehalfOf(address from) external onlyOwner {
    _cooldown(from);
  }

  /// @inheritdoc IStakeToken
  function redeem(address to, uint256 amount) external {
    _redeem(msg.sender, to, amount.toUint104());
  }

  /// @inheritdoc IStakeToken
  function redeemOnBehalf(address from, address to, uint256 amount) external onlyOwner {
    _redeem(from, to, amount.toUint104());
  }

  /// @inheritdoc IStakeToken
  function getExchangeRate() public view returns (uint216) {
    return _currentExchangeRate;
  }

  /// @inheritdoc IStakeToken
  function previewRedeem(uint256 shares) public view returns (uint256) {
    return (EXCHANGE_RATE_UNIT * shares) / _currentExchangeRate;
  }

  ///@inheritdoc IStakeToken
  function totalAssets() public view returns (uint256) {
    uint256 currentShares = totalSupply();
    return previewRedeem(currentShares);
  }

  /// @inheritdoc IStakeToken
  function slash(address destination, uint256 amount) external onlySlashingAdmin returns (uint256) {
    require(amount > 0, 'ZERO_AMOUNT');
    uint256 maxSlashable = getMaxSlashable();
    require(maxSlashable > 0, 'ZERO_FUNDS_AVAILABLE');
    if (amount > maxSlashable) {
      amount = maxSlashable;
    }

    uint256 currentShares = totalSupply();
    uint256 balance = previewRedeem(currentShares);
    _updateExchangeRate(_getExchangeRate(balance - amount, currentShares));

    STAKED_TOKEN.safeTransfer(destination, amount);

    emit Slashed(destination, amount);
    return amount;
  }

  function getMaxSlashable() public view returns (uint256) {
    uint256 currentAssets = totalAssets();
    uint256 cachedMin = minAssetsRemaining;
    return cachedMin > currentAssets ? 0 : currentAssets - cachedMin;
  }

  /// @inheritdoc IStakeToken
  function setCooldownSeconds(uint256 cooldownSeconds) external onlyOwner {
    _setCooldownSeconds(cooldownSeconds);
  }

  /// @inheritdoc IStakeToken
  function getCooldownSeconds() external view returns (uint256) {
    return _cooldownConfig.cooldownSeconds;
  }

  function _cooldown(address from) internal {
    uint256 amount = balanceOf(from);
    require(amount != 0, 'INVALID_BALANCE_ON_COOLDOWN');
    stakersCooldowns[from] = CooldownSnapshot({
      timestamp: uint40(block.timestamp),
      amount: uint216(amount)
    });

    emit Cooldown(from, amount);
  }

  /**
   * @dev sets the cooldown seconds
   * @param cooldownSeconds the new amount of cooldown seconds
   */
  function _setCooldownSeconds(uint256 cooldownSeconds) internal {
    _cooldownConfig.cooldownSeconds = cooldownSeconds.toUint32();
    emit CooldownSecondsChanged(cooldownSeconds);
  }

  /**
   * @dev Allows staking a specified amount of STAKED_TOKEN
   * @param to The address to receiving the shares
   * @param amount The amount of assets to be staked
   */
  function _stake(address from, address to, uint256 amount) internal {
    require(amount != 0, 'INVALID_ZERO_AMOUNT');

    uint256 sharesToMint = previewStake(amount);
    require(sharesToMint != 0, 'INVALID_ZERO_AMOUNT_AFTER_CONVERSION');

    _mint(to, sharesToMint.toUint104());

    STAKED_TOKEN.safeTransferFrom(from, address(this), amount);

    emit Staked(from, to, amount, sharesToMint);
  }

  /**
   * @dev Redeems staked tokens, and stop earning rewards
   * @param from Address to redeem from
   * @param to Address to redeem to
   * @param amount Amount to redeem
   */
  function _redeem(address from, address to, uint104 amount) internal {
    require(amount != 0, 'INVALID_ZERO_AMOUNT');

    CooldownSnapshot memory cooldownSnapshot = stakersCooldowns[from];
    CooldownConfig memory cachedCooldownConfig = _cooldownConfig;
    require(
      (block.timestamp >= cooldownSnapshot.timestamp + cachedCooldownConfig.cooldownSeconds),
      'INSUFFICIENT_COOLDOWN'
    );
    require(
      (block.timestamp - (cooldownSnapshot.timestamp + cachedCooldownConfig.cooldownSeconds) <=
        cachedCooldownConfig.unstakeWindowSeconds),
      'UNSTAKE_WINDOW_FINISHED'
    );

    uint256 maxRedeemable = cooldownSnapshot.amount;
    require(maxRedeemable != 0, 'INVALID_ZERO_MAX_REDEEMABLE');

    uint256 amountToRedeem = (amount > maxRedeemable) ? maxRedeemable : amount;

    uint256 underlyingToRedeem = previewRedeem(amountToRedeem);

    _burn(from, amountToRedeem.toUint104());

    IERC20(STAKED_TOKEN).safeTransfer(to, underlyingToRedeem);

    emit Redeem(from, to, underlyingToRedeem, amountToRedeem);
  }

  /**
   * @dev Updates the exchangeRate and emits events accordingly
   * @param newExchangeRate the new exchange rate
   */
  function _updateExchangeRate(uint216 newExchangeRate) internal virtual {
    require(newExchangeRate != 0, 'ZERO_EXCHANGE_RATE');
    _currentExchangeRate = newExchangeRate;
    emit ExchangeRateChanged(newExchangeRate);
  }

  /**
   * @dev calculates the exchange rate based on totalAssets and totalShares
   * @dev always rounds up to ensure 100% backing of shares by rounding in favor of the contract
   * @param totalAssets The total amount of assets staked
   * @param totalShares The total amount of shares
   * @return exchangeRate as 18 decimal precision uint216
   */
  function _getExchangeRate(
    uint256 totalAssets,
    uint256 totalShares
  ) internal pure returns (uint216) {
    return (((totalShares * EXCHANGE_RATE_UNIT) + totalAssets - 1) / totalAssets).toUint216();
  }

  function _update(address from, address to, uint256 amount) internal override {
    uint256 cachedTotalSupply = totalSupply();
    // stake & transfer
    if (to != address(0)) {
      uint256 balanceOfTo = balanceOf(to);
      REWARDS_CONTROLLER.handleAction(to, cachedTotalSupply, balanceOfTo);
    }
    // redeem & transfer
    if (from != address(0) && from != to) {
      uint256 balanceOfFrom = balanceOf(from);
      // Sender
      REWARDS_CONTROLLER.handleAction(from, cachedTotalSupply, balanceOfFrom);
      CooldownSnapshot memory previousSenderCooldown = stakersCooldowns[from];
      if (previousSenderCooldown.timestamp != 0) {
        // update to 0 means redeem
        // this is based on the assumption that erc20 forbids transfer to 0
        if (to == address(0)) {
          if (previousSenderCooldown.amount <= amount) {
            delete stakersCooldowns[from];
          } else {
            stakersCooldowns[from].amount = uint216(previousSenderCooldown.amount - amount);
          }
        } else {
          uint256 balanceAfter = balanceOfFrom - amount;
          if (balanceAfter == 0) {
            delete stakersCooldowns[from];
          } else if (balanceAfter < previousSenderCooldown.amount) {
            stakersCooldowns[from].amount = uint216(balanceAfter);
          }
        }
      }
    }

    super._update(from, to, amount);
  }
}
