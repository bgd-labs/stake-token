// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC4626} from 'openzeppelin-contracts/contracts/interfaces/IERC4626.sol';

interface IStakeToken is IERC4626 {
  struct CooldownSnapshot {
    /// @notice Time to unlock funds for withdrawal
    uint32 timestamp;
    /// @notice Amount of tokens available for withdrawal
    uint224 amount;
  }

  struct SmConfig {
    /// @notice Cooldown duration
    uint32 cooldown;
    /// @notice Time period during which funds can be withdrawn
    uint32 unstakeWindow;
  }

  struct SignatureParams {
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  event Cooldown(address indexed user, uint256 amount, uint256 timestamp);
  event Slashed(address indexed destination, uint256 amount);

  event CooldownChanged(uint256 cooldown);
  event UnstakeWindowChanged(uint256 unstakeWindow);
  event ExchangeRateChanged(uint256 exchangeRate);
  event SlashingAdminChanged(address newAdmin);

  /**
   * @dev Attempted to set zero `exchangeRate`.
   */
  error ZeroExchangeRate();

  /**
   * @dev Attempted to call cooldown without locked liquidity.
   */
  error ZeroBalanceInStaking();

  /**
   * @dev Attempted to slash for zero amount of assets.
   */
  error ZeroAmountSlashing();

  /**
   * @dev Attempted to slash with insufficient funds in staking.
   */
  error ZeroFundsAvailable();

  /**
   * @dev Attempt to make permit, which wasn't succeded.
   */
  error PermitNotSucceded();

  /**
   * @dev Attempt to call slash not from `slashingAdmin` address.
   */
  error CallerIsNotSlashingAdmin();

  /**
   * @dev Attempt to call cooldown without allowance for `stakeToken`.
   */
  error NotApprovedForCooldown(address owner, address spender);

  /**
   * @dev Executes a slashing of the asset of a certain amount, transferring the seized funds
   * to destination. Decreasing the amount of underlying will automatically adjust the exchange rate.
   * If the amount exceeds maxSlashableAmount then the second one is taken.
   * Emits a {Slashed} event.
   * @param destination Address where seized funds will be transferred
   * @param amount Amount to be slashed
   * @return amount Amount slashed
   */
  function slash(address destination, uint256 amount) external returns (uint256);

  /**
   * @dev Makes a deposit by first issuing approve for the required number of tokens (if `asset` supports the `permit` function).
   * Emits a {Deposit} event.
   * @param assets Amount of assets to be deposited
   * @param receiver Receiver of shares
   * @param deadline Signature deadline for issuing approve
   * @param sig Signature parameters
   */
  function depositWithPermit(
    uint256 assets,
    address receiver,
    uint256 deadline,
    SignatureParams memory sig
  ) external returns (uint256);

  /**
   * @dev Sets pause to the contract, can be called by `guardian` or `owner`.
   * Emits a {Paused} or an {Unpaused} event.
   * @param pause Flag indicating whether to pause or unpause
   */
  function setPause(bool pause) external;

  /**
   * @dev Activates the cooldown period to unstake for `msg.sender`.
   * It can't be called if the user is not staking.
   * Emits a {Cooldown} event.
   */
  function cooldown() external;

  /**
   * @dev Activates the cooldown period to unstake for a certain user.
   * It can't be called if the user is not staking.
   * `from` must approve shares for `msg.sender` so that he can activate the cooldown on his behalf.
   * Emits a {Cooldown} event.
   * @param from Address at which the `cooldown` will be activated
   */
  function cooldownOnBehalfOf(address from) external;

  /**
   * @dev Sets a new `cooldown` duration.
   * Can only be called by the `owner`.
   * Emits a {CooldownChanged} event.
   * @param cooldown Amount of seconds users have to wait between starting the `cooldown` and being able to withdraw funds
   */
  function setCooldown(uint256 cooldown) external;

  /**
   * @dev Sets a new `unstakeWindow` duration.
   * Can only be called by the `owner`.
   * Emits a {UnstakeWindowChanged} event.
   * @param newUnstakeWindow Amount of seconds users have to withdraw after `cooldown`
   */
  function setUnstakeWindow(uint256 newUnstakeWindow) external;

  /**
   * @dev Returns the current exchange rate with a 1e18 precision.
   */
  function getExchangeRate() external view returns (uint256);

  /**
   * @dev Returns current `cooldown` duration.
   */
  function getCooldown() external view returns (uint256);

  /**
   * @dev Returns current `unstakeWindow` duration.
   */
  function getUnstakeWindow() external view returns (uint256);

  /**
   * @dev Returns the last activated user `cooldown`. Contains the amount of tokens and timestamp.
   * May return zero values ​​if all funds have been withdrawn or transferred.
   */
  function getStakerCooldown(address user) external view returns (CooldownSnapshot memory);

  /**
   * @dev Returns the maximum slashable assets available for now.
   */
  function getMaxSlashableAssets() external view returns (uint256);

  /**
   * @dev Returns the minimum amount of assets, which can't be slashed.
   */
  function MIN_ASSETS_REMAINING() external view returns (uint256);
}
