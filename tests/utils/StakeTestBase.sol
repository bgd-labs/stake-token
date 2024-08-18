// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IERC20Metadata} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';

import {IStakeToken} from 'src/contracts/interfaces/IStakeToken.sol';

import {IRewardsController} from 'src/contracts/interfaces/IRewardsController.sol';
import {IPoolAddressesProvider} from 'src/contracts/interfaces/IPoolAddressesProvider.sol';

import {MockERC20} from './mock/MockERC20.sol';
import {MockACLManager} from './mock/MockACLManager.sol';
import {MockAddressProvider} from './mock/MockAddressProvider.sol';
import {MockRewardsController} from './mock/MockRewardsController.sol';

import {StakeToken} from 'src/contracts/StakeToken.sol';

contract StakeTestBase is Test {
  address public admin = vm.addr(0x1000);
  address public guardian = vm.addr(0x2000);

  address public user = vm.addr(0x3000);
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

    console.log(slashingAdmin);

    mockAddressProvider = address(new MockAddressProvider(mockACLManager));
    mockRewardsContoller = address(new MockRewardsController());

    underlying = new MockERC20('MockToken', 'MTK');
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
    uint256 amountOfAssets = stakeToken.convertToAssets(amountOfShares);

    _dealUnderlying(amountOfAssets, actor);

    vm.startPrank(actor);

    IERC20Metadata(stakeToken.asset()).approve(address(stakeToken), amountOfAssets);
    uint256 assets = stakeToken.mint(amountOfShares, receiver);

    vm.stopPrank();

    return assets;
  }
}
