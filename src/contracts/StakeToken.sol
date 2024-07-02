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
import {AaveDistributionManager} from './AaveDistributionManager.sol';
import {IStakeToken} from './IStakeToken.sol';
import {IAaveDistributionManager} from './IAaveDistributionManager.sol';
import {IRewardsController} from './IRewardsController.sol';

import {PercentageMath} from './lib/PercentageMath.sol';
import {DistributionTypes} from './lib/DistributionTypes.sol';

contract StakeToken is ERC20Permit, AaveDistributionManager, IStakeToken, Rescuable {
  using SafeERC20 for IERC20;
  using PercentageMath for uint256;
  using SafeCast for uint256;
  using SafeCast for uint104;

  uint216 public constant INITIAL_EXCHANGE_RATE = 1e18;
  uint256 public constant EXCHANGE_RATE_UNIT = 1e18;
  uint256 public constant MAX_SLASHABLE_PERCENTAGE = 9999;

  /// @notice lower bound to prevent spam & avoid exchangeRate issues
  // as returnFunds can be called permissionless an attacker could spam returnFunds(1) to produce exchangeRate snapshots making voting expensive
  uint256 public immutable LOWER_BOUND;

  IERC20 public immutable STAKED_TOKEN;
  IERC20 public immutable REWARD_TOKEN;

  /// @notice Seconds available to redeem once the cooldown period is fulfilled
  uint256 public immutable UNSTAKE_WINDOW;

  /// @notice Address to pull from the rewards, needs to have approved this contract
  address public immutable REWARDS_VAULT;
  IRewardsController public immutable REWARDS_CONTROLLER;

  mapping(address => uint256) public stakerRewardsToClaim;
  mapping(address => CooldownSnapshot) public stakersCooldowns;

  /// @notice Seconds between starting cooldown and being able to withdraw
  uint256 internal _cooldownSeconds;
  /// @notice The maximum amount of funds that can be slashed at any given time
  uint256 private DEPRECATED_maxSlashablePercentage;
  /// @notice Mirror of latest snapshot value for cheaper access
  uint216 internal _currentExchangeRate;
  /// @notice Flag determining if there's an ongoing slashing event that needs to be settled
  bool private DEPRECATED_inPostSlashingPeriod;

  address internal slashingAdmin;

  modifier onlySlashingAdmin() {
    require(msg.sender == slashingAdmin, 'CALLER_NOT_SLASHING_ADMIN');
    _;
  }

  constructor(
    string memory name,
    IERC20 stakedToken,
    IERC20 rewardToken,
    uint256 unstakeWindow,
    address rewardsVault,
    address emissionManager,
    IRewardsController rewardsController
  ) ERC20Permit(name) AaveDistributionManager(emissionManager) {
    uint256 decimals = IERC20Metadata(address(stakedToken)).decimals();
    LOWER_BOUND = 10 ** decimals;
    STAKED_TOKEN = stakedToken;
    REWARD_TOKEN = rewardToken;
    UNSTAKE_WINDOW = unstakeWindow;
    REWARDS_VAULT = rewardsVault;
    REWARDS_CONTROLLER = rewardsController;
  }

  function initialize(
    string calldata name,
    string calldata symbol,
    address slashingAdmin,
    address cooldownPauseAdmin,
    address claimHelper,
    uint256 cooldownSeconds
  ) external virtual initializer {
    _initializeMetadata(name, symbol);
    _transferOwnership(slashingAdmin);
    _setSlashingAdmin(slashingAdmin);
    _setCooldownSeconds(cooldownSeconds);
    _updateExchangeRate(INITIAL_EXCHANGE_RATE);
  }

  // TODO: reconsider as might not be needed with custom deployment
  // compatibility for RewardsController
  function scaledTotalSupply() external returns (uint256) {
    return totalSupply();
  }

  function whoCanRescue() public view override returns (address) {
    return owner();
  }

  /// @inheritdoc IAaveDistributionManager
  function configureAssets(
    DistributionTypes.AssetConfigInput[] memory assetsConfigInput
  ) external onlyEmissionManager {
    for (uint256 i = 0; i < assetsConfigInput.length; i++) {
      assetsConfigInput[i].totalStaked = totalSupply();
    }

    _configureAssets(assetsConfigInput);
  }

  function setDistributionEnd(uint256 newDistributionEnd) external onlyOwner {
    require(newDistributionEnd >= block.timestamp, 'END_MUST_BE_GE_NOW');
    AssetData storage assetConfig = assets[address(this)];
    _updateAssetStateInternal(address(this), assetConfig, totalSupply());
    distributionEnd = newDistributionEnd;
    emit DistributionEndChanged(newDistributionEnd);
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
  function claimRewards(address to, uint256 amount) external {
    _claimRewards(msg.sender, to, amount);
  }

  /// @inheritdoc IStakeToken
  function claimRewardsOnBehalf(
    address from,
    address to,
    uint256 amount
  ) external onlyOwner returns (uint256) {
    return _claimRewards(from, to, amount);
  }

  /// @inheritdoc IStakeToken
  function claimRewardsAndRedeem(address to, uint256 claimAmount, uint256 redeemAmount) external {
    _claimRewards(msg.sender, to, claimAmount);
    _redeem(msg.sender, to, redeemAmount.toUint104());
  }

  /// @inheritdoc IStakeToken
  function claimRewardsAndRedeemOnBehalf(
    address from,
    address to,
    uint256 claimAmount,
    uint256 redeemAmount
  ) external onlyOwner {
    _claimRewards(from, to, claimAmount);
    _redeem(from, to, redeemAmount.toUint104());
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
  function totalAssets() external view returns (uint256) {
    return STAKED_TOKEN.balanceOf(address(this));
  }

  /// @inheritdoc IStakeToken
  function slash(address destination, uint256 amount) external onlySlashingAdmin returns (uint256) {
    require(amount > 0, 'ZERO_AMOUNT');
    uint256 currentShares = totalSupply();
    uint256 balance = previewRedeem(currentShares);

    uint256 maxSlashable = balance.percentMul(MAX_SLASHABLE_PERCENTAGE);

    if (amount > maxSlashable) {
      amount = maxSlashable;
    }
    require(balance - amount >= LOWER_BOUND, 'REMAINING_LT_MINIMUM');

    _updateExchangeRate(_getExchangeRate(balance - amount, currentShares));

    STAKED_TOKEN.safeTransfer(destination, amount);

    emit Slashed(destination, amount);
    return amount;
  }

  /// @inheritdoc IStakeToken
  function setCooldownSeconds(uint256 cooldownSeconds) external onlyOwner {
    _setCooldownSeconds(cooldownSeconds);
  }

  /// @inheritdoc IStakeToken
  function getCooldownSeconds() external view returns (uint256) {
    return _cooldownSeconds;
  }

  /// @inheritdoc IStakeToken
  function getTotalRewardsBalance(address staker) external view returns (uint256) {
    DistributionTypes.UserStakeInput[]
      memory userStakeInputs = new DistributionTypes.UserStakeInput[](1);
    userStakeInputs[0] = DistributionTypes.UserStakeInput({
      underlyingAsset: address(this),
      stakedByUser: balanceOf(staker),
      totalStaked: totalSupply()
    });
    return stakerRewardsToClaim[staker] + _getUnclaimedRewards(staker, userStakeInputs);
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
    _cooldownSeconds = cooldownSeconds;
    emit CooldownSecondsChanged(cooldownSeconds);
  }

  /**
   * @dev claims the rewards for a specified address to a specified address
   * @param from The address of the from from which to claim
   * @param to Address to receive the rewards
   * @param amount Amount to claim
   * @return amount claimed
   */
  function _claimRewards(address from, address to, uint256 amount) internal returns (uint256) {
    require(amount != 0, 'INVALID_ZERO_AMOUNT');
    uint256 newTotalRewards = _updateCurrentUnclaimedRewards(from, balanceOf(from), false);

    uint256 amountToClaim = (amount > newTotalRewards) ? newTotalRewards : amount;
    require(amountToClaim != 0, 'INVALID_ZERO_AMOUNT');

    stakerRewardsToClaim[from] = newTotalRewards - amountToClaim;
    REWARD_TOKEN.safeTransferFrom(REWARDS_VAULT, to, amountToClaim);
    emit RewardsClaimed(from, to, amountToClaim);
    return amountToClaim;
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
    require(
      (block.timestamp >= cooldownSnapshot.timestamp + _cooldownSeconds),
      'INSUFFICIENT_COOLDOWN'
    );
    require(
      (block.timestamp - (cooldownSnapshot.timestamp + _cooldownSeconds) <= UNSTAKE_WINDOW),
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

  /**
   * @dev Updates the user state related with his accrued rewards
   * @param user Address of the user
   * @param userBalance The current balance of the user
   * @param updateStorage Boolean flag used to update or not the stakerRewardsToClaim of the user
   * @return The unclaimed rewards that were added to the total accrued
   */
  function _updateCurrentUnclaimedRewards(
    address user,
    uint256 userBalance,
    bool updateStorage
  ) internal returns (uint256) {
    uint256 accruedRewards = _updateUserAssetInternal(
      user,
      address(this),
      userBalance,
      totalSupply()
    );
    uint256 unclaimedRewards = stakerRewardsToClaim[user] + accruedRewards;

    if (accruedRewards != 0) {
      if (updateStorage) {
        stakerRewardsToClaim[user] = unclaimedRewards;
      }
      emit RewardsAccrued(user, accruedRewards);
    }

    return unclaimedRewards;
  }

  function _update(address from, address to, uint256 amount) internal override {
    uint256 cachedTotalSupply = totalSupply();
    // stake & transfer
    if (to != address(0)) {
      uint256 balanceOfTo = balanceOf(to);
      _updateCurrentUnclaimedRewards(to, balanceOfTo, true);
      REWARDS_CONTROLLER.handleAction(to, cachedTotalSupply, balanceOfTo);
    }
    // redeem & transfer
    if (from != address(0) && from != to) {
      uint256 balanceOfFrom = balanceOf(from);
      // Sender
      _updateCurrentUnclaimedRewards(from, balanceOfFrom, true);
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
