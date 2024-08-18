// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {StakeTestBase} from './utils/StakeTestBase.sol';

contract StakeTokenConfigTests is StakeTestBase {
  function test_setCooldown(uint32 cooldown) public {
    vm.startPrank(admin);

    stakeToken.setCooldown(cooldown);

    assertEq(stakeToken.getCooldown(), cooldown);
  }

  function test_setUnstakeWindow(uint32 unstakeWindow) public {
    vm.startPrank(admin);

    stakeToken.setUnstakeWindow(unstakeWindow);

    assertEq(stakeToken.getUnstakeWindow(), unstakeWindow);
  }

  function test_decimals() public view {
    assertEq(stakeToken.decimals(), 18);
  }
}
