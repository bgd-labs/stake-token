// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {OwnableUpgradeable} from 'openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol';
import {IStakeToken} from '../../src/contracts/interfaces/IStakeToken.sol';

library ActionsLibrary {
  using SafeERC20 for IERC20;

  function helper_deposit(
    IStakeToken self,
    Vm vm,
    uint256 amount,
    address actor,
    address receiver
  ) internal returns (uint256) {
    vm.startPrank(actor);
    IERC20(self.asset()).forceApprove(address(self), amount);
    uint256 shares = self.deposit(amount, receiver);
    vm.stopPrank();
    return shares;
  }

  function helper_cooldown_and_warp(IStakeToken self, Vm vm, address actor) internal {
    vm.prank(actor);
    self.cooldown();
    IStakeToken.CooldownSnapshot memory snapshot = self.stakersCooldowns(actor);
    vm.warp(snapshot.cooldownEnd + 1);
  }

  function helper_slash(
    IStakeToken self,
    Vm vm,
    address caller,
    address target,
    uint256 assets
  ) internal returns (uint256) {
    vm.prank(caller);
    return self.slash(target, assets);
  }
}
