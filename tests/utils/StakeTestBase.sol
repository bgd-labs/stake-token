// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {TestnetProcedures} from 'aave-v3-origin/../tests/utils/TestnetProcedures.sol';

import {IPool} from 'aave-v3-origin/core/contracts/interfaces/IPool.sol';

import {DataTypes} from 'aave-v3-origin/core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';

import {IAccessControl} from 'aave-v3-origin/core/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol';

import {IERC20Metadata} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {IStakeToken} from '../../src/contracts/interfaces/IStakeToken.sol';
import {StakeToken} from '../../src/contracts/StakeToken.sol';
import {IRewardsController} from '../../src/contracts/interfaces/IRewardsController.sol';

contract StakeTestBase is TestnetProcedures {
  address public admin = vm.addr(0x1000);
  address public guardian = vm.addr(0x2000);

  address public user = vm.addr(0x3000);
  address public someone = vm.addr(0x4000);

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
            guardian,
            15 days,
            2 days
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
