// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC4626} from 'openzeppelin-contracts/contracts/interfaces/IERC4626.sol';

interface IStakeToken is IERC4626 {
  struct CooldownSnapshot {
    /// @notice Represent the time of unlocking funds for redemption
    uint40 timestamp;
    /// @notice Amount of tokens available for redeem
    uint216 amount;
  }

  struct SmConfig {
    /// @notice Seconds available to redeem once the cooldown period is fulfilled
    uint40 unstakeWindowSeconds;
    /// @notice Seconds between starting cooldown and being able to withdraw
    uint40 cooldownSeconds;
    /// @notice The address of the underlying asset
    address stakedToken;
    // reserved for future use
  }

  /// @notice v,r,s components of a signature
  struct SignatureParams {
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  struct PermitParams {
    /// @notice value to approve
    uint256 value;
    /// @notice signature expiration time
    uint256 deadline;
    /// @notice v,r,s components of a signature
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  event Cooldown(address indexed user, uint256 amount);

  event MaxSlashablePercentageChanged(uint256 newPercentage);
  event Slashed(address indexed destination, uint256 amount);
  event SlashingExitWindowDurationChanged(uint256 windowSeconds);
  event CooldownSecondsChanged(uint256 cooldownSeconds);
  event UnstakeWindowChanged(uint256 unstakeWindow);
  event ExchangeRateChanged(uint216 exchangeRate);
  event FundsReturned(uint256 amount);
  event SlashingSettled();
  event SlashingAdminChanged(address newAdmin);

  function MIN_ASSETS_REMAINING() external returns (uint256);

  function METADEPOSIT_TYPEHASH() external view returns (bytes32);

  function METAREDEEM_TYPEHASH() external view returns (bytes32);

  /**
   * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens, gasless
   * @param owner address of funds owner
   * @param receiver address of funds receiver
   * @param assets amount of underlying to deposit
   * @param deadline The permit execution deadline
   * @param permit The v,r,s components together with value and deadline of permit packed into PermitParams, can be empty
   * @param sigParams The v,r,s components of the signed message packed into SignatureParams
   */
  function metaDeposit(
    address owner,
    address receiver,
    uint256 assets,
    uint256 deadline,
    PermitParams calldata permit,
    SignatureParams calldata sigParams
  ) external returns (uint256);

  /**
   * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver, gasless
   * @param owner address of funds owner
   * @param receiver address of funds receiver
   * @param shares value of shares to burn
   * @param deadline The permit execution deadline
   * @param sigParams The v,r,s components of the signed message packed into SignatureParams
   */
  function metaRedeem(
    address owner,
    address receiver,
    uint256 shares,
    uint256 deadline,
    SignatureParams calldata sigParams
  ) external returns (uint256);

  /**
   * @dev Redeems shares, and stop earning rewards
   * @param to Address to redeem to
   * @param amount Amount of shares to redeem
   */
  function redeem(address to, uint256 amount) external;

  /**
   * @dev Activates the cooldown period to unstake
   * - It can't be called if the user is not staking
   */
  function cooldown() external;

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
  function getCooldownSeconds() external view returns (uint256);

  /**
   * @dev Setter of cooldown seconds
   * Can only be called by the owner
   * @param cooldownSeconds the new amount of seconds you have to wait between starting the cooldown and being able to redeem
   */
  function setCooldownSeconds(uint256 cooldownSeconds) external;

  /**
   * @dev Activates the cooldown period to unstake
   * - It can't be called if the user is not staking
   */
  function cooldownOnBehalfOf(address from) external;

  /**
   * @dev Getter for the unstake window
   * @return unstakeWindow in seconds
   */
  function getUnstakeWindow() external returns (uint256);

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
