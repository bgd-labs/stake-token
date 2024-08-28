// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

// modified
import 'erc4626-tests/ERC4626.test.sol';

import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';

import {StakeToken} from 'src/contracts/StakeToken.sol';
import {IRewardsController} from 'src/contracts/interfaces/IRewardsController.sol';

import {MockRewardsController} from '../utils/mock/MockRewardsController.sol';
import {MockERC20Permit} from '../utils/mock/MockERC20Permit.sol';

interface ISlashable {
  function slash(address to, uint256 amount) external;
}

contract ERC4626StdTest is ERC4626Test {
  function setUp() public override {
    _underlying_ = address(new MockERC20Permit('Mock ERC20', 'MERC20'));

    address mockRewardsController = address(new MockRewardsController());
    StakeToken stakeTokenImpl = new StakeToken(IRewardsController(mockRewardsController));

    _vault_ = address(
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
    );

    _delta_ = 0;
    _vaultMayBeEmpty = false;
    _unlimitedAmount = false;
  }

  function whoCanSlash() public pure returns (address) {
    return address(0x3000);
  }

  function MIN_ASSETS_REMAINING() public view returns (uint256) {
    return StakeToken(_vault_).MIN_ASSETS_REMAINING();
  }

  function setUpYield(Init memory init) public override {
    if (init.yield >= 0) {
      // there's no way for direct gain opportunity in stakeToken
    } else {
      uint256 totalShares;

      for (uint i = 0; i < N; i++) {
        totalShares += init.share[i];
      }

      vm.assume(init.yield > type(int).min);

      uint loss = uint(-1 * init.yield);

      vm.assume(loss + MIN_ASSETS_REMAINING() < totalShares); // avoid overflow in conversion

      vm.startPrank(whoCanSlash());
      try ISlashable(_vault_).slash(address(0xdead), loss) {} catch {
        vm.assume(false);
      }

      vm.stopPrank();
    }
  }
}
