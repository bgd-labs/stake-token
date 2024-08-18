// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

contract MockAddressProvider {
  address public aclManager;

  constructor(address newAclManager) {
    aclManager = newAclManager;
  }

  function getACLManager() public view returns (address) {
    return aclManager;
  }
}
