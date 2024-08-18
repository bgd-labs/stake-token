// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {IPoolAddressesProvider} from 'aave-v3-origin/core/contracts/interfaces/IPoolAddressesProvider.sol';
import {IStaticATokenLM} from 'aave-v3-origin/periphery/contracts/static-a-token/interfaces/IStaticATokenLM.sol';
import {IERC4626} from 'aave-v3-origin/periphery/contracts/static-a-token/interfaces/IERC4626.sol';
import {IRewardsController} from '../interfaces/IRewardsController.sol';
import {StakeToken} from '../StakeToken.sol';

/**
 * A customized version of StakeToken to acoomondate for 4626 stata methods
 * DISLCAIMER: this code is not yet meant serious, mostly did because wanted to check if i can now setup protocol to test
 */
contract StataStakeToken is StakeToken {
  using SafeERC20 for IERC20;

  enum Token {
    UNDERLYING,
    A_TOKEN,
    STATA_TOKEN
  }

  constructor(
    IRewardsController rewardsController,
    IPoolAddressesProvider provider
  ) StakeToken(rewardsController, provider) {}

  // infinite approve all underlyings
  function initialize(
    address stakedToken,
    string calldata name,
    string calldata symbol,
    address owner,
    uint256 cooldownSeconds,
    uint256 unstakeWindow
  ) external virtual override initializer {
    _initialize(stakedToken, name, symbol, owner, cooldownSeconds, unstakeWindow);
    address cachedAsset = asset();
    IERC20 underlying = IERC20(IERC4626(cachedAsset).asset());
    IERC20 underlyingAToken = IERC20(address(IStaticATokenLM(cachedAsset).aToken()));
    SafeERC20.forceApprove(underlying, cachedAsset, type(uint256).max);
    SafeERC20.forceApprove(underlyingAToken, cachedAsset, type(uint256).max);
  }

  function deposit(address to, uint256 amount, Token inputType) external returns (uint256) {
    if (inputType == Token.UNDERLYING) {
      address cachedAsset = asset();
      IERC20 underlying = IERC20(IERC4626(cachedAsset).asset());
      IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
      amount = IERC4626(cachedAsset).deposit(amount, address(this));
      return _stake(msg.sender, to, amount, false);
    }
    if (inputType == Token.A_TOKEN) {
      address cachedAsset = asset();
      IERC20 underlyingAToken = IERC20(address(IStaticATokenLM(cachedAsset).aToken()));
      IERC20(underlyingAToken).safeTransferFrom(msg.sender, address(this), amount);
      amount = IStaticATokenLM(cachedAsset).deposit(amount, address(this), 0, false);
      return _stake(msg.sender, to, amount, false);
    }
    return _stake(msg.sender, to, amount, true);
  }
}
