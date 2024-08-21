// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {VmSafe} from 'forge-std/Vm.sol';

import {IStakeToken} from 'src/contracts/interfaces/IStakeToken.sol';

import {IRewardsController} from 'src/contracts/interfaces/IRewardsController.sol';
import {IPoolAddressesProvider} from 'src/contracts/interfaces/IPoolAddressesProvider.sol';

import {IERC20Metadata} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';

import {StakeToken} from 'src/contracts/StakeToken.sol';

import {MockERC20Permit} from './mock/MockERC20Permit.sol';
import {MockACLManager} from './mock/MockACLManager.sol';
import {MockAddressProvider} from './mock/MockAddressProvider.sol';
import {MockRewardsController} from './mock/MockRewardsController.sol';

contract StakeTestBase is Test {
  address public admin = vm.addr(0x1000);
  address public guardian = vm.addr(0x2000);

  uint256 userPrivateKey = 0x3000;
  address public user = vm.addr(userPrivateKey);

  address public someone = vm.addr(0x4000);

  address public proxyAdmin = vm.addr(0x5000);
  address public slashingAdmin = vm.addr(0x9000);

  IERC20Metadata public underlying;
  IStakeToken public stakeToken;

  address mockAddressProvider;
  address mockACLManager;
  address mockRewardsContoller;

  function setUp() public virtual {
    _setupProtocol();
    _setupStakeToken(address(underlying));
  }

  function _setupStakeToken(address stakeTokenUnderlying) internal {
    StakeToken stakeTokenImpl = new StakeToken(
      IRewardsController(mockRewardsContoller),
      IPoolAddressesProvider(mockAddressProvider)
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
            guardian,
            15 days,
            2 days
          )
        )
      )
    );
  }

  function _setupProtocol() internal {
    mockACLManager = address(new MockACLManager(slashingAdmin));

    mockAddressProvider = address(new MockAddressProvider(mockACLManager));
    mockRewardsContoller = address(new MockRewardsController());

    underlying = new MockERC20Permit('MockToken', 'MTK');
  }

  function _dealUnderlying(uint256 amount, address actor) internal {
    deal(address(underlying), actor, amount);
  }

  function _deposit(
    uint256 amountOfAsset,
    address actor,
    address receiver
  ) internal returns (uint256) {
    _dealUnderlying(amountOfAsset, actor);

    vm.startPrank(actor);

    IERC20Metadata(stakeToken.asset()).approve(address(stakeToken), amountOfAsset);
    uint256 shares = stakeToken.deposit(amountOfAsset, receiver);

    vm.stopPrank();

    return shares;
  }

  function _mint(
    uint256 amountOfShares,
    address actor,
    address receiver
  ) internal returns (uint256) {
    uint256 amountOfAssets = stakeToken.convertToAssets(amountOfShares) + 1;

    _dealUnderlying(amountOfAssets, actor);

    vm.startPrank(actor);

    IERC20Metadata(stakeToken.asset()).approve(address(stakeToken), amountOfAssets);
    uint256 assets = stakeToken.mint(amountOfShares, receiver);

    vm.stopPrank();

    return assets;
  }

  function sharesMultiplier() internal pure returns (uint256) {
    return 10 ** _decimalsOffset();
  }

  function _decimalsOffset() internal pure returns (uint256) {
    return 3;
  }

  function checkPowerLoss(uint256 expected, uint256 get) internal pure returns (uint256 power) {
    uint256 diff = getDiff(expected, get);

    while (true) {
      diff = diff / 10;

      if (diff == 0) {
        return power;
      }

      power++;
    }
  }

  function getDiff(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a - b : b - a;
  }
}
