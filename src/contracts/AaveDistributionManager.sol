// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/**
 * @title AaveDistributionManager
 * @notice Accounting contract to manage multiple staking distributions
 * @author Aave
 */
contract AaveDistributionManager {
  struct AssetData {
    uint128 emissionPerSecond;
    uint128 lastUpdateTimestamp;
    uint256 index;
    mapping(address => uint256) users;
  }
  mapping(address => AssetData) private DEPRECATED_assets;
  uint256 private DEPRECATED_distributionEnd;
}
