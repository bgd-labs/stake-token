// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockPoolAddressesProvider {
  address private immutable _ACL_ADMIN;

  address private _aclManager;

  constructor(address aclAdmin) {
    _ACL_ADMIN = aclAdmin;
  }

  function getACLAdmin() external view returns (address) {
    return _ACL_ADMIN;
  }

  function getACLManager() external view returns (address) {
    return _aclManager;
  }

  function setACLManager(address manager) external {
    _aclManager = manager;
  }
}
