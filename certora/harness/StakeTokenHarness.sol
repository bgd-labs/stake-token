// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {StakeToken} from '../munged/src/contracts/StakeToken.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {ECDSA} from 'openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol';

contract StakeTokenHarness is StakeToken {
    // The following map records all users for which _updateCurrentUnclaimedRewards(..)
    // was called.
    mapping(address => bool) public _updated_unclaimed_rewards;
        
    constructor(
                string memory name,
                IERC20 stakedToken,
                IERC20 rewardToken,
                uint256 unstakeWindow,
                address rewardsVault,
                address emissionManager
    ) StakeToken (name, stakedToken, rewardToken, unstakeWindow, rewardsVault, emissionManager) {}

    function _updateCurrentUnclaimedRewards(address user, uint256 userBalance, bool updateStorage)
        internal virtual override returns (uint256) {
        _updated_unclaimed_rewards[user] = true;
        return super._updateCurrentUnclaimedRewards(user,userBalance,updateStorage);
    }

    function was_updated(address user) external returns (bool) {
        return _updated_unclaimed_rewards[user];
    }

    function __clean(address user) external {
        _updated_unclaimed_rewards[user] = false;
    }

    // Returns amount of the cooldown initiated by the user.
    function cooldownAmount(address user) public view returns (uint216) {
        return stakersCooldowns[user].amount;
    }

    // Returns timestamp of the cooldown initiated by the user.
    function cooldownTimestamp(address user) public view returns (uint40) {
        return stakersCooldowns[user].timestamp;
    }

    // Returns the asset's emission per second from the sturct
    function getAssetEmissionPerSecond(address token) public view returns (uint128) {
        return assets[token].emissionPerSecond;
    }

    // Returns the asset's last updated timestamp from the sturct
    function getAssetLastUpdateTimestamp(address token) public view returns (uint128) {
        return assets[token].lastUpdateTimestamp;
    }

    // Returns the asset's global index from the sturct
    function getAssetGlobalIndex(address token) public view returns (uint256) {
        return assets[token].index;
    }

    // Returns the user's personal index for the specific asset
    function getUserPersonalIndex(address token, address user) public view returns (uint256) {
        return assets[token].users[user];
    }

    // returns user's token balance, used in some community rules
    function getBalance(address user) public view returns (uint104) {
        return _balances[user].balance;
    }

    // returns user's rewards already accumulated in stake-token
    function getStakerRewardsToClaim(address user) public view returns (uint256) {
        return stakerRewardsToClaim[user];
    }

}
