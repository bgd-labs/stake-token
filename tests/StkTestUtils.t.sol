// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {DistributionTypes} from '../src/contracts/lib/DistributionTypes.sol';
import {StakeToken} from '../src/contracts/StakeToken.sol';
import {ERC20} from 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import {ProxyAdmin} from 'openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol';
// using 4.9 via aave-token-v3 for testing as it makes reasoning about proxyAdmin a bit easier
import {TransparentUpgradeableProxy} from 'aave-token-v3/../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';

contract MockERC20 is ERC20 {
  constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}
}

contract StkTestUtils is Test {
  ERC20 public underlyingToken;
  ERC20 public rewardToken;
  address public constant rewardsVault = address(0x43110);
  address public constant admin = address(0x8000);
  address public constant USER = address(0x42);
  StakeToken public stakeTokenImpl;
  ProxyAdmin public proxyAdmin;
  StakeToken public stakeToken;

  function _initializeStkToken(uint256 maxSlashing) internal {
    underlyingToken = new MockERC20('TestToken', 'TEST');
    rewardToken = new MockERC20('TestReward', 'REWARD');
    stakeTokenImpl = new StakeToken(
      'stkTest',
      underlyingToken,
      rewardToken,
      2 days,
      rewardsVault,
      admin
    );
    proxyAdmin = new ProxyAdmin(admin);
    stakeToken = StakeToken(
      address(
        new TransparentUpgradeableProxy(
          address(stakeTokenImpl),
          address(proxyAdmin),
          abi.encodeWithSelector(
            StakeToken.initialize.selector,
            'Stake Test',
            'stkTest',
            admin,
            admin,
            admin,
            maxSlashing,
            15 days
          )
        )
      )
    );
    vm.prank(admin);
    stakeToken.setDistributionEnd(block.timestamp + 360 days);
    // there's some assumptions about timestamp being non zero
    vm.warp(block.timestamp + 1);
  }

  function _setEmission(uint256 emissionPerSecond) internal {
    vm.startPrank(admin);
    DistributionTypes.AssetConfigInput[] memory configs = new DistributionTypes.AssetConfigInput[](
      1
    );
    configs[0] = DistributionTypes.AssetConfigInput(
      uint128(uint256(emissionPerSecond)),
      0 ether, // doesn't matter, probably should be refactored as well
      address(stakeToken) // doesn't make much sense either as it's always the address of the token itself
    );
    stakeToken.configureAssets(configs);
    vm.stopPrank();

    vm.startPrank(rewardsVault);
    rewardToken.approve(address(stakeToken), type(uint256).max);
    deal(address(rewardToken), rewardsVault, emissionPerSecond * 360 days * 3);
    vm.stopPrank();
  }

  function _stake(uint256 amount, address user) internal {
    _stake(amount, user, user);
  }

  function _stake(uint256 amount, address user, address onBehalfOf) internal {
    deal(address(underlyingToken), user, amount);
    vm.startPrank(user);
    underlyingToken.approve(address(stakeToken), amount);
    stakeToken.stake(onBehalfOf, amount);
    vm.stopPrank();
  }

  function _redeem(uint256 amount, address user, address destination) internal {
    vm.startPrank(user);
    stakeToken.redeem(destination, amount);
    vm.stopPrank();
  }

  function _slash(address destination, uint256 amount) internal {
    vm.startPrank(admin);
    stakeToken.slash(destination, amount);
    vm.stopPrank();
  }

  function _settleSlashing() internal {
    vm.startPrank(admin);
    stakeToken.settleSlashing();
    vm.stopPrank();
  }
}
