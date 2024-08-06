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
import {StakeTestBase} from './StakeTestBase.sol';

contract StataStakeTestBase is StakeTestBase {
  StaticATokenFactory public factory;
  StaticATokenLM public staticATokenLM;
  StataStakeToken public stakeToken;

  function setUp() public virtual {
    _setupProtocol();
    address token = _setupStaticAToken();
    _setupStakeToken(token);
  }

  function _setupStaticAToken() internal returns (address) {
    factory = StaticATokenFactory(report.staticATokenFactoryProxy);
    factory.createStaticATokens(pool.getReservesList());

    staticATokenLM = StaticATokenLM(factory.getStaticAToken(underlying));
    return address(staticATokenLM);
  }

  function _setupStakeToken(address stakeTokenUnderlying) internal {
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

  function _dealStataToken(uint256 amount, address user) internal {
    amount = staticATokenLM.previewMint(amount);
    deal(underlying, user, amount);
    vm.prank(user);
    IERC20Metadata(underlying).approve(address(staticATokenLM), amount);
    vm.prank(user);
    staticATokenLM.deposit(amount, user);
  }
}
