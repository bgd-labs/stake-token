import "invariants.spec";
import "propertiesWithSummarizations.spec";

using RewardVault as reward_vault;

use invariant allSharesAreBacked;
use invariant cooldownAmountNotGreaterThanBalance;
use invariant cooldownDataCorrectness;
use invariant lowerBoundNotZero;
use invariant PersonalIndexLessOrEqualGlobalIndex;
use invariant totalSupplyGreaterThanUserBalance;
use invariant inv_sumAllBalance_eq_totalSupply;
use invariant calculated_bal_LEQ_real_bal;



/* ====================================================================
   In this file we gathered the rules that say the one user can't (badly) 
   affect other user.
   More specifically, we start with arbitrary state and let Alice perform
   a specific operation.
   Then we let Alice make the same operation (on same initial state), 
   but before that Bob is doing some operation. 
   We then check that the outcome of Alice wasn't badly affected by Bob.
   ==================================================================*/



/* ====================================================================
   Alice calls to redeem.

   Status: PASS
   ==================================================================*/
rule front_run__redeem(method f, env e) filtered {
    f -> !f.isView && f.contract == currentContract && !is_admin_func(f)
        && f.selector != sig:redeemOnBehalf(address,address,uint256).selector}
{
    address alice; address bob; uint256 amount_to_redeem;

    require alice != bob; require alice != currentContract; require bob != currentContract;
    require alice != reward_token; require alice != reward_vault;
    require_feasible_state(e,alice);
    require balanceOf(alice) + balanceOf(bob) <= sumAllBalance;

    storage initialStorage = lastStorage;

    uint256 alice_bal_before1 = stake_token.balanceOf(alice);
    redeemOnBehalf@withrevert(e,alice,alice,amount_to_redeem);
    require !lastReverted;
    uint256 alice_bal_after1 = stake_token.balanceOf(alice);

    // Here we start with the same initial-storage
    uint256 alice_bal_before2 = stake_token.balanceOf(alice) at initialStorage;
    env e2;  require e2.msg.sender==bob;
    require e2.block.timestamp <= e.block.timestamp;
    require_feasible_state(e2,bob);
    calldataarg args;
    if (f.selector == sig:transferFrom(address,address,uint256).selector) {
        address from; address to; uint256 a;
        require (from != alice);
        transferFrom(e2,from,to,a);
    }
    else if (f.selector == sig:redeemOnBehalf(address,address,uint256).selector) {
        address from; address to; uint256 a;
        require (from != alice);
        redeemOnBehalf(e2,from,to,a);
    }
    else if (f.selector == sig:claimRewardsAndRedeemOnBehalf(address,address,uint256,uint256).selector) {
        address from; address to; uint256 a; uint256 b;
        require (from != alice);
        claimRewardsAndRedeemOnBehalf(e2,from,to,a,b);
    }
    else {
        f(e2, args);
    }
    
    redeemOnBehalf@withrevert(e, alice,alice,amount_to_redeem);
    assert !lastReverted;
    uint256 alice_bal_after2 = stake_token.balanceOf(alice);

    assert alice_bal_before1 == alice_bal_before2;
    assert alice_bal_after1 <= alice_bal_after2;
}

/* ====================================================================
   Part of Alice calls to redeem. Here Bob calls redeemOnBehalf(...).

   Status: PASS
   ==================================================================*/
rule front_run__redeem__on_redeemOnBahalf(env e) {
    address alice; address bob; uint256 amount_to_redeem;

    require alice != bob; require alice != currentContract; require bob != currentContract;
    require alice != reward_token; require alice != reward_vault;
    require_feasible_state(e,alice);
    require balanceOf(alice) + balanceOf(bob) <= sumAllBalance;

    storage initialStorage = lastStorage;

    uint256 alice_bal_before1 = stake_token.balanceOf(alice);
    redeemOnBehalf@withrevert(e,alice,alice,amount_to_redeem);
    require !lastReverted;
    uint256 alice_bal_after1 = stake_token.balanceOf(alice);

    // Here we start with the same initial-storage
    uint256 alice_bal_before2 = stake_token.balanceOf(alice) at initialStorage;
    env e2;  require e2.msg.sender==bob;
    require e2.block.timestamp <= e.block.timestamp;
    require_feasible_state(e2,bob);

        address from; address to; uint256 a;
        require (from != alice);
        redeemOnBehalf(e2,from,to,a);
    
    redeemOnBehalf@withrevert(e, alice,alice,amount_to_redeem);
    assert !lastReverted;
    uint256 alice_bal_after2 = stake_token.balanceOf(alice);

    assert alice_bal_before1 == alice_bal_before2;
    assert alice_bal_after1 <= alice_bal_after2;
}




