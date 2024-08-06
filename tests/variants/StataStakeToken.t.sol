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
import {StataStakeTestBase} from '../utils/StataStakeTestBase.sol';

contract StataStakeTokenTest is StataStakeTestBase {
  function test_stakeUnderlying(uint64 amount) external {
    vm.assume(amount != 0);
    _dealUnderlying(amount, address(this));

    IERC20Metadata(underlying).approve(address(stakeToken), amount);
    stataStakeToken.deposit(address(this), amount, StataStakeToken.Token.UNDERLYING);
  }

  function test_stakeAToken(uint64 amount) external {
    vm.assume(amount != 0);
    _dealAToken(amount, address(this));

    IERC20Metadata(aToken).approve(address(stakeToken), amount);
    stataStakeToken.deposit(address(this), amount, StataStakeToken.Token.A_TOKEN);
  }

  function test_stakeStataToken(uint64 amount) external {
    vm.assume(amount != 0);
    _dealStataToken(amount, address(this));

    IERC20Metadata(address(staticATokenLM)).approve(address(stakeToken), amount);
    stataStakeToken.deposit(address(this), amount, StataStakeToken.Token.STATA_TOKEN);
  }
}
