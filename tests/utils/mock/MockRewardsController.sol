// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

contract MockRewardsController {
  address lastUser;
  uint256 lastTotalSupply;
  uint256 lastUserBalance;

  function handleAction(address user, uint256 totalSupply, uint256 userBalance) external {
    lastUser = user;
    lastTotalSupply = totalSupply;
    lastUserBalance = userBalance;
  }
}
