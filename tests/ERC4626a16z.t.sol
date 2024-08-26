// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import 'erc4626-tests/ERC4626.test.sol';

import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';

import {StakeToken} from 'src/contracts/StakeToken.sol';
import {IRewardsController} from 'src/contracts/interfaces/IRewardsController.sol';

import {MockRewardsController} from './utils/mock/MockRewardsController.sol';
import {MockERC20Permit} from './utils/mock/MockERC20Permit.sol';

contract ERC4626StdTest is ERC4626Test {
  function setUp() public override {
    _underlying_ = address(new MockERC20Permit('Mock ERC20', 'MERC20'));

    address mockRewardsController = address(new MockRewardsController());
    StakeToken stakeTokenImpl = new StakeToken(IRewardsController(mockRewardsController));

    _vault_ = address(
      StakeToken(
        address(
          new TransparentUpgradeableProxy(
            address(stakeTokenImpl),
            address(0x2000),
            abi.encodeWithSelector(
              StakeToken.initialize.selector,
              address(_underlying_),
              'Mock ERC4626',
              'MERC4626',
              address(0x3000),
              15 days,
              2 days
            )
          )
        )
      )
    );

    _delta_ = 0;
    _vaultMayBeEmpty = false;
    _unlimitedAmount = false;
  }
}