/* ====================================================================
   The following rule is deprecated ! It is contained in the rule
   front_run__redeem.
   ==================================================================*/
rule front_run__redeem_no_revert(method f, env e) filtered {
    f -> !f.isView && f.contract == currentContract && !is_admin_func(f)}
{
    address alice; address bob;
    uint256 amount_to_redeem;

    require alice != bob; require alice != currentContract; require bob != currentContract;
    require alice != reward_token; require alice != reward_vault;
    requireInvariant inv_sumAllBalance_eq_totalSupply();
    storage initialStorage = lastStorage;

    uint256 alice_bal_before1 = stake_token.balanceOf(alice);
    redeemOnBehalf(e, alice,alice,amount_to_redeem);
    uint256 alice_bal_after1 = stake_token.balanceOf(alice);

    uint256 alice_bal_before2 = stake_token.balanceOf(alice) at initialStorage;
    env e2;  require e2.msg.sender==bob;
    calldataarg args;
    if (f.selector == sig:transferFrom(address,address,uint256).selector) {
        address from; address to; uint256 a;
        require (from != alice);
        transferFrom(e2,from,to,a);
    }
    else if (f.selector == sig:redeemOnBehalf(address,address,uint256).selector) {
        address from; address to; uint256 a;
        require (from != alice);
        redeemOnBehalf(e2,from,to,a);
    }
    else if (f.selector == sig:claimRewardsAndRedeemOnBehalf(address,address,uint256,uint256).selector) {
        address from; address to; uint256 a; uint256 b;
        require (from != alice);
        claimRewardsAndRedeemOnBehalf(e2,from,to,a,b);
    }
    else {
        f(e2, args);
    }
    
    redeemOnBehalf(e, alice,alice,amount_to_redeem);
    uint256 alice_bal_after2 = stake_token.balanceOf(alice);

    assert alice_bal_before1 == alice_bal_before2;
    assert alice_bal_after1 <= alice_bal_after2;
}


/* ====================================================================
   The balance of Alice can't be badly affected by any operation of Bob.

   Status: PASS
   ==================================================================*/
rule front_run__balance (method f, env e) filtered {
    f -> !f.isView && f.contract == currentContract && !is_admin_func(f) }
{
    
    address alice; address bob;

    require alice != bob; require alice != currentContract; require bob != currentContract;
    require alice != reward_token;  require alice != reward_vault;
    requireInvariant inv_sumAllBalance_eq_totalSupply();

    uint256 alice_bal_1 = balanceOf(alice);

    env e2;  require e2.msg.sender==bob;
    calldataarg args;
    if (f.selector == sig:transferFrom(address,address,uint256).selector) {
        address from; address to; uint256 a;
        require (from != alice);
        transferFrom(e2,from,to,a);
    }
    else if (f.selector == sig:redeemOnBehalf(address,address,uint256).selector) {
        address from; address to; uint256 a;
        require (from != alice);
        redeemOnBehalf(e2,from,to,a);
    }
    else if (f.selector == sig:claimRewardsAndRedeemOnBehalf(address,address,uint256,uint256).selector) {
        address from; address to; uint256 a; uint256 b;
        require (from != alice);
        claimRewardsAndRedeemOnBehalf(e2,from,to,a,b);
    }
    else {
        f(e2, args);
    }
    
    uint256 alice_bal_2 = balanceOf(alice);

    assert alice_bal_1 <= alice_bal_2;
}


/* ====================================================================
   The cooldown-info of Alice can't be affected by any operation of Bob.

   Status: PASS
   ==================================================================*/
rule front_run__cooldown_info(method f, env e) filtered {
    f -> !f.isView && f.contract == currentContract && !is_admin_func(f) }
{   
    address alice; address bob;

    require alice != 0 && bob != 0;
    require alice != bob; require alice != currentContract; require bob != currentContract;
    require alice != reward_token;  require alice != reward_vault;
    requireInvariant inv_sumAllBalance_eq_totalSupply();

    uint40 cooldownStart_1; uint216 sharesCooldownStart_1;
    cooldownStart_1, sharesCooldownStart_1 = stakersCooldowns(alice);

    env e2;  require e2.msg.sender==bob;
    calldataarg args;
    if (f.selector == sig:transferFrom(address,address,uint256).selector) {
        address from; address to; uint256 a;
        require (from != alice);
        transferFrom(e2,from,to,a);
    }
    else if (f.selector == sig:redeemOnBehalf(address,address,uint256).selector) {
        address from; address to; uint256 a;
        require (from != alice);
        redeemOnBehalf(e2,from,to,a);
    }
    else if (f.selector == sig:claimRewardsAndRedeemOnBehalf(address,address,uint256,uint256).selector) {
        address from; address to; uint256 a; uint256 b;
        require (from != alice);
        claimRewardsAndRedeemOnBehalf(e2,from,to,a,b);
    }
    else
    f(e2, args);
    
    uint40 cooldownStart_2; uint216 sharesCooldownStart_2;
    cooldownStart_2, sharesCooldownStart_2 = stakersCooldowns(alice);

    assert cooldownStart_1 == cooldownStart_2;
    assert sharesCooldownStart_1 == sharesCooldownStart_2;
}







