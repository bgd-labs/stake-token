// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {TestnetProcedures} from 'aave-v3-origin/../tests/utils/TestnetProcedures.sol';
import {IPool} from 'aave-v3-origin/core/contracts/interfaces/IPool.sol';
import {DataTypes} from 'aave-v3-origin/core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {IERC20Metadata} from 'aave-v3-origin/periphery/contracts/static-a-token/StaticATokenLM.sol';
import {IAccessControl} from 'aave-v3-origin/core/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol';

contract StakeTestBase is TestnetProcedures {
  address public admin = vm.addr(0xA11CE);
  address public proxyAdmin;
  IPool public pool;
  address public underlying;
  address public aToken;

  function _setupProtocol() internal {
    initTestEnvironment();
    proxyAdmin = report.proxyAdmin;
    pool = contracts.poolProxy;
    DataTypes.ReserveDataLegacy memory reserveDataWETH = contracts.poolProxy.getReserveData(
      tokenList.weth
    );
    underlying = address(weth);
    aToken = reserveDataWETH.aTokenAddress;

    vm.prank(poolAdmin);
    IAccessControl(address(contracts.aclManager)).grantRole('SLASHING_ADMIN', admin);
  }

  function _dealUnderlying(uint256 amount, address user) internal {
    deal(underlying, user, amount);
  }

  function _dealAToken(uint256 amount, address user) internal {
    deal(underlying, user, amount);
    vm.prank(user);
    IERC20Metadata(underlying).approve(address(pool), amount);
    vm.prank(user);
    pool.supply(underlying, amount, user, 0);
  }
}
