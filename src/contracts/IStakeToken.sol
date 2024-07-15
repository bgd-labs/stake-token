// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IStakeToken {
  struct CooldownSetup {
    // make more sense to display time from which can be withdrawn, not activation time
    /// @notice The time after which funds can be redeemed
    uint32 timestamp;
    /// @notice The amount of tokens which can be redeemed
    uint216 amount;
  }

  struct SmConfig {
    /// @notice Seconds available to redeem once the cooldown period is fulfilled
    uint32 unstakeWindowSeconds;
    /// @notice Seconds between starting cooldown and being able to withdraw
    uint32 defaultCooldownSeconds;
    /// @notice The address of the underlying asset
    address stakedToken;
    /// @notice The minimum cooldown time available for redeeming assets
    uint32 minCooldownSeconds;
    /// @notice The maximum fee in BIPS that will be taken when the cooldown period is reduced by maxReductionTime
    uint16 maxFee;
    /// @notice The address of treasury
    address treasury;
  }

  event Cooldown(address indexed user, uint256 amount, uint32 timeToRedeem);
  event FeesSentToTreasury(uint256 amount);
  event TreasuryChanged(address treasury);
  event MaxFeeChanged(uint256 maxFee);
  event MinCooldownSecondsChanged(uint256 maxReductionSeconds);

  event Staked(address indexed from, address indexed to, uint256 assets, uint256 shares);
  event Redeem(address indexed from, address indexed to, uint256 assets, uint256 shares);
  event MaxSlashablePercentageChanged(uint256 newPercentage);
  event Slashed(address indexed destination, uint256 amount);
  event SlashingExitWindowDurationChanged(uint256 windowSeconds);
  event CooldownSecondsChanged(uint256 cooldownSeconds);
  event UnstakeWindowChanged(uint256 unstakeWindow);
  event ExchangeRateChanged(uint216 exchangeRate);
  event FundsReturned(uint256 amount);
  event SlashingSettled();
  event SlashingAdminChanged(address newAdmin);

  /**
   * @dev Allows staking a specified amount of STAKED_TOKEN
   * @param to The address to receiving the shares
   * @param amount The amount of assets to be staked
   */
  function stake(address to, uint256 amount) external;

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
   * @dev Activates the cooldown period and reduces it
   * @param reducedTime Time by which the cooldown will be reduced
   */
  function reducedCooldown(uint256 reducedTime) external;

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
   * @return defaultCooldownSeconds The amount of seconds between starting the cooldown and being able to redeem by default
   */
  function getDefaultCooldownSeconds() external view returns (uint256);

  /**
   * @dev Getter of the maximum reduction cooldown seconds
   * @return maxReductionSeconds The maximum time available for reduction cooldown period
   */
  function getMaxReductionSeconds() external view returns (uint256);

  /**
   * @dev Getter of the minimum cooldown seconds possible
   * @return minCooldownSeconds The minimum cooldown time available
   */
  function getMinCooldownSeconds() external view returns (uint256);

  /**
   * @dev Setter of cooldown seconds
   * Can only be called by the cooldown admin
   * @param cooldownSeconds the new amount of seconds you have to wait between starting the cooldown and being able to redeem
   */
  function setCooldownSeconds(uint256 cooldownSeconds) external;

  /**
   * @dev Setter of treasury address
   * @param treasury new treasury address to set for collecting fast-withdrawal fees
   */
  function setTreasury(address treasury) external;

  /**
   * @dev Setter of max fee
   * @param maxFee Amount of fees in BPS, which should be paid for max cooldown reduction
   */
  function setMaxFee(uint256 maxFee) external;

  /**
   * @dev Setter of min cooldown time in seconds
   * @param newMinCooldownSeconds number of seconds the cooldown can be reduced to with the payment of fees
   */
  function setMinCooldownSeconds(uint256 newMinCooldownSeconds) external;

  /**
   * @dev returns the exact amount of shares that would be received for the provided number of assets
   * @param assets the number of assets to stake
   * @return uint256 shares the number of shares that would be received
   */
  function previewStake(uint256 assets) external view returns (uint256);

  /**
   * @dev Activates the cooldown period to unstake
   * - It can't be called if the user is not staking
   */
  function cooldownOnBehalfOf(address from) external;

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
   * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
   *
   * - SHOULD include any compounding that occurs from yield.
   * - MUST be inclusive of any fees that are charged against assets in the Vault.
   * - MUST NOT revert.
   */
  function totalAssets() external returns (uint256);
}
