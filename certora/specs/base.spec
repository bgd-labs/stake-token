using DummyERC20Impl as stake_token;
using DummyERC20ImplRewards as reward_token;

methods {
    function stake_token.balanceOf(address) external returns (uint256) envfree;
    function reward_token.balanceOf(address) external returns (uint256) envfree;

    // public variables
    function REWARDS_VAULT() external returns (address) envfree;
    function UNSTAKE_WINDOW() external returns (uint256) envfree;
    function LOWER_BOUND() external returns (uint256) envfree;

    // envfree
    function balanceOf(address) external returns (uint256) envfree;
    function cooldownAmount(address) external returns (uint216) envfree;
    function cooldownTimestamp(address) external returns (uint40) envfree;
    function totalSupply() external returns (uint256) envfree;
    function stakerRewardsToClaim(address) external returns (uint256) envfree;
    function stakersCooldowns(address) external returns (uint40, uint216) envfree;
    function getCooldownSeconds() external returns (uint256) envfree;
    function getExchangeRate() external returns (uint216) envfree;
    function inPostSlashingPeriod() external returns (bool) envfree;
    function getMaxSlashablePercentage() external returns (uint256) envfree;
    function getAssetGlobalIndex(address) external returns (uint256) envfree;
    function getAssetLastUpdateTimestamp(address) external returns (uint128) envfree;
    function getUserPersonalIndex(address, address) external returns (uint256) envfree;
    function getStakerRewardsToClaim(address) external returns (uint256) envfree;
    function previewStake(uint256) external returns (uint256) envfree;
    function previewRedeem(uint256) external returns (uint256) envfree;
    function getUserAssetData(address user, address asset) external returns (uint256) envfree;
    function getAssetEmissionPerSecond(address token) external returns (uint128) envfree;

    function _.permit(address, address, uint256, uint256, uint8, bytes32, bytes32) external => NONDET;
    function _.permit(address, address, uint256, uint256, uint8, bytes32, bytes32) internal => NONDET;

    // view but not envfree - uses block.timestamp
    function getNextCooldownTimestamp(uint256,uint256,address,uint256) external;
    function getPowerAtBlock(address,uint256,uint8) external returns (uint256);

    // state changing operations
    function initialize(address,address,address,uint256,uint256) external;
    function stake(address,uint256) external;
    function redeem(address,uint256) external;
    function slash(address,uint256) external returns (uint256);
    function returnFunds(uint256) external;
}

methods {
    function totalSupply()                         external returns (uint256)   envfree;
    function balanceOf(address)                    external returns (uint256)   envfree;
    function allowance(address,address)            external returns (uint256)   envfree;
    function increaseAllowance(address, uint256) external;
    function decreaseAllowance(address, uint256) external;
    function transfer(address,uint256) external;
    function transferFrom(address,address,uint256) external;
    function permit(address,address,uint256,uint256,uint8,bytes32,bytes32) external;

    function delegate(address delegatee) external;
    function metaDelegate(address,address,uint256,uint8,bytes32,bytes32) external;
    function metaDelegateByType(address,address,uint8,uint256,uint8,bytes32,bytes32) external;

    function getBalance(address user) external returns (uint104) envfree;

    function EXCHANGE_RATE_UNIT() external returns (uint256) envfree;
    function __clean(address user) external envfree;
    function was_updated(address user) external returns (bool) envfree;
}

definition AAVE_MAX_SUPPLY() returns uint256 = 16000000 * 10^18;
//definition MAX_UINT104() returns uint104 = 0xffffffffffffffffffffffffff;
definition MAX_UINT104() returns uint104 = max_uint104;
definition PERCENTAGE_FACTOR() returns uint256 = 10^4;

definition claimRewards_funcs(method f) returns bool =
(
    f.selector == sig:claimRewards(address, uint256).selector ||
    f.selector == sig:claimRewardsOnBehalf(address, address, uint256).selector ||
    f.selector == sig:claimRewardsAndRedeem(address, uint256, uint256).selector ||
    f.selector == sig:claimRewardsAndRedeemOnBehalf(address, address, uint256, uint256).selector
);

definition redeem_funcs(method f) returns bool =
(
    f.selector == sig:redeem(address, uint256).selector ||
    f.selector == sig:redeemOnBehalf(address, address, uint256).selector ||
    f.selector == sig:claimRewardsAndRedeem(address, uint256, uint256).selector ||
    f.selector == sig:claimRewardsAndRedeemOnBehalf(address, address, uint256, uint256).selector
);


//function upto_1(mathint a, mathint b) returns bool {
//    return  a==b  ||  a==b+1  ||  a+1==b;
//}
//function upto_2(mathint a, mathint b) returns bool {
//    return  a==b  ||  a==b+1  ||  a==b+2  ||  a==b-1  ||  a==b-2;
//}



definition is_redeem_method(method f) returns bool =
    (
     f.selector == sig:redeem(address,uint256).selector ||
     f.selector == sig:redeemOnBehalf(address,address,uint256).selector ||
     f.selector == sig:claimRewardsAndRedeem(address,uint256,uint256).selector ||
     f.selector == sig:claimRewardsAndRedeemOnBehalf(address,address,uint256,uint256).selector
    );

definition is_stake_method(method f) returns bool =
    (
     f.selector == sig:stake(address,uint256).selector ||
     f.selector == sig:stakeWithPermit(uint256,uint256,uint8,bytes32,bytes32).selector //||
    );

definition is_transfer_method(method f) returns bool =
    (
     f.selector == sig:transfer(address,uint256).selector ||
     f.selector == sig:transferFrom(address,address,uint256).selector
    );



function is_transfer_method_func(method f) returns bool {
    return
        f.selector == sig:transfer(address,uint256).selector ||
        f.selector == sig:transferFrom(address,address,uint256).selector;
}

definition is_admin_func(method f) returns bool =
    f.selector == sig:initialize(string,string,address,address,address,uint256,uint256).selector
    || f.selector == sig:settleSlashing().selector
    || f.selector == sig:slash(address,uint256).selector
    || f.selector == sig:returnFunds(uint256).selector
    || f.selector == sig:cooldownOnBehalfOf(address).selector
    || f.selector == sig:setCooldownSeconds(uint256).selector
    || f.selector == sig:claimRoleAdmin(uint256).selector
    || f.selector == sig:configureAssets(DistributionTypes.AssetConfigInput[]).selector
        ;


function get_maxSlashable() returns mathint {
    return previewRedeem(totalSupply()) *getMaxSlashablePercentage() / PERCENTAGE_FACTOR();
}





