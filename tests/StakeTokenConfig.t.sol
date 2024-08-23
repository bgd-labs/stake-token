// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

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
    assertEq(stakeToken.decimals(), 18 + _decimalsOffset());
  }

  function test_transferOwnership(address anyone) public {
    vm.assume(anyone != address(0));

    vm.startPrank(admin);

    stakeToken.transferOwnership(anyone);

    assertEq(stakeToken.owner(), anyone);
  }

  function test_renounceOwnership() public {
    vm.startPrank(admin);

    stakeToken.renounceOwnership();

    assertEq(stakeToken.owner(), address(0));
  }
}
