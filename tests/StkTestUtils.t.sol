// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {EmissionManager} from 'aave-v3-periphery/contracts/rewards/EmissionManager.sol';
import {RewardsController} from 'aave-v3-periphery/contracts/rewards/RewardsController.sol';
import {ProxyAdmin} from 'openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol';
import {ERC20} from 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
// using 4.9 via aave-token-v3 for testing as it makes reasoning about proxyAdmin a bit easier
import {TransparentUpgradeableProxy} from 'aave-token-v3/../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {IPoolAddressesProvider} from 'aave-v3-origin/core/contracts/interfaces/IPoolAddressesProvider.sol';
import {ACLManager} from 'aave-v3-origin/core/contracts/protocol/configuration/ACLManager.sol';
import {MockPoolAddressesProvider} from './utils/MockPoolAddressesProvider.sol';
import {MockERC20} from './utils/MockERC20.sol';
import {StakeToken} from '../src/contracts/StakeToken.sol';
import {IRewardsController} from '../src/contracts/interfaces/IRewardsController.sol';

contract StkTestUtils is Test {
  ERC20 public underlyingToken;
  ERC20 public rewardToken;
  address public constant rewardsVault = address(0x43110);
  address public constant admin = address(0x8000);
  address public constant slashingAdmin = address(0x9000);
  address public constant USER = address(0x42);
  StakeToken public stakeTokenImpl;
  ProxyAdmin public proxyAdmin;
  StakeToken public stakeToken;

  function setUp() public virtual {
    underlyingToken = new MockERC20('TestToken', 'TEST');
    rewardToken = new MockERC20('TestReward', 'REWARD');
    EmissionManager manager = new EmissionManager(admin);
    RewardsController controller = new RewardsController(address(manager));
    MockPoolAddressesProvider mockProvider = new MockPoolAddressesProvider(address(admin));
    ACLManager aclManager = new ACLManager(IPoolAddressesProvider(address(mockProvider)));
    mockProvider.setACLManager(address(aclManager));
    stakeTokenImpl = new StakeToken(
      IRewardsController(address(controller)),
      IPoolAddressesProvider(address(mockProvider))
    );
    proxyAdmin = new ProxyAdmin(admin);
    stakeToken = StakeToken(
      address(
        new TransparentUpgradeableProxy(
          address(stakeTokenImpl),
          address(proxyAdmin),
          abi.encodeWithSelector(
            StakeToken.initialize.selector,
            underlyingToken,
            'Stake Test',
            'stkTest',
            admin,
            15 days,
            2 days,
            1 ether
          )
        )
      )
    );

    vm.prank(admin);
    aclManager.grantRole('SLASHING_ADMIN', slashingAdmin);
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
    vm.startPrank(slashingAdmin);
    stakeToken.slash(destination, amount);
    vm.stopPrank();
  }
}
