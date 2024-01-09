// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Initializable} from 'openzeppelin-contracts/contracts/proxy/utils/Initializable.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';
import {IERC20Metadata} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {IERC20Permit} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol';

import {ERC20Permit} from './ERC20Permit.sol';
import {AaveDistributionManager} from './AaveDistributionManager.sol';
import {RoleManager} from './RoleManager.sol';
import {IStakeToken} from './IStakeToken.sol';
import {IAaveDistributionManager} from './IAaveDistributionManager.sol';

import {PercentageMath} from './lib/PercentageMath.sol';
import {DistributionTypes} from './lib/DistributionTypes.sol';

contract StakeToken is ERC20Permit, AaveDistributionManager, RoleManager, IStakeToken {
  using SafeERC20 for IERC20;
  using PercentageMath for uint256;
  using SafeCast for uint256;
  using SafeCast for uint104;

  uint256 public constant SLASH_ADMIN_ROLE = 0;
  uint256 public constant COOLDOWN_ADMIN_ROLE = 1;
  uint256 public constant CLAIM_HELPER_ROLE = 2;
  uint216 public constant INITIAL_EXCHANGE_RATE = 1e18;
  uint256 public constant EXCHANGE_RATE_UNIT = 1e18;

  /// @notice lower bound to prevent spam & avoid exchangeRate issues
  // as returnFunds can be called permissionless an attacker could spam returnFunds(1) to produce exchangeRate snapshots making voting expensive
  uint256 public immutable LOWER_BOUND;

  IERC20 public immutable STAKED_TOKEN;
  IERC20 public immutable REWARD_TOKEN;

  /// @notice Seconds available to redeem once the cooldown period is fulfilled
  uint256 public immutable UNSTAKE_WINDOW;

  /// @notice Address to pull from the rewards, needs to have approved this contract
  address public immutable REWARDS_VAULT;

  mapping(address => uint256) public stakerRewardsToClaim;
  mapping(address => CooldownSnapshot) public stakersCooldowns;

  /// @notice Seconds between starting cooldown and being able to withdraw
  uint256 internal _cooldownSeconds;
  /// @notice The maximum amount of funds that can be slashed at any given time
  uint256 internal _maxSlashablePercentage;
  /// @notice Mirror of latest snapshot value for cheaper access
  uint216 internal _currentExchangeRate;
  /// @notice Flag determining if there's an ongoing slashing event that needs to be settled
  bool public inPostSlashingPeriod;

  modifier onlySlashingAdmin() {
    require(msg.sender == getAdmin(SLASH_ADMIN_ROLE), 'CALLER_NOT_SLASHING_ADMIN');
    _;
  }

  modifier onlyCooldownAdmin() {
    require(msg.sender == getAdmin(COOLDOWN_ADMIN_ROLE), 'CALLER_NOT_COOLDOWN_ADMIN');
    _;
  }

  modifier onlyClaimHelper() {
    require(msg.sender == getAdmin(CLAIM_HELPER_ROLE), 'CALLER_NOT_CLAIM_HELPER');
    _;
  }

  constructor(
    string memory name,
    IERC20 stakedToken,
    IERC20 rewardToken,
    uint256 unstakeWindow,
    address rewardsVault,
    address emissionManager
  ) ERC20Permit(name) AaveDistributionManager(emissionManager) {
    uint256 decimals = IERC20Metadata(address(stakedToken)).decimals();
    LOWER_BOUND = 10 ** decimals;
    STAKED_TOKEN = stakedToken;
    REWARD_TOKEN = rewardToken;
    UNSTAKE_WINDOW = unstakeWindow;
    REWARDS_VAULT = rewardsVault;
  }

  function initialize(
    string calldata name,
    string calldata symbol,
    address slashingAdmin,
    address cooldownPauseAdmin,
    address claimHelper,
    uint256 maxSlashablePercentage,
    uint256 cooldownSeconds
  ) external virtual initializer {
    _initializeMetadata(name, symbol);

    InitAdmin[] memory initAdmins = new InitAdmin[](3);
    initAdmins[0] = InitAdmin(SLASH_ADMIN_ROLE, slashingAdmin);
    initAdmins[1] = InitAdmin(COOLDOWN_ADMIN_ROLE, cooldownPauseAdmin);
    initAdmins[2] = InitAdmin(CLAIM_HELPER_ROLE, claimHelper);

    _initAdmins(initAdmins);

    _setMaxSlashablePercentage(maxSlashablePercentage);
    _setCooldownSeconds(cooldownSeconds);
    _updateExchangeRate(INITIAL_EXCHANGE_RATE);
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
  function cooldownOnBehalfOf(address from) external onlyClaimHelper {
    _cooldown(from);
  }

  /// @inheritdoc IStakeToken
  function redeem(address to, uint256 amount) external {
    _redeem(msg.sender, to, amount.toUint104());
  }

  /// @inheritdoc IStakeToken
  function redeemOnBehalf(address from, address to, uint256 amount) external onlyClaimHelper {
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
  ) external onlyClaimHelper returns (uint256) {
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
  ) external onlyClaimHelper {
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

  /// @inheritdoc IStakeToken
  function slash(address destination, uint256 amount) external onlySlashingAdmin returns (uint256) {
    require(!inPostSlashingPeriod, 'PREVIOUS_SLASHING_NOT_SETTLED');
    require(amount > 0, 'ZERO_AMOUNT');
    uint256 currentShares = totalSupply();
    uint256 balance = previewRedeem(currentShares);

    uint256 maxSlashable = balance.percentMul(_maxSlashablePercentage);

    if (amount > maxSlashable) {
      amount = maxSlashable;
    }
    require(balance - amount >= LOWER_BOUND, 'REMAINING_LT_MINIMUM');

    inPostSlashingPeriod = true;
    _updateExchangeRate(_getExchangeRate(balance - amount, currentShares));

    STAKED_TOKEN.safeTransfer(destination, amount);

    emit Slashed(destination, amount);
    return amount;
  }

  /// @inheritdoc IStakeToken
  function returnFunds(uint256 amount) external {
    require(amount >= LOWER_BOUND, 'AMOUNT_LT_MINIMUM');
    uint256 currentShares = totalSupply();
    require(currentShares >= LOWER_BOUND, 'SHARES_LT_MINIMUM');
    uint256 assets = previewRedeem(currentShares);
    _updateExchangeRate(_getExchangeRate(assets + amount, currentShares));

    STAKED_TOKEN.safeTransferFrom(msg.sender, address(this), amount);
    emit FundsReturned(amount);
  }

  /// @inheritdoc IStakeToken
  function settleSlashing() external onlySlashingAdmin {
    inPostSlashingPeriod = false;
    emit SlashingSettled();
  }

  /// @inheritdoc IStakeToken
  function setMaxSlashablePercentage(uint256 percentage) external onlySlashingAdmin {
    _setMaxSlashablePercentage(percentage);
  }

  /// @inheritdoc IStakeToken
  function getMaxSlashablePercentage() external view returns (uint256) {
    return _maxSlashablePercentage;
  }

  /// @inheritdoc IStakeToken
  function setCooldownSeconds(uint256 cooldownSeconds) external onlyCooldownAdmin {
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
   * @dev sets the max slashable percentage
   * @param percentage must be strictly lower 100% as otherwise the exchange rate calculation would result in 0 division
   */
  function _setMaxSlashablePercentage(uint256 percentage) internal {
    require(percentage < PercentageMath.PERCENTAGE_FACTOR, 'INVALID_SLASHING_PERCENTAGE');

    _maxSlashablePercentage = percentage;
    emit MaxSlashablePercentageChanged(percentage);
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
    require(!inPostSlashingPeriod, 'SLASHING_ONGOING');
    require(amount != 0, 'INVALID_ZERO_AMOUNT');

    uint256 balanceOfTo = balanceOf(to);

    uint256 accruedRewards = _updateUserAssetInternal(
      to,
      address(this),
      balanceOfTo,
      totalSupply()
    );

    if (accruedRewards != 0) {
      stakerRewardsToClaim[to] = stakerRewardsToClaim[to] + accruedRewards;
      emit RewardsAccrued(to, accruedRewards);
    }

    uint256 sharesToMint = previewStake(amount);

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
    if (!inPostSlashingPeriod) {
      require(
        (block.timestamp >= cooldownSnapshot.timestamp + _cooldownSeconds),
        'INSUFFICIENT_COOLDOWN'
      );
      require(
        (block.timestamp - (cooldownSnapshot.timestamp + _cooldownSeconds) <= UNSTAKE_WINDOW),
        'UNSTAKE_WINDOW_FINISHED'
      );
    }

    uint256 balanceOfFrom = balanceOf(from);
    uint256 maxRedeemable = inPostSlashingPeriod ? balanceOfFrom : cooldownSnapshot.amount;
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
    // stake & transfer
    if (to != address(0)) {
      uint256 balanceOfTo = balanceOf(to);
      _updateCurrentUnclaimedRewards(to, balanceOfTo, true);
    }
    // redeem & transfer
    if (from != address(0) && from != to) {
      uint256 balanceOfFrom = balanceOf(from);
      // Sender
      _updateCurrentUnclaimedRewards(from, balanceOfFrom, true);
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
