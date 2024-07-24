// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import 'forge-std/Test.sol';
// import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
// import {TestnetProcedures} from 'aave-v3-origin/../tests/utils/TestnetProcedures.sol';
// import {IPool} from 'aave-v3-origin/core/contracts/interfaces/IPool.sol';
// import {DataTypes} from 'aave-v3-origin/core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
// import {StaticATokenFactory} from 'aave-v3-origin/periphery/contracts/static-a-token/StaticATokenFactory.sol';
// import {StaticATokenLM, IStaticATokenLM, IERC20, IERC20Metadata, ERC20} from 'aave-v3-origin/periphery/contracts/static-a-token/StaticATokenLM.sol';
// import {StakeToken} from '../../src/contracts/StakeToken.sol';
// import {IRewardsController} from '../../src/contracts/interfaces/IRewardsController.sol';

// contract StataStakeTokenTest is TestnetProcedures {
//   address public admin = vm.addr(0xA11CE);

//   address public proxyAdmin;
//   StaticATokenFactory public factory;
//   StaticATokenLM public staticATokenLM;
//   address public underlying;
//   address public aToken;
//   StakeToken public stakeToken;
//   IPool public pool;

//   function setUp() public {
//     _setupProtocol();
//     _setupStaticAToken();
//     _setupStakeToken();
//   }

//   function test_stakeUnderliyng() external {}

//   function test_stakeAToken() external {}

//   function _setupProtocol() internal {
//     initTestEnvironment();
//     proxyAdmin = report.proxyAdmin;
//     pool = contracts.poolProxy;
//   }

//   function _setupStaticAToken() internal {
//     DataTypes.ReserveDataLegacy memory reserveDataWETH = contracts.poolProxy.getReserveData(
//       tokenList.weth
//     );
//     underlying = address(weth);
//     aToken = reserveDataWETH.aTokenAddress;

//     factory = StaticATokenFactory(report.staticATokenFactoryProxy);
//     factory.createStaticATokens(pool.getReservesList());

//     staticATokenLM = StaticATokenLM(factory.getStaticAToken(underlying));
//   }

//   function _setupStakeToken() internal {
//     StakeToken stakeTokenImpl = new StakeToken(
//       IRewardsController(address(contracts.rewardsControllerProxy)),
//       contracts.poolAddressesProvider
//     );
//     TransparentUpgradeableProxy stakeTokenProxy = new TransparentUpgradeableProxy(
//       address(stakeTokenImpl),
//       address(proxyAdmin),
//       abi.encodeWithSelector(
//         StakeToken.initialize.selector,
//         address(staticATokenLM),
//         'Stake Test',
//         'stkTest',
//         admin,
//         15 days,
//         2 days,
//         1 ether
//       )
//     );
//   }
// }
