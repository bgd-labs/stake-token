import "base.spec";


/* ==================================
                          104
         32      64      96|
         |       |       | |           
0x123456789012345678901234567890
=================================== */

ghost mathint sumAllBalance {
    init_state axiom sumAllBalance == 0;
}
hook Sstore _balances[KEY address a].balance uint104 balance (uint104 old_balance) STORAGE {
    sumAllBalance = sumAllBalance - old_balance + balance;
}
hook Sload uint104 balance _balances[KEY address a].balance STORAGE {
    require to_mathint(balance) <= sumAllBalance;
}

// **********************************************
// The total supply equals the sum of all users' balances.
//
// Status: pass
// **********************************************
invariant inv_sumAllBalance_eq_totalSupply()
    sumAllBalance == to_mathint(totalSupply())
    &&
    to_mathint(totalSupply()) <= to_mathint(MAX_UINT104());


/*
    @Invariant totalSupplyGreaterThanUserBalance
    @Description: The total supply amount of shares is greater or equal to any user's share balance.
    @Link: https://prover.certora.com/output/40577/55c78438915b43cfa84014b153baee5e/?anonymousKey=cc47986c3d9dc44e8801e3e591ec56d048e26f30
*/
invariant totalSupplyGreaterThanUserBalance(address user)
    totalSupply() >= balanceOf(user)
{
    preserved {
        requireInvariant inv_sumAllBalance_eq_totalSupply();
    }
}


/*
    @Invariant balanceOfZero
    @Description: The balance of address zero is 0
    @Link: https://prover.certora.com/output/40577/55c78438915b43cfa84014b153baee5e/?anonymousKey=cc47986c3d9dc44e8801e3e591ec56d048e26f30
*/
invariant balanceOfZero()
    balanceOf(0) == 0;

/*
    @Invariant lowerBoundNotZero
    @Link: https://prover.certora.com/output/40577/55c78438915b43cfa84014b153baee5e/?anonymousKey=cc47986c3d9dc44e8801e3e591ec56d048e26f30
*/
invariant lowerBoundNotZero()
    LOWER_BOUND() > 0;

/*
    @Invariant cooldownDataCorrectness
    @Description: When cooldown amount of user nonzero, the cooldown had to be triggered
    @Link: https://prover.certora.com/output/40577/55c78438915b43cfa84014b153baee5e/?anonymousKey=cc47986c3d9dc44e8801e3e591ec56d048e26f30
*/
invariant cooldownDataCorrectness(address user, env e)
    cooldownAmount(user) > 0 => cooldownTimestamp(user) > 0
    {
        preserved with (env e2)
        {
            require e2.block.timestamp == e.block.timestamp;
            require e.block.timestamp > 0;
            require e.block.timestamp < 2^32;
        }
    }
    
/*
  @Invariant cooldownAmountNotGreaterThanBalance
  @Description: No user can have greater cooldown amount than is their balance.
  @Link: https://prover.certora.com/output/40577/55c78438915b43cfa84014b153baee5e/?anonymousKey=cc47986c3d9dc44e8801e3e591ec56d048e26f30
*/
invariant cooldownAmountNotGreaterThanBalance(address user)
    balanceOf(user) >= assert_uint256(cooldownAmount(user))
{
    preserved with (env e) {
        requireInvariant cooldownDataCorrectness(user, e);
        requireInvariant totalSupplyGreaterThanUserBalance(user);
        requireInvariant inv_sumAllBalance_eq_totalSupply();
    }
}


/*
    @Invariant PersonalIndexLessOrEqualGlobalIndex
    @Description: The personal index of a user on a specific asset is at most equal to the global index of the same asset.
                  As user's personal index is derived from the global index, and therefore cannot exceed it
    @Link: https://prover.certora.com/output/40577/55c78438915b43cfa84014b153baee5e/?anonymousKey=cc47986c3d9dc44e8801e3e591ec56d048e26f30
*/
invariant PersonalIndexLessOrEqualGlobalIndex(address asset, address user)
    getUserPersonalIndex(asset, user) <= getAssetGlobalIndex(asset);



//invariant correct_currentExchangeRate() 
//    to_mathint(totalSupply()) <= getExchangeRate() * stake_token.balanceOf(currentContract) / 10^18;




/* ====================================================================
   A solvency rule. 
   Note: 
   1. In the contranct that total underlying is calculated by previewRedeem(totalSupply()).
   2. We only check the affect of current contranct. This invariant can defenitely be 
      violated if, for example, a transfer reduces stake_token.balanceOf(currentContract)
      is performed in the stake_token contranct.
  ====================================================================*/
invariant calculated_bal_LEQ_real_bal()
    previewRedeem(totalSupply()) <= stake_token.balanceOf(currentContract)
    filtered {f -> f.contract == currentContract &&
        f.selector!=sig:initialize(string,string,address,address,address,uint256,uint256).selector
    }
{
    preserved with (env e)
    {
        require e.msg.sender != currentContract;
    }
}


function require_feasible_state(env e, address user) {
    require(user != 0 && user != currentContract);
    requireInvariant cooldownAmountNotGreaterThanBalance(user);
    requireInvariant inv_sumAllBalance_eq_totalSupply();
    requireInvariant calculated_bal_LEQ_real_bal();
    requireInvariant PersonalIndexLessOrEqualGlobalIndex(currentContract,user);
    require getAssetGlobalIndex(currentContract) <= 10^10;
    require getAssetEmissionPerSecond(currentContract) <= 10^10;
    require getStakerRewardsToClaim(user) <= AAVE_MAX_SUPPLY();
    require stake_token.balanceOf(user) <= AAVE_MAX_SUPPLY();
    require stake_token.balanceOf(currentContract) <= AAVE_MAX_SUPPLY();

    uint256 LUTS = getAssetLastUpdateTimestamp(currentContract);
    require LUTS <= e.block.timestamp && e.block.timestamp <= 2^40;
}

