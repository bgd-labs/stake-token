// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {TestnetProcedures} from 'aave-v3-origin/../tests/utils/TestnetProcedures.sol';
import {IPool} from 'aave-v3-origin/core/contracts/interfaces/IPool.sol';
import {DataTypes} from 'aave-v3-origin/core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {IERC20Metadata} from 'aave-v3-origin/periphery/contracts/static-a-token/StaticATokenLM.sol';
import {IAccessControl} from 'aave-v3-origin/core/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol';
import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {IStakeToken} from '../../src/contracts/interfaces/IStakeToken.sol';
import {StakeToken} from '../../src/contracts/StakeToken.sol';
import {IRewardsController} from '../../src/contracts/interfaces/IRewardsController.sol';
import {ActionsLibrary} from './ActionsLibrary.sol';

/**
 * Token agnostic stake base helper setting up a aave protocol & stake token with an erc20 underlying
 */
contract StakeTestBase is TestnetProcedures {
  using ActionsLibrary for IStakeToken;

  address public admin = vm.addr(0xA11CE);
  address public user = vm.addr(0xB0B);
  address public proxyAdmin;
  address public slashingAdmin = address(0x9000);
  IPool public pool;
  IERC20Metadata public underlying;
  address public aToken;
  IStakeToken public stakeToken;

  function setUp() public virtual {
    _setupProtocol();
    _setupStakeToken(address(underlying));
  }

  function _setupStakeToken(address stakeTokenUnderlying) internal {
    StakeToken stakeTokenImpl = new StakeToken(
      IRewardsController(address(contracts.rewardsControllerProxy)),
      contracts.poolAddressesProvider
    );
    stakeToken = IStakeToken(
      address(
        new TransparentUpgradeableProxy(
          address(stakeTokenImpl),
          address(proxyAdmin),
          abi.encodeWithSelector(
            StakeToken.initialize.selector,
            address(stakeTokenUnderlying),
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
  }

  function _setupProtocol() internal {
    initTestEnvironment();
    proxyAdmin = report.proxyAdmin;
    pool = contracts.poolProxy;
    DataTypes.ReserveDataLegacy memory reserveDataWETH = contracts.poolProxy.getReserveData(
      tokenList.weth
    );
    underlying = IERC20Metadata(address(weth));
    aToken = reserveDataWETH.aTokenAddress;

    vm.prank(poolAdmin);
    IAccessControl(address(contracts.aclManager)).grantRole('SLASHING_ADMIN', slashingAdmin);
  }

  function _dealUnderlying(uint256 amount, address actor) internal {
    deal(address(underlying), actor, amount);
  }

  function _stake(uint256 amount, address actor) internal {
    _stake(amount, actor, actor);
  }

  function _stake(uint256 amount, address actor, address receiver) internal {
    _dealUnderlying(amount, actor);
    stakeToken.helper_deposit(vm, amount, actor, receiver);
  }

  function _redeem(uint256 amount, address actor, address destination) internal {
    vm.startPrank(actor);
    stakeToken.redeem(destination, amount);
    vm.stopPrank();
  }

  function _slash(address destination, uint256 amount) internal {
    stakeToken.helper_slash(vm, slashingAdmin, destination, amount);
  }
}
