// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

contract MockACLManager {
  address public slashingManager;

  constructor(address newSlashingManager) {
    slashingManager = newSlashingManager;
  }

  function hasRole(bytes32, address who) public view returns (bool) {
    if (who == slashingManager) {
      return true;
    }

    return false;
  }
}
