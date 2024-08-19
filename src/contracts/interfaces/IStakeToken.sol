// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC4626} from 'openzeppelin-contracts/contracts/interfaces/IERC4626.sol';

interface IStakeToken is IERC4626 {
  struct CooldownSnapshot {
    /// @notice Represent the time of unlocking funds for redemption
    uint40 cooldownEnd;
    /// @notice Represents the sice (in seconds) of the withdrawal window when the snapshot was taken
    uint40 withdrawalWindowSeconds;
    /// @notice Amount of tokens available for redeem
    uint104 amount;
  }

  struct SmConfig {
    /// @notice Seconds available to redeem once the cooldown period is fulfilled
    uint40 defaultWithdrawalWindowSeconds;
    /// @notice Seconds between starting cooldown and being able to withdraw
    uint40 defaultCooldownSeconds;
    /// @notice The address of the underlying asset
    address stakedToken;
    // reserved for future use
  }

  /// @notice Thrown when an entity tries to slash that is not listed as admin.
  /// @param caller The caller.
  error OnlySlashingAdmin(address caller);
  /// @notice Thrown when a passed amount is zero.
  error ZeroAmount();
  /// @notice Throw when the passed assets amount corresponds to zero shares.
  /// @param assets The asset amount.
  error ZeroSharesAfterConversion(uint256 assets);
  /// @notice Thrown when there are no funds available to slash.
  error NoFundsAvailable();
  /// @notice Thrown when trying to redeem before the cooldown is read.
  /// @param cooldownEndTimestamp The timestamp at which the shares can be redeemed.
  error CooldownNotReady(uint40 cooldownEndTimestamp);
  /// @notice Thrown when trying to redeem after the cooldown has been expired.
  /// @param expirationTimestamp The timestamp at which the cooldown expired.
  error CooldownExpired(uint40 expirationTimestamp);
  /// @notice Throw when the cooldown amount is zero.
  error ZeroAmountRedeemable();

  event Cooldown(address indexed user, uint256 amount);
  event Slashed(address indexed destination, uint256 amount);
  event DefaultCooldownSecondsChanged(uint256 cooldownSeconds);
  event DefaultWithdrawalWindowChanged(uint256 withdrawalWindowSeconds);
  event ExchangeRateChanged(uint216 exchangeRate);
  event FundsReturned(uint256 amount);
  event SlashingSettled();
  event SlashingAdminChanged(address newAdmin);

  function MIN_ASSETS_REMAINING() external returns (uint256);

  /**
   * @dev Redeems shares, and stop earning rewards
   * @param to Address to redeem to
   * @param amount Amount of shares to redeem
   */
  function redeem(address to, uint256 amount) external;

  /**
   * @dev Activates the cooldown period to withdraw
   * - It can't be called if the user is not staking
   */
  function cooldown() external;

  /**
   * @dev Allows staking a certain amount of STAKED_TOKEN with gasless approvals (permit)
   * @param amount The amount to be staked
   * @param deadline The permit execution deadline
   * @param v The v component of the signed message
   * @param r The r component of the signed message
   * @param s The s component of the signed message
   */
  function stakeWithPermit(
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @dev Returns the current exchange rate
   * @return exchangeRate as 18 decimal precision uint216
   */
  function getExchangeRate() external view returns (uint216);

  /**
   * @dev Executes a slashing of the underlying of a certain amount, transferring the seized funds
   * to destination. Decreasing the amount of underlying will automatically adjust the exchange rate.
   * A call to `slash` will start a slashing event which has to be settled via `settleSlashing`.
   * As long as the slashing event is ongoing, stake and slash are deactivated.
   * - MUST NOT be called when a previous slashing is still ongoing
   * @param destination the address where seized funds will be transferred
   * @param amount the amount to be slashed
   * - if the amount bigger than maximum allowed, the maximum will be slashed instead.
   * @return amount the amount slashed
   */
  function slash(address destination, uint256 amount) external returns (uint256);

  /**
   * @dev Getter of the cooldown seconds
   * @return cooldownSeconds the amount of seconds between starting the cooldown and being able to redeem
   */
  function getDefaultCooldownSeconds() external view returns (uint256);

  /**
   * @dev Setter of cooldown seconds
   * Can only be called by the owner
   * @param cooldownSeconds the new amount of seconds you have to wait between starting the cooldown and being able to redeem
   */
  function setDefaultCooldownSeconds(uint256 cooldownSeconds) external;

  /**
   * @dev Activates the cooldown period to withdraw
   * - It can't be called if the user is not staking
   */
  function cooldownOnBehalfOf(address from) external;

  /**
   * @dev Getter for the withdraw window
   * @return withdrawWindow in seconds
   */
  function getWithdrawalWindow() external returns (uint256);

  /**
   * @dev returns the exact amount of assets that would be redeemed for the provided number of shares
   * @param shares the number of shares to redeem
   * @return uint256 assets the number of assets that would be redeemed
   */
  function previewRedeem(uint256 shares) external view returns (uint256);

  /**
   * @dev Redeems shares for a user. Only the claim helper contract is allowed to call this function
   * @param from Address to redeem from
   * @param to Address to redeem to
   * @param amount Amount of shares to redeem
   */
  function redeemOnBehalf(address from, address to, uint256 amount) external;

  /**
   * @dev Getter for the pending cooldown of a user
   * @return pending cooldown
   */
  function stakersCooldowns(address user) external view returns (CooldownSnapshot memory);

  /**
   * @dev Getter of the currently slashable assets
   * @return maxSlashableAssets the maximum amount of assets that could be slashed at this moment
   * - MUST consider minAssetsRemaining
   */
  function getMaxSlashableAssets() external view returns (uint256);

  /**
   * @dev Sets the paused state on the token
   * - MUST be permissioned
   */
  function setPaused(bool paused) external;
}
