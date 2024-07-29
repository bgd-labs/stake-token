// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {TestnetProcedures} from 'aave-v3-origin/../tests/utils/TestnetProcedures.sol';
import {IPool} from 'aave-v3-origin/core/contracts/interfaces/IPool.sol';
import {DataTypes} from 'aave-v3-origin/core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {StaticATokenFactory} from 'aave-v3-origin/periphery/contracts/static-a-token/StaticATokenFactory.sol';
import {StaticATokenLM, IStaticATokenLM, IERC20, IERC20Metadata, ERC20} from 'aave-v3-origin/periphery/contracts/static-a-token/StaticATokenLM.sol';
import {StataStakeToken} from '../../src/contracts/variants/StataStakeToken.sol';
import {IRewardsController} from '../../src/contracts/interfaces/IRewardsController.sol';

contract StataStakeTokenTest is TestnetProcedures {
  address public admin = vm.addr(0xA11CE);

  address public proxyAdmin;
  StaticATokenFactory public factory;
  StaticATokenLM public staticATokenLM;
  address public underlying;
  address public aToken;
  StataStakeToken public stakeToken;
  IPool public pool;

  function setUp() public {
    _setupProtocol();
    _setupStaticAToken();
    _setupStakeToken();
  }

  function _setupProtocol() internal {
    initTestEnvironment();
    proxyAdmin = report.proxyAdmin;
    pool = contracts.poolProxy;
  }

  function _setupStaticAToken() internal {
    DataTypes.ReserveDataLegacy memory reserveDataWETH = contracts.poolProxy.getReserveData(
      tokenList.weth
    );
    underlying = address(weth);
    aToken = reserveDataWETH.aTokenAddress;

    factory = StaticATokenFactory(report.staticATokenFactoryProxy);
    factory.createStaticATokens(pool.getReservesList());

    staticATokenLM = StaticATokenLM(factory.getStaticAToken(underlying));
  }

  function _setupStakeToken() internal {
    StataStakeToken stakeTokenImpl = new StataStakeToken(
      IRewardsController(address(contracts.rewardsControllerProxy)),
      contracts.poolAddressesProvider
    );
    stakeToken = StataStakeToken(
      address(
        new TransparentUpgradeableProxy(
          address(stakeTokenImpl),
          address(proxyAdmin),
          abi.encodeWithSelector(
            StataStakeToken.initialize.selector,
            address(staticATokenLM),
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

  function test_stakeUnderlying(uint64 amount) external {
    vm.assume(amount != 0);
    _dealUnderlying(amount, address(this));

    IERC20Metadata(underlying).approve(address(stakeToken), amount);
    stakeToken.stake(address(this), amount, StataStakeToken.Token.UNDERLYING);
  }

  function test_stakeAToken(uint64 amount) external {
      vm.assume(amount != 0);
    _dealAToken(amount, address(this));

    IERC20Metadata(aToken).approve(address(stakeToken), amount);
    stakeToken.stake(address(this), amount, StataStakeToken.Token.A_TOKEN);
  }

  function test_stakeStataToken(uint64 amount) external {
      vm.assume(amount != 0);
    _dealAToken(amount, address(this));

    IERC20Metadata(address(staticATokenLM)).approve(address(stakeToken), amount);
    stakeToken.stake(address(this), amount, StataStakeToken.Token.STATA_TOKEN);
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

  function _dealStataToken(uint256 amount, address user) internal {
    amount = staticATokenLM.previewMint(amount);
    deal(underlying, user, amount);
    vm.prank(user);
    IERC20Metadata(underlying).approve(address(staticATokenLM), amount);
    vm.prank(user);
    staticATokenLM.deposit(amount, user);
  }
}
