// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC4626} from 'openzeppelin-contracts/contracts/interfaces/IERC4626.sol';

interface IStakeToken is IERC4626 {
  struct StakeTokenStorage {
    mapping(address => CooldownSnapshot) _stakerCooldown;
    SmConfig _smConfig;
    /// @notice Current exchangeRate of the stk
    uint192 _currentExchangeRate;
  }

  struct CooldownSnapshot {
    /// @notice Represent the time of unlocking funds for redemption
    uint32 timestamp;
    /// @notice Amount of tokens available for redeem
    uint224 amount;
  }

  struct SmConfig {
    /// @notice Seconds available to redeem once the cooldown period is fulfilled
    uint32 unstakeWindowSeconds;
    /// @notice Seconds between starting cooldown and being able to withdraw
    uint32 cooldownSeconds;
  }

  event SlashingSettled();

  event Cooldown(address indexed user, uint256 amount);
  event Slashed(address indexed destination, uint256 amount);

  event MaxSlashablePercentageChanged(uint256 newPercentage);
  event SlashingExitWindowDurationChanged(uint256 windowSeconds);
  event CooldownSecondsChanged(uint256 cooldownSeconds);
  event UnstakeWindowChanged(uint256 unstakeWindow);
  event ExchangeRateChanged(uint256 exchangeRate);
  event SlashingAdminChanged(address newAdmin);

  event FundsReturned(uint256 amount);

  error ZeroExchangeRate();
  error ZeroBalanceOnCooldown();
  error ZeroAmountSlashing();
  error ZeroFundsAvailable();
  error CallerIsNotSlashingAdmin();
  error NotApprovedForCooldown(address owner, address spender);

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
   * @dev Activates the cooldown period to unstake
   * - It can't be called if the user is not staking
   */
  function cooldown() external;

  /**
   * @dev Activates the cooldown period to unstake
   * - It can't be called if the user is not staking
   */
  function cooldownOnBehalfOf(address from) external;

  /**
   * @dev Setter of cooldown seconds
   * Can only be called by the owner
   * @param cooldownSeconds the new amount of seconds you have to wait between starting the cooldown and being able to redeem
   */
  function setCooldownSeconds(uint256 cooldownSeconds) external;

  /**
   * @dev Setter of unstake window in seconds
   * Can only be called by the owner
   * @param newUnstakeWindow the new amount of seconds you have to withdraw after cooldown
   */
  function setUnstakeWindow(uint256 newUnstakeWindow) external;

  /**
   * @dev Returns the current exchange rate
   * @return exchangeRate as 18 decimal precision uint216
   */
  function getExchangeRate() external view returns (uint256);

  /**
   * @dev Getter of the cooldown seconds
   * @return cooldownSeconds the amount of seconds between starting the cooldown and being able to redeem
   */
  function getCooldownSeconds() external view returns (uint256);

  /**
   * @dev Getter for the unstake window
   * @return unstakeWindow in seconds
   */
  function getUnstakeWindow() external view returns (uint256);

  /**
   * @dev Getter for the pending cooldown of a user
   * @return pending cooldown
   */
  function getStakerCooldown(address user) external view returns (CooldownSnapshot memory);

  /**
   * @dev Getter of the currently slashable assets
   * @return maxSlashableAssets the maximum amount of assets that could be slashed at this moment
   * - MUST consider minAssetsRemaining
   */
  function getMaxSlashableAssets() external view returns (uint256);

  function MIN_ASSETS_REMAINING() external view returns (uint256);
}
