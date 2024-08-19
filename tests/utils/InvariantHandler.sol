// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {OwnableUpgradeable} from 'openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {CommonBase} from 'forge-std/Base.sol';
import {StdCheats} from 'forge-std/StdCheats.sol';
import {StdUtils} from 'forge-std/StdUtils.sol';
import {IStakeToken} from '../../src/contracts/interfaces/IStakeToken.sol';
import {StataStakeTestBase} from './StataStakeTestBase.sol';
import {ActionsLibrary} from './ActionsLibrary.sol';

contract InvariantHandler is CommonBase, StdCheats, StdUtils {
  using SafeERC20 for IERC20;
  using ActionsLibrary for IStakeToken;

  IStakeToken private _stakeToken;
  address private _slashingAdmin;
  address[] public actors;

  // tracking variables
  uint256 internal currentActorIndex;
  address internal currentActor;
  uint256 public ghost_sumOfStakedAssets = 0;
  uint256 public ghost_lastExchangeRate;

  modifier useActor(uint256 actorIndexSeed) {
    currentActorIndex = bound(actorIndexSeed, 0, actors.length - 1);
    currentActor = actors[currentActorIndex];
    _;
  }

  constructor(IStakeToken stakeToken, address slashingAdmin) {
    _stakeToken = stakeToken;
    _slashingAdmin = slashingAdmin;
    actors.push(vm.addr(1000));
    actors.push(vm.addr(1001));
    actors.push(vm.addr(1002));
    ghost_lastExchangeRate = stakeToken.getExchangeRate();
  }

  function stake(uint256 assets, uint256 actorIndexSeed) external useActor(actorIndexSeed) {
    assets = bound(assets, 1, type(uint64).max);
    deal(_stakeToken.asset(), currentActor, assets);
    _stakeToken.helper_deposit(vm, assets, currentActor, currentActor);
    ghost_sumOfStakedAssets += assets;
  }

  function cooldown(uint256 actorIndexSeed) external useActor(actorIndexSeed) {
    if (IERC20(address(_stakeToken)).balanceOf(currentActor) == 0) return;
    _stakeToken.helper_cooldown_and_warp(vm, currentActor);
  }

  function redeem(uint256 assets, uint256 actorIndexSeed) external useActor(actorIndexSeed) {
    IStakeToken.CooldownSnapshot memory snapshot = _stakeToken.stakersCooldowns(currentActor);
    if (snapshot.amount == 0 || snapshot.cooldownEnd <= block.timestamp) return;
    _stakeToken.redeem(currentActor, assets);
    ghost_sumOfStakedAssets -= snapshot.amount > assets ? assets : snapshot.amount;
  }

  function transfer(uint256 shares, uint256 actorIndexSeed) external useActor(actorIndexSeed) {
    shares = bound(shares, 0, IERC20(address(_stakeToken)).balanceOf(currentActor));
    IERC20(address(_stakeToken)).transfer(_getNextActor(), shares);
  }

  function slash(uint256 assets) external {
    assets = bound(assets, 1, ghost_sumOfStakedAssets);
    ghost_lastExchangeRate = _stakeToken.getExchangeRate();
    ghost_sumOfStakedAssets -= _stakeToken.helper_slash(vm, _slashingAdmin, vm.addr(0xB0B), assets);
  }

  function _getNextActor() internal view returns (address) {
    if (currentActorIndex == actors.length - 1) return actors[0];
    return actors[currentActorIndex + 1];
  }
}
