// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {IStakeToken} from '../src/contracts/interfaces/IStakeToken.sol';
import {StataStakeTestBase} from './utils/StataStakeTestBase.sol';
import {InvariantHandler} from './utils/InvariantHandler.sol';

contract InvariantTest is StataStakeTestBase {
  InvariantHandler public handler;

  function setUp() public virtual override {
    super.setUp();
    handler = new InvariantHandler(stakeToken);

    targetContract(address(handler));
  }

  /**
   * totalAssets MUST be lower or equal the underlying balance
   */
  function invariant_totalAssets() external view {
    assertLe(stakeToken.totalAssets(), handler.ghost_sumOfStakedAssets());

    // check that the ghost accounting is correct
    assertEq(
      IERC20(stakeToken.asset()).balanceOf(address(stakeToken)),
      handler.ghost_sumOfStakedAssets()
    );
  }
}
