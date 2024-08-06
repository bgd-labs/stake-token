// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Initializable} from 'openzeppelin-contracts/contracts/proxy/utils/Initializable.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';
import {IERC20Metadata} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {IERC20Permit} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol';
import {IERC4626} from 'openzeppelin-contracts/contracts/interfaces/IERC4626.sol';
import {Rescuable} from 'solidity-utils/contracts/utils/Rescuable.sol';
import {Math} from 'openzeppelin-contracts/contracts/utils/math/Math.sol';

import {IPoolAddressesProvider} from 'aave-v3-origin/core/contracts/interfaces/IPoolAddressesProvider.sol';
import {IAccessControl} from 'aave-v3-origin/core/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol';

import {PercentageMath} from './lib/PercentageMath.sol';

import {ERC20PermitUpgradeable} from './ERC20PermitUpgradeable.sol';
import {ERC20Upgradeable} from './ERC20Upgradeable.sol';
import {IStakeToken} from './interfaces/IStakeToken.sol';
import {IRewardsController} from './interfaces/IRewardsController.sol';

contract StakeToken is ERC20PermitUpgradeable, IStakeToken, Rescuable {
  using Math for uint256;
  using SafeERC20 for IERC20;
  using PercentageMath for uint256;
  using SafeCast for uint256;
  using SafeCast for uint104;

  uint216 public constant INITIAL_EXCHANGE_RATE = 1e18;
  uint256 public constant EXCHANGE_RATE_UNIT = 1e18;

  IRewardsController public immutable REWARDS_CONTROLLER;
  IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

  /// @custom:storage-location erc7201:aave.storage.StakeToken
  struct StakeTokenStorage {
    mapping(address => CooldownSnapshot) _stakersCooldowns;
    SmConfig _smConfig;
    /// @notice Current exchangeRate of the stk
    uint216 _currentExchangeRate;
    /// @notice minimum of funds that should remain after slashing to prevent excessive rounding issues
    uint256 _minAssetsRemaining;
  }

  // keccak256(abi.encode(uint256(keccak256("aave.storage.StakeToken")) - 1)) & ~bytes32(uint256(0xff))
  bytes32 private constant StakeTokenStorageLocation =
    0x570b5e9089e57b3d227cfcd747a97877e3c5f12150099d7b38848c6202ca0a00;

  modifier onlySlashingAdmin() {
    require(
      IAccessControl(ADDRESSES_PROVIDER.getACLManager()).hasRole('SLASHING_ADMIN', msg.sender),
      'CALLER_NOT_SLASHING_ADMIN'
    );
    _;
  }

  function _getStakeTokenStorage() private pure returns (StakeTokenStorage storage $) {
    assembly {
      $.slot := StakeTokenStorageLocation
    }
  }

  /// @inheritdoc IStakeToken
  function stakersCooldowns(address user) public view returns (CooldownSnapshot memory) {
    StakeTokenStorage storage $ = _getStakeTokenStorage();
    return $._stakersCooldowns[user];
  }

  constructor(IRewardsController rewardsController, IPoolAddressesProvider provider) {
    REWARDS_CONTROLLER = rewardsController;
    ADDRESSES_PROVIDER = provider;
    _disableInitializers();
  }

  function initialize(
    address stakedToken,
    string calldata name,
    string calldata symbol,
    address owner,
    uint256 cooldownSeconds,
    uint256 unstakeWindow,
    uint256 minAssetsRemaining
  ) external virtual initializer {
    _initialize(
      stakedToken,
      name,
      symbol,
      owner,
      cooldownSeconds,
      unstakeWindow,
      minAssetsRemaining
    );
  }

  function _initialize(
    address stakedToken,
    string calldata name,
    string calldata symbol,
    address owner,
    uint256 cooldownSeconds,
    uint256 unstakeWindow,
    uint256 minAssetsRemaining
  ) internal onlyInitializing {
    StakeTokenStorage storage $ = _getStakeTokenStorage();
    $._smConfig.stakedToken = stakedToken;
    __ERC20_init(name, symbol); // TODO: should naming be inherited from underlying or not?
    __Ownable_init(owner);
    __EIP712_init(string(abi.encodePacked('stk', name)), '1');
    _setCooldownSeconds(cooldownSeconds);
    _setUnstakeWindow(unstakeWindow);
    _updateExchangeRate(INITIAL_EXCHANGE_RATE);
    _setMinAssetsRemaining(minAssetsRemaining);
  }

  function setPaused(bool paused) external onlyOwnerOrGuardian {
    if (paused) _pause();
    else _unpause();
  }

  function decimals() public view override(IERC20Metadata, ERC20Upgradeable) returns (uint8) {
    StakeTokenStorage storage $ = _getStakeTokenStorage();
    return IERC20Metadata($._smConfig.stakedToken).decimals();
  }

  /// @inheritdoc IERC4626
  function asset() public view override(IERC4626) returns (address) {
    StakeTokenStorage storage $ = _getStakeTokenStorage();
    return $._smConfig.stakedToken;
  }

  ///@inheritdoc IERC4626
  function totalAssets() public view override(IERC4626) returns (uint256) {
    uint256 currentShares = totalSupply();
    return previewRedeem(currentShares);
  }

  // TODO: reconsider as might not be needed with custom deployment
  // compatibility for RewardsController
  function scaledTotalSupply() external view returns (uint256) {
    return totalSupply();
  }

  ///@inheritdoc IERC4626
  function maxDeposit(address) external pure override returns (uint256) {
    return type(uint256).max;
  }

  ///@inheritdoc IERC4626
  function maxMint(address) external pure override returns (uint256) {
    return type(uint256).max;
  }

  ///@inheritdoc IERC4626
  function maxWithdraw(address owner) external view override returns (uint256) {
    StakeTokenStorage storage $ = _getStakeTokenStorage();
    return previewRedeem($._stakersCooldowns[owner].amount);
  }

  ///@inheritdoc IERC4626
  function maxRedeem(address owner) external view override returns (uint256) {
    StakeTokenStorage storage $ = _getStakeTokenStorage();
    return $._stakersCooldowns[owner].amount;
  }

  function whoCanRescue() public view override returns (address) {
    return owner();
  }

  function setUnstakeWindow(uint256 newUnstakeWindow) external onlyOwner {
    _setUnstakeWindow(newUnstakeWindow);
  }

  function _setUnstakeWindow(uint256 newUnstakeWindow) internal {
    StakeTokenStorage storage $ = _getStakeTokenStorage();

    $._smConfig.unstakeWindowSeconds = newUnstakeWindow.toUint40();

    emit UnstakeWindowChanged(newUnstakeWindow);
  }

  function getUnstakeWindow() external view returns (uint256) {
    StakeTokenStorage storage $ = _getStakeTokenStorage();

    return $._smConfig.unstakeWindowSeconds;
  }

  ///@inheritdoc IERC4626
  function convertToShares(uint256 assets) external view override returns (uint256) {
    return _convertToShares(assets, Math.Rounding.Floor);
  }

  ///@inheritdoc IERC4626
  function convertToAssets(uint256 shares) external view override returns (uint256) {
    return _convertToAssets(shares, Math.Rounding.Floor);
  }

  ///@inheritdoc IERC4626
  function previewDeposit(uint256 assets) external view override returns (uint256) {
    return _convertToShares(assets, Math.Rounding.Floor);
  }

  ///@inheritdoc IERC4626
  function previewMint(uint256 shares) public view override returns (uint256) {
    return _convertToAssets(shares, Math.Rounding.Ceil);
  }

  /// @inheritdoc IStakeToken
  function previewStake(uint256 assets) public view returns (uint256) {
    return _convertToShares(assets, Math.Rounding.Floor);
  }

  ///@inheritdoc IERC4626
  function previewWithdraw(uint256 assets) public view override returns (uint256) {
    return _convertToShares(assets, Math.Rounding.Ceil);
  }

  /// @inheritdoc IERC4626
  function previewRedeem(uint256 shares) public view override returns (uint256) {
    return _convertToAssets(shares, Math.Rounding.Floor);
  }

  function _convertToAssets(
    uint256 shares,
    Math.Rounding rounding
  ) internal view returns (uint256) {
    StakeTokenStorage storage $ = _getStakeTokenStorage();
    return shares.mulDiv(EXCHANGE_RATE_UNIT, $._currentExchangeRate, rounding);
  }

  function _convertToShares(
    uint256 assets,
    Math.Rounding rounding
  ) internal view returns (uint256) {
    StakeTokenStorage storage $ = _getStakeTokenStorage();
    return assets.mulDiv($._currentExchangeRate, EXCHANGE_RATE_UNIT, rounding);
  }

  ///@inheritdoc IERC4626
  function deposit(
    uint256 assets,
    address receiver
  ) external override whenNotPaused returns (uint256) {
    return _stake(msg.sender, receiver, assets, true);
  }

  ///@inheritdoc IERC4626
  function mint(
    uint256 shares,
    address receiver
  ) external override whenNotPaused returns (uint256) {
    uint256 assets = previewMint(shares);
    _stake(msg.sender, receiver, assets, true);
    return assets;
  }

  /// @inheritdoc IStakeToken
  function stake(address to, uint256 amount) external whenNotPaused {
    _stake(msg.sender, to, amount, true);
  }

  /// @inheritdoc IStakeToken
  function stakeWithPermit(
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external whenNotPaused {
    StakeTokenStorage storage $ = _getStakeTokenStorage();
    try
      IERC20Permit($._smConfig.stakedToken).permit(
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
    _stake(msg.sender, msg.sender, amount, true);
  }

  /// @inheritdoc IStakeToken
  function cooldown() external whenNotPaused {
    _cooldown(msg.sender);
  }

  /// @inheritdoc IStakeToken
  function cooldownOnBehalfOf(address from) external whenNotPaused onlyOwner {
    _cooldown(from);
  }

  /// @inheritdoc IStakeToken
  function redeem(address to, uint256 amount) external whenNotPaused {
    _redeem(msg.sender, to, amount.toUint104());
  }

  /// @inheritdoc IStakeToken
  function redeemOnBehalf(
    address from,
    address to,
    uint256 amount
  ) external whenNotPaused onlyOwner {
    _redeem(from, to, amount.toUint104());
  }

  /// @inheritdoc IERC4626
  function withdraw(
    uint256 assets,
    address receiver,
    address owner
  ) external override returns (uint256) {
    uint256 shares = previewWithdraw(assets);

    if (owner != msg.sender) {
      _spendAllowance(owner, msg.sender, shares);
    }

    _redeem(owner, receiver, shares.toUint104());

    return shares;
  }

  /// @inheritdoc IERC4626
  function redeem(
    uint256 shares,
    address receiver,
    address owner
  ) external override returns (uint256) {
    if (owner != msg.sender) {
      _spendAllowance(owner, msg.sender, shares);
    }

    return _redeem(owner, receiver, shares.toUint104());
  }

  /// @inheritdoc IStakeToken
  function getExchangeRate() public view returns (uint216) {
    StakeTokenStorage storage $ = _getStakeTokenStorage();
    return $._currentExchangeRate;
  }

  /// @inheritdoc IStakeToken
  function slash(
    address destination,
    uint256 amount
  ) external onlySlashingAdmin whenNotPaused returns (uint256) {
    require(amount > 0, 'ZERO_AMOUNT');
    uint256 maxSlashable = getMaxSlashableAssets();
    require(maxSlashable > 0, 'ZERO_FUNDS_AVAILABLE');
    if (amount > maxSlashable) {
      amount = maxSlashable;
    }

    uint256 currentShares = totalSupply();
    uint256 balance = previewRedeem(currentShares);
    _updateExchangeRate(_getExchangeRate(balance - amount, currentShares));
    StakeTokenStorage storage $ = _getStakeTokenStorage();

    IERC20($._smConfig.stakedToken).safeTransfer(destination, amount);

    emit Slashed(destination, amount);
    return amount;
  }

  /// @inheritdoc IStakeToken
  function getMaxSlashableAssets() public view returns (uint256) {
    uint256 currentAssets = totalAssets();
    StakeTokenStorage storage $ = _getStakeTokenStorage();
    uint256 cachedMin = $._minAssetsRemaining;
    return cachedMin > currentAssets ? 0 : currentAssets - cachedMin;
  }

  /// @inheritdoc IStakeToken
  function getMinAssetsRemaining() external view returns (uint256) {
    StakeTokenStorage storage $ = _getStakeTokenStorage();
    return $._minAssetsRemaining;
  }

  /// @inheritdoc IStakeToken
  function setMinAssetsRemaining(uint256 newMinAssetsRemaining) external onlyOwner {
    _setMinAssetsRemaining(newMinAssetsRemaining);
  }

  function _setMinAssetsRemaining(uint256 newMinAssetsRemaining) internal {
    StakeTokenStorage storage $ = _getStakeTokenStorage();
    $._minAssetsRemaining = newMinAssetsRemaining;
    emit MinAssetsRemainingChanged(newMinAssetsRemaining);
  }

  /// @inheritdoc IStakeToken
  function setCooldownSeconds(uint256 cooldownSeconds) external onlyOwner {
    _setCooldownSeconds(cooldownSeconds);
  }

  /// @inheritdoc IStakeToken
  function getCooldownSeconds() external view returns (uint256) {
    StakeTokenStorage storage $ = _getStakeTokenStorage();
    return $._smConfig.cooldownSeconds;
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

  /**
   * @dev sets the cooldown seconds
   * @param cooldownSeconds the new amount of cooldown seconds
   */
  function _setCooldownSeconds(uint256 cooldownSeconds) internal {
    StakeTokenStorage storage $ = _getStakeTokenStorage();

    $._smConfig.cooldownSeconds = cooldownSeconds.toUint40();

    emit CooldownSecondsChanged(cooldownSeconds);
  }

  /**
   * @dev Allows staking a specified amount of stakedToken
   * @param to The address to receiving the shares
   * @param amount The amount of assets to be staked
   */
  function _stake(
    address from,
    address to,
    uint256 amount,
    bool pullFunds
  ) internal returns (uint256 sharesToMint) {
    require(amount != 0, 'INVALID_ZERO_AMOUNT');

    sharesToMint = previewStake(amount);
    require(sharesToMint != 0, 'INVALID_ZERO_AMOUNT_AFTER_CONVERSION');

    _mint(to, sharesToMint.toUint104());

    if (pullFunds) {
      StakeTokenStorage storage $ = _getStakeTokenStorage();
      IERC20($._smConfig.stakedToken).safeTransferFrom(from, address(this), amount);
    }

    emit Deposit(from, to, amount, sharesToMint);
  }

  /**
   * @dev Redeems staked tokens, and stop earning rewards
   * @param from Address to redeem from
   * @param to Address to redeem to
   * @param amount Amount to redeem
   */
  function _redeem(address from, address to, uint104 amount) internal returns (uint256 assets) {
    require(amount != 0, 'INVALID_ZERO_AMOUNT');

    StakeTokenStorage storage $ = _getStakeTokenStorage();

    CooldownSnapshot memory cooldownSnapshot = $._stakersCooldowns[from];
    SmConfig memory cachedSmConfig = $._smConfig;

    require(block.timestamp >= cooldownSnapshot.timestamp, 'INSUFFICIENT_COOLDOWN');
    require(
      block.timestamp - cooldownSnapshot.timestamp <= cachedSmConfig.unstakeWindowSeconds,
      'UNSTAKE_WINDOW_FINISHED'
    );

    uint256 maxRedeemable = cooldownSnapshot.amount;
    require(maxRedeemable != 0, 'INVALID_ZERO_MAX_REDEEMABLE');

    uint256 amountToRedeem = (amount > maxRedeemable) ? maxRedeemable : amount;

    assets = previewRedeem(amountToRedeem);

    _burn(from, amountToRedeem.toUint104());

    IERC20(cachedSmConfig.stakedToken).safeTransfer(to, assets);

    emit Withdraw(msg.sender, to, from, assets, amountToRedeem);
  }

  /**
   * @dev Updates the exchangeRate and emits events accordingly
   * @param newExchangeRate the new exchange rate
   */
  function _updateExchangeRate(uint216 newExchangeRate) internal virtual {
    require(newExchangeRate != 0, 'ZERO_EXCHANGE_RATE');
    StakeTokenStorage storage $ = _getStakeTokenStorage();
    $._currentExchangeRate = newExchangeRate;
    emit ExchangeRateChanged(newExchangeRate);
  }

  /**
   * @dev calculates the exchange rate based on totalAssets and totalShares
   * @dev always rounds up to ensure 100% backing of shares by rounding in favor of the contract
   * @param newTotalAssets The total amount of assets staked
   * @param newTotalShares The total amount of shares
   * @return exchangeRate as 18 decimal precision uint216
   */
  function _getExchangeRate(
    uint256 newTotalAssets,
    uint256 newTotalShares
  ) internal pure returns (uint216) {
    return
      (((newTotalShares * EXCHANGE_RATE_UNIT) + newTotalAssets - 1) / newTotalAssets).toUint216();
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
      StakeTokenStorage storage $ = _getStakeTokenStorage();
      CooldownSnapshot memory previousSenderCooldown = $._stakersCooldowns[from];
      if (previousSenderCooldown.timestamp != 0) {
        // update to 0 means redeem
        // this is based on the assumption that erc20 forbids transfer to 0
        if (to == address(0)) {
          if (previousSenderCooldown.amount <= amount) {
            delete $._stakersCooldowns[from];
          } else {
            $._stakersCooldowns[from].amount = uint216(previousSenderCooldown.amount - amount);
          }
        } else {
          uint256 balanceAfter = balanceOfFrom - amount;
          if (balanceAfter == 0) {
            delete $._stakersCooldowns[from];
          } else if (balanceAfter < previousSenderCooldown.amount) {
            $._stakersCooldowns[from].amount = uint216(balanceAfter);
          }
        }
      }
    }

    super._update(from, to, amount);
  }
}
