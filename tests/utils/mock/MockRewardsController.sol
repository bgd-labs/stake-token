// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC4626} from '@openzeppelin/contracts/interfaces/IERC4626.sol';

contract MockRewardsController {
  address public lastUser;
  uint256 public lastUserBalance;

  uint256 public lastTotalSupply;
  uint256 public lastTotalAssets;

  function handleAction(address user, uint256 totalSupply, uint256 userBalance) external {
    lastUser = user;
    lastUserBalance = userBalance;

    lastTotalSupply = totalSupply;
    lastTotalAssets = IERC4626(msg.sender).totalAssets();
  }
}
