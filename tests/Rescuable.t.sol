// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';

import {StakeTestBase} from './utils/StakeTestBase.sol';

contract ReceiveEther {
  event Received(uint256 amount);

  receive() external payable {
    emit Received(msg.value);
  }
}

contract CooldownTests is StakeTestBase {
  function test_checkWhoCanRescue() public view {
    assertEq(stakeToken.whoCanRescue(), admin);
  }

  function test_rescue() public {
    // will use the same token, but imagine if it's not underlying)
    _dealUnderlying(1 ether, someone);

    vm.startPrank(someone);

    IERC20(underlying).transfer(address(stakeToken), 1 ether);

    vm.stopPrank();
    vm.startPrank(admin);

    stakeToken.emergencyTokenTransfer(address(underlying), someone, 1 ether);

    assertEq(underlying.balanceOf(address(stakeToken)), 0);
    assertEq(underlying.balanceOf(someone), 1 ether);
  }

  function test_rescueEther() public {
    deal(address(stakeToken), 1 ether);

    address sendToMe = address(new ReceiveEther());

    vm.stopPrank();
    vm.startPrank(admin);

    stakeToken.emergencyEtherTransfer(sendToMe, 1 ether);

    assertEq(sendToMe.balance, 1 ether);
  }

  function test_rescueFromNotAdmin(address anyone) public {
    vm.assume(anyone != admin);
    _dealUnderlying(1 ether, someone);

    vm.startPrank(someone);

    IERC20(underlying).transfer(address(stakeToken), 1 ether);

    vm.stopPrank();
    vm.startPrank(anyone);

    vm.expectRevert('ONLY_RESCUE_GUARDIAN');
    stakeToken.emergencyTokenTransfer(address(underlying), someone, 1 ether);
  }
}
