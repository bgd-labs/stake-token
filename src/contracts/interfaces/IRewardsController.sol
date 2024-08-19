// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IRewardsController {
  function handleAction(address user, uint256 totalSupply, uint256 userBalance) external;
}