/* ====================================================================
   Alice calls to stake.

   Status: PASS
   ==================================================================*/
rule front_run__stake(method f, env e) filtered {
    f -> !f.isView && f.contract == currentContract && !is_admin_func(f)
    && f.selector != sig:stakeWithPermit(uint256,uint256,uint8,bytes32,bytes32).selector }
{
    address alice; address bob; uint256 amount_to_stake;

    require alice != bob; require alice != currentContract; require bob != currentContract;
    require alice != reward_token; require alice != reward_vault;
    require e.msg.sender == alice;
    require_feasible_state(e,alice);
    require (to_mathint(getExchangeRate()) <= 100*EXCHANGE_RATE_UNIT() );
    require totalSupply() <= AAVE_MAX_SUPPLY();
    require balanceOf(alice) + balanceOf(bob) <= sumAllBalance;

    storage initialStorage = lastStorage;

    uint256 alice_bal_before1 = balanceOf(alice);
    //    require e.msg.sender != bob;
    //require e.msg.sender != currentContract;
    //require e.msg.sender != stake_token;
    //require e.msg.sender != reward_token;
    stake@withrevert(e,alice,amount_to_stake);
    require !lastReverted;
    uint256 alice_bal_after1 = stake_token.balanceOf(alice);

    // Here we start with the same initial-storage
    uint256 alice_bal_before2 = balanceOf(alice) at initialStorage;
    env e2;  require e2.msg.sender==bob;
    require e2.block.timestamp <= e.block.timestamp;
    require_feasible_state(e2,bob);
    calldataarg args;
    if (f.selector == sig:transferFrom(address,address,uint256).selector) {
        address from; address to; uint256 a;
        require (from != alice);
        transferFrom(e2,from,to,a);
    }
    else if (f.selector == sig:redeemOnBehalf(address,address,uint256).selector) {
        address from; address to; uint256 a;
        require (from != alice);
        redeemOnBehalf(e2,from,to,a);
    }
    else if (f.selector == sig:claimRewardsAndRedeemOnBehalf(address,address,uint256,uint256).selector) {
        address from; address to; uint256 a; uint256 b;
        require (from != alice);
        claimRewardsAndRedeemOnBehalf(e2,from,to,a,b);
    }
    else {
        f(e2, args);
    }
    
    // alice operation 
    stake@withrevert(e,alice,amount_to_stake);
    assert !lastReverted;
    uint256 alice_bal_after2 = stake_token.balanceOf(alice);

    assert alice_bal_before1 == alice_bal_before2;
    assert alice_bal_after1 <= alice_bal_after2;
}

/* ====================================================================
   Part of Alice calls to stake, but Bob calls stakeWithPermit(...).

   Status: PASS
   ==================================================================*/
rule front_run__stake__on_stakeWithPermit(env e) {
    address alice; address bob; uint256 amount_to_stake;

    require alice != bob; require alice != currentContract; require bob != currentContract;
    require alice != reward_token; require alice != reward_vault;
    require e.msg.sender == alice;
    require_feasible_state(e,alice);
    require (to_mathint(getExchangeRate()) <= 100*EXCHANGE_RATE_UNIT() );
    require totalSupply() <= AAVE_MAX_SUPPLY();
    require balanceOf(alice) + balanceOf(bob) <= sumAllBalance;

    storage initialStorage = lastStorage;

    uint256 alice_bal_before1 = balanceOf(alice);
    stake@withrevert(e,alice,amount_to_stake);
    require !lastReverted;
    uint256 alice_bal_after1 = stake_token.balanceOf(alice);

    // Here we start with the same initial-storage
    uint256 alice_bal_before2 = balanceOf(alice) at initialStorage;
    env e2;  require e2.msg.sender==bob;
    require e2.block.timestamp <= e.block.timestamp;
    require_feasible_state(e2,bob);

    uint256 amount; uint256 deadline; uint8 v; bytes32 r; bytes32 s;
    stakeWithPermit(e2,amount,deadline,v,r,s);
    
    // alice operation 
    stake@withrevert(e,alice,amount_to_stake);
    assert !lastReverted;
    uint256 alice_bal_after2 = stake_token.balanceOf(alice);

    assert alice_bal_before1 == alice_bal_before2;
    assert alice_bal_after1 <= alice_bal_after2;
}


