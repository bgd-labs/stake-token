// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {StakeToken} from '../src/contracts/StakeToken.sol';
import {ERC20} from 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import {ProxyAdmin} from 'openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {IERC20Errors} from 'openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol';
import {StkTestUtils} from './StkTestUtils.t.sol';

contract StakeTokenTest is StkTestUtils {
  function test_storageSlot() public {
    assertEq(
      0x570b5e9089e57b3d227cfcd747a97877e3c5f12150099d7b38848c6202ca0a00,
      keccak256(abi.encode(uint256(keccak256('aave.storage.StakeToken')) - 1)) &
        ~bytes32(uint256(0xff))
    );
  }

  function test_totalAssets() public {
    uint64 stakeAmount = 10 ether;
    uint64 slashAmount = 1 ether;
    assertEq(stakeToken.totalAssets(), 0);
    _stake(stakeAmount, USER);
    assertEq(stakeToken.totalAssets(), stakeAmount, 'WRONG_AMOUNT_STAKED');
    _slash(USER, slashAmount);
    assertApproxEqAbs(stakeToken.totalAssets(), stakeAmount - slashAmount, 10);
  }
}
