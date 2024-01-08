// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IAaveDistributionManager} from './IAaveDistributionManager.sol';

interface IStakeToken is IAaveDistributionManager {
  struct CooldownSnapshot {
    uint40 timestamp;
    uint216 amount;
  }

  event RewardsAccrued(address user, uint256 amount);
  event RewardsClaimed(address indexed from, address indexed to, uint256 amount);
  event Cooldown(address indexed user, uint256 amount);

  event Staked(address indexed from, address indexed to, uint256 assets, uint256 shares);
  event Redeem(address indexed from, address indexed to, uint256 assets, uint256 shares);
  event MaxSlashablePercentageChanged(uint256 newPercentage);
  event Slashed(address indexed destination, uint256 amount);
  event SlashingExitWindowDurationChanged(uint256 windowSeconds);
  event CooldownSecondsChanged(uint256 cooldownSeconds);
  event ExchangeRateChanged(uint216 exchangeRate);
  event FundsReturned(uint256 amount);
  event SlashingSettled();

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
   * @dev Claims an `amount` of `REWARD_TOKEN` to the address `to`
   * @param to Address to send the claimed rewards
   * @param amount Amount to stake
   */
  function claimRewards(address to, uint256 amount) external;

  /**
   * @dev Return the total rewards pending to claim by an staker
   * @param staker The staker address
   * @return The rewards
   */
  function getTotalRewardsBalance(address staker) external view returns (uint256);

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
   * @dev Settles an ongoing slashing event
   */
  function settleSlashing() external;

  /**
   * @dev Pulls STAKE_TOKEN and distributes them amongst current stakers by altering the exchange rate.
   * This method is permissionless and intended to be used after a slashing event to return potential excess funds.
   * @param amount amount of STAKE_TOKEN to pull.
   */
  function returnFunds(uint256 amount) external;

  /**
   * @dev Getter of the cooldown seconds
   * @return cooldownSeconds the amount of seconds between starting the cooldown and being able to redeem
   */
  function getCooldownSeconds() external view returns (uint256);

  /**
   * @dev Setter of cooldown seconds
   * Can only be called by the cooldown admin
   * @param cooldownSeconds the new amount of seconds you have to wait between starting the cooldown and being able to redeem
   */
  function setCooldownSeconds(uint256 cooldownSeconds) external;

  /**
   * @dev Getter of the max slashable percentage of the total staked amount.
   * @return percentage the maximum slashable percentage
   */
  function getMaxSlashablePercentage() external view returns (uint256);

  /**
   * @dev Setter of max slashable percentage of the total staked amount.
   * Can only be called by the slashing admin
   * @param percentage the new maximum slashable percentage
   */
  function setMaxSlashablePercentage(uint256 percentage) external;

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
   * @dev Claims an `amount` of `REWARD_TOKEN` to the address `to` on behalf of the user. Only the claim helper contract is allowed to call this function
   * @param from The address of the user from to claim
   * @param to Address to send the claimed rewards
   * @param amount Amount to claim
   */
  function claimRewardsOnBehalf(
    address from,
    address to,
    uint256 amount
  ) external returns (uint256);

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
   * @dev Claims an `amount` of `REWARD_TOKEN` and redeems to the provided address
   * @param to Address to claim and redeem to
   * @param claimAmount Amount to claim
   * @param redeemAmount Amount to redeem
   */
  function claimRewardsAndRedeem(address to, uint256 claimAmount, uint256 redeemAmount) external;

  /**
   * @dev Claims an `amount` of `REWARD_TOKEN` and redeems the `redeemAmount` to an address. Only the claim helper contract is allowed to call this function
   * @param from The address of the from
   * @param to Address to claim and redeem to
   * @param claimAmount Amount to claim
   * @param redeemAmount Amount to redeem
   */
  function claimRewardsAndRedeemOnBehalf(
    address from,
    address to,
    uint256 claimAmount,
    uint256 redeemAmount
  ) external;
}
