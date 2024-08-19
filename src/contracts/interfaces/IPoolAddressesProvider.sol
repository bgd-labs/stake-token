// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IPoolAddressesProvider {
  /**
   * @notice Returns the address of the ACL manager.
   * @return The address of the ACLManager
   */
  function getACLManager() external view returns (address);
}
