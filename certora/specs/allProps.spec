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




/*
    @Rule integrityOfStaking
    @Description: successful stake function move amount of the stake token from the sender to the contract
                  and increases the sender's shares balance accordinly.

    @Formula:
        {
            balanceStakeTokenDepositorBefore := stake_token.balanceOf(msg.sender),
            balanceStakeTokenVaultBefore := stake_token.balanceOf(currentContract),
            balanceBefore := balanceOf(to)
        }
            stake(to, amount)
        {
            balanceOf(to) = balanceBefore + amount * currentExchangeRate / EXCHANGE_RATE_UNIT(),
            stake_token.balanceOf(msg.sender) = balanceStakeTokenDepositorBefore - amount,
            stake_token.balanceOf(currentContract) = balanceStakeTokenVaultBefore + amount
        }

    @Notes:
    @Link: https://prover.certora.com/output/40577/3fdb151c46c84b1ab323b99c80890273/?anonymousKey=68e37ada870b7b91c68a5eadaf6030f3989002a6
*/
rule integrityOfStaking(address to, uint256 amount) {
    env e;
    require(e.msg.sender != currentContract);

    uint256 balanceStakeTokenDepositorBefore = stake_token.balanceOf(e.msg.sender);
    uint256 balanceStakeTokenVaultBefore = stake_token.balanceOf(currentContract);
    uint256 balanceBefore = balanceOf(to);
    uint72 cooldownBefore;
    cooldownBefore, _ = stakersCooldowns(to);
    require(cooldownBefore == 0);
    requireInvariant inv_sumAllBalance_eq_totalSupply();
    stake(e, to, amount);
    uint256 balanceAfter = balanceOf(to);
    uint256 balanceStakeTokenDepositorAfter = stake_token.balanceOf(e.msg.sender);
    uint256 balanceStakeTokenVaultAfter = stake_token.balanceOf(currentContract);

    uint216 currentExchangeRate = getExchangeRate();

    assert to_mathint(balanceAfter) == balanceBefore +
        amount * currentExchangeRate / EXCHANGE_RATE_UNIT();
    assert to_mathint(balanceStakeTokenDepositorAfter) == balanceStakeTokenDepositorBefore - amount;
    assert to_mathint(balanceStakeTokenVaultAfter) == balanceStakeTokenVaultBefore + amount;
}

/*
    @Rule noStakingPostSlashingPeriod
    @Description: Rule to verify that no user can stake while in post-slashing period.

    @Formula:
            stake(onBehalfOf, amount)
        {
            inPostSlashingPeriod = true => function reverts
        }

    @Notes:
    @Link: https://prover.certora.com/output/40577/3fdb151c46c84b1ab323b99c80890273/?anonymousKey=68e37ada870b7b91c68a5eadaf6030f3989002a6
*/
rule noStakingPostSlashingPeriod(address onBehalfOf, uint256 amount) {
    env e;
    require(inPostSlashingPeriod());
    stake@withrevert(e, onBehalfOf, amount);
    assert lastReverted, "should not be able to stake in post slashing period";
}

/*
    @Rule noSlashingMoreThanMax
    @Description: Rule to verify that slashing can't exceed the available slashing amount.

    @Formula:
        {
            vaultBalanceBefore := stake_token.balanceOf(currentContract),
            maxSlashable := vaultBalanceBefore * MaxSlashablePercentage / PERCENTAGE_FACTOR
        }
            slash(recipient, amount)
        {
            vaultBalanceBefore - stake_token.balanceOf(currentContract) = maxSlashable
        }

    @Notes:
    @Link: https://prover.certora.com/output/40577/3fdb151c46c84b1ab323b99c80890273/?anonymousKey=68e37ada870b7b91c68a5eadaf6030f3989002a6
*/
rule noSlashingMoreThanMax(uint256 amount, address recipient) {
    env e;
    require(getMaxSlashablePercentage() <= PERCENTAGE_FACTOR());
    uint vaultBalanceBefore = stake_token.balanceOf(currentContract);

    // We calculate maxSlashable the same way it is calculated in slash(...)
    mathint maxSlashable = get_maxSlashable();

    require (to_mathint(amount) > maxSlashable);
    require (recipient != currentContract);
    slash(e, recipient, amount);

    uint vaultBalanceAfter = stake_token.balanceOf(currentContract);
    
    assert vaultBalanceBefore - vaultBalanceAfter == maxSlashable;
}

/*
    @Rule integrityOfSlashing
    @Description: successful slash function increases the recipient balance by the slashed amount,
                  decreases the vaults balance by the same amount and turns on the postSlashing period flag.

    @Formula:
        {
            recipientStakeTokenBalanceBefore := stake_token.balanceOf(recipient),
            vaultStakeTokenBalanceBefore := stake_token.balanceOf(currentContract)
        }
            slash(recipient, amountToSlash)
        {
            stake_token.balanceOf(recipient) = recipientStakeTokenBalanceBefore + amountToSlash,
            stake_token.balanceOf(currentContract) = vaultStakeTokenBalanceBefore - amountToSlash,
            inPostSlashingPeriod = True
        }

    @Notes:
    @Link: https://prover.certora.com/output/40577/3fdb151c46c84b1ab323b99c80890273/?anonymousKey=68e37ada870b7b91c68a5eadaf6030f3989002a6
*/
rule integrityOfSlashing(address to, uint256 amount) {
    env e;
    require(e.msg.sender != currentContract && to != currentContract);
    require(getMaxSlashablePercentage() <= PERCENTAGE_FACTOR());

    require(totalSupply() > 0);
    uint256 total = totalSupply();

    uint256 balanceStakeTokenToBefore = stake_token.balanceOf(to);
    uint256 balanceStakeTokenVaultBefore = stake_token.balanceOf(currentContract);
    // We calculate maxSlashable the same way it is calculated in slash(...)
    mathint maxSlashable = get_maxSlashable();
    slash(e, to, amount);
    uint256 balanceStakeTokenToAfter = stake_token.balanceOf(to);
    uint256 balanceStakeTokenVaultAfter = stake_token.balanceOf(currentContract);

    mathint amountToSlash;
    if (to_mathint(amount) > maxSlashable) {
        amountToSlash = maxSlashable;
    } else {
        amountToSlash = amount;
    }

    assert to_mathint(balanceStakeTokenToAfter) == balanceStakeTokenToBefore + amountToSlash;
    assert to_mathint(balanceStakeTokenVaultAfter) == balanceStakeTokenVaultBefore - amountToSlash;
    assert inPostSlashingPeriod();
}

/*
    @Rule integrityOfReturnFunds
    @Description: successful returnFunds function decreases the sender balance by the returned amount and
                  increases the vaults balance by the same amount.

    @Formula:
        {
            senderStakeTokenBalanceBefore := stake_token.balanceOf(msg.sender),
            vaultStakeTokenBalanceBefore := stake_token.balanceOf(currentContract)
        }
            returnFunds(amount)
        {
            stake_token.balanceOf(msg.sender) = recipientStakeTokenBalanceBefore - amount,
            stake_token.balanceOf(currentContract) = vaultStakeTokenBalanceBefore + amount
        }

    @Notes:
    @Link: https://prover.certora.com/output/40577/3fdb151c46c84b1ab323b99c80890273/?anonymousKey=68e37ada870b7b91c68a5eadaf6030f3989002a6
*/
rule integrityOfReturnFunds(uint256 amount) {
    env e;
    require(e.msg.sender != currentContract);

    uint256 balanceStakeTokenSenderBefore = stake_token.balanceOf(e.msg.sender);
    uint256 balanceStakeTokenVaultBefore = stake_token.balanceOf(currentContract);
    returnFunds(e, amount);
    uint256 balanceStakeTokenSenderAfter = stake_token.balanceOf(e.msg.sender);
    uint256 balanceStakeTokenVaultAfter = stake_token.balanceOf(currentContract);
    //    require(balanceStakeTokenVaultAfter > 0);

    assert to_mathint(balanceStakeTokenSenderAfter) == balanceStakeTokenSenderBefore - amount;
    assert to_mathint(balanceStakeTokenVaultAfter) == balanceStakeTokenVaultBefore + amount;
}


/*
    @Rule noRedeemOutOfUnstakeWindow
    @Description: Succesful redeem function means that the user's timestamp in within the unstake window or it's a post slashing period.

    @Formula:
        {
            cooldown := stakersCooldowns(msg.sender)
        }
            redeem(to, amount)
        {
            (inPostSlashingPeriod = true) ||
            (block.timestamp > cooldown + getCooldownSeconds() &&
            block.timestamp - (cooldown + getCooldownSeconds()) <= UNSTAKE_WINDOW)
        }

    @Notes:
    @Link: https://prover.certora.com/output/40577/3fdb151c46c84b1ab323b99c80890273/?anonymousKey=68e37ada870b7b91c68a5eadaf6030f3989002a6
*/
rule noRedeemOutOfUnstakeWindow(address to, uint256 amount) {
    env e;

    uint72 cooldown;
    cooldown, _ = stakersCooldowns(e.msg.sender);
    redeem(e, to, amount);

    // assert cooldown is inside the unstake window or it's a post slashing period
    assert inPostSlashingPeriod() ||
        (to_mathint(e.block.timestamp) >= to_mathint(cooldown) + getCooldownSeconds() &&
         to_mathint(e.block.timestamp) - (to_mathint(cooldown) + getCooldownSeconds()) <= to_mathint(UNSTAKE_WINDOW()));
}

/*
    @Rule totalSupplyDoesNotDropToZero
    @Description: When the totalSupply is positive, it can never become zero.
    @Notes:
    @Link: https://prover.certora.com/output/40577/ff250297b015412ca205db4ed18253e3/?anonymousKey=09c506cb5a75a7ca18379f9650b482ac15cc1f67
*/
rule totalSupplyDoesNotDropToZero(method f, calldataarg args, env e) filtered {
    f -> !f.isView && !redeem_funcs(f)
} {
    require totalSupply() > 0;

    f(e, args);

    assert totalSupply() > 0;
}

/*
    @Rule cooldownCorrectness
    @Description: Rule to verify the correctness of stakersCooldowns.

    @Notes: During unstake period, each user should be able to unstake at most
            the amount they had when the cooldown has been initiated.
    @Link: https://prover.certora.com/output/40577/3fdb151c46c84b1ab323b99c80890273/?anonymousKey=68e37ada870b7b91c68a5eadaf6030f3989002a6
*/
rule cooldownCorrectness(env e) {
    calldataarg args;
    address user = e.msg.sender;
    require(user != 0 && user != currentContract);
    requireInvariant cooldownAmountNotGreaterThanBalance(user);
    requireInvariant inv_sumAllBalance_eq_totalSupply();

    uint40 cooldownStart;
    uint216 sharesCooldownStart;
    uint256 amountToUnstake;
    address to;
    cooldownStart, sharesCooldownStart = stakersCooldowns(user); // timestamp when was the cooldown initiated
    uint256 sharesBefore = balanceOf(user); // number of shares


    require(sharesBefore >= require_uint256(sharesCooldownStart));
    // The following 3 requirements make sure we are in the unstake period
    require(cooldownStart > 0);
    require(to_mathint(e.block.timestamp) > cooldownStart + getCooldownSeconds());
    require(to_mathint(e.block.timestamp) - (cooldownStart + getCooldownSeconds()) <= to_mathint(UNSTAKE_WINDOW()));

    redeem(e, to, amountToUnstake);
    mathint soldShares = sharesBefore - balanceOf(user);

    assert amountToUnstake <= assert_uint256(sharesCooldownStart)
        => soldShares == to_mathint(amountToUnstake);
    assert (amountToUnstake > assert_uint256(sharesCooldownStart)
            && !inPostSlashingPeriod())
        => soldShares == to_mathint(sharesCooldownStart);
}



/*
    @Rule rewardsGetterEquivalentClaim
    @Description: Rewards getter returns the same amount of max rewards the user deserve (if the user was to withdraw max).

    @Formula:
        {
            deservedRewards := getTotalRewardsBalance(from),
            receiverBalanceBefore := reward_token.balanceOf(receiver)
        }
            claimedAmount := claimRewardsOnBehalf(from, receiver, max_uint256)
        {
            deservedRewards = claimedAmount,
            reward_token.balanceOf(receiver) = receiverBalanceBefore + claimedAmount
        }

    @Notes:
    @Link: https://prover.certora.com/output/40577/3fdb151c46c84b1ab323b99c80890273/?anonymousKey=68e37ada870b7b91c68a5eadaf6030f3989002a6
*/
rule rewardsGetterEquivalentClaim(env e, address to, address from) {
    require to != REWARDS_VAULT();
    uint256 deservedRewards = getTotalRewardsBalance(e, from);
    uint256 _receiverBalance = reward_token.balanceOf(to);

    uint256 claimedAmount = claimRewardsOnBehalf(e, from, to, max_uint256);

    uint256 receiverBalance_ = reward_token.balanceOf(to);

    assert(deservedRewards == claimedAmount);
    assert(to_mathint(receiverBalance_) == _receiverBalance + claimedAmount);
}

/*
    @Rule rewardsMonotonicallyIncrease
    @Description: Rewards monotonically increasing as time progresses.

    @Notes:
    @Link: https://prover.certora.com/output/40577/3fdb151c46c84b1ab323b99c80890273/?anonymousKey=68e37ada870b7b91c68a5eadaf6030f3989002a6
*/
rule rewardsMonotonicallyIncrease(address user, env e, env e2) {
    uint256 _deservedRewards = getTotalRewardsBalance(e, user);

    require e2.block.timestamp >= e.block.timestamp;

    uint256 deservedRewards_ = getTotalRewardsBalance(e2, user);

    assert(deservedRewards_ >= _deservedRewards);
}

/*
    @Rule rewardsIncreaseForNonClaimFunctions
    @Description: Rewards monotonically increasing for non claim functions.

    @Formula:
        {
            deservedRewardsBefore := getTotalRewardsBalance(user)
        }
            <invoke any method f>
        {
            deservedRewardsAfter := getTotalRewardsBalance(user)

            f != claimRewards(address, uint256) &&
            f != claimRewardsOnBehalf(address, address, uint256) &&
            f != claimRewardsAndStake(address, uint256) &&
            f != claimRewardsAndStakeOnBehalf(address, address, uint256) &&
            f != claimRewardsAndRedeem(address, uint256, uint256) &&
            f != claimRewardsAndRedeemOnBehalf(address, address, uint256, uint256)
            => deservedRewardsBefore <= deservedRewardsAfter
        }
    @Notes: We skip verification for view functions as those cannot change anything.
    @Link: https://prover.certora.com/output/40577/3fdb151c46c84b1ab323b99c80890273/?anonymousKey=68e37ada870b7b91c68a5eadaf6030f3989002a6
*/
rule rewardsIncreaseForNonClaimFunctions(method f, address user, env e) filtered {
    f -> !f.isView && !claimRewards_funcs(f)
} {
    uint256 _deservedRewards = getTotalRewardsBalance(e, user);

    requireInvariant totalSupplyGreaterThanUserBalance(user);
    requireInvariant allSharesAreBacked();

    calldataarg args;
    f(e, args);

    uint256 deservedRewards_ = getTotalRewardsBalance(e, user);

    assert(deservedRewards_ >= _deservedRewards);
}

/*
    @Rule indexesMonotonicallyIncrease
    @Description: Global index monotonically increasing.

    @Formula:
        {
            globalIndexBefore := getAssetGlobalIndex(asset),
            personalIndexBefore := getUserPersonalIndex(asset, user)
        }
            <invoke any method f>
        {
            getAssetGlobalIndex(asset) >= globalIndexBefore,
            getUserPersonalIndex(asset, user) >= personalIndexBefore
        }

    @Notes:
    @Link: https://prover.certora.com/output/40577/3fdb151c46c84b1ab323b99c80890273/?anonymousKey=68e37ada870b7b91c68a5eadaf6030f3989002a6
*/
rule indexesMonotonicallyIncrease(method f, address asset, address user) {
    requireInvariant PersonalIndexLessOrEqualGlobalIndex(asset, user);
    uint256 _globalIndex = getAssetGlobalIndex(asset);
    uint256 _personalIndex = getUserPersonalIndex(asset, user);

    env e; calldataarg args;
    f(e, args);

    uint256 globalIndex_ = getAssetGlobalIndex(asset);
    uint256 personalIndex_ = getUserPersonalIndex(asset, user);

    assert(globalIndex_ >= _globalIndex);
    assert(personalIndex_ >= _personalIndex);
}

/*
    @Rule slashingIncreaseExchangeRate
    @Description: Slashing increases the exchange rate.

    @Formula:
        {
            ExchangeRateBefore := getExchangeRate()
        }
            slash(args)
        {
            getExchangeRate() >= ExchangeRateBefore
        }

    @Notes:
    @Link: https://prover.certora.com/output/40577/3fdb151c46c84b1ab323b99c80890273/?anonymousKey=68e37ada870b7b91c68a5eadaf6030f3989002a6
*/
rule slashingDontDecreaseExchangeRate(address receiver, uint256 amount) {
    env e; calldataarg args;

    uint216 _ExchangeRate = getExchangeRate();

    slash(e, args);

    uint216 ExchangeRate_ = getExchangeRate();

    assert ExchangeRate_ >= _ExchangeRate;
}

/*
    @Rule returnFundsDecreaseExchangeRate
    @Description: Returning funds decreases the exchange rate.

    @Formula:
        {
            ExchangeRateBefore := getExchangeRate()
        }
            returnFunds(args)
        {
            getExchangeRate() <= ExchangeRateBefore
        }

    @Notes:
    @Link: https://prover.certora.com/output/40577/3fdb151c46c84b1ab323b99c80890273/?anonymousKey=68e37ada870b7b91c68a5eadaf6030f3989002a6
*/
rule returnFundsDontIncreaseExchangeRate(address receiver, uint256 amount) {
    env e;
    uint216 _ExchangeRate = getExchangeRate();

    // Currently, in the constructor, LOWER_BOUND = 10**decimals
    requireInvariant lowerBoundNotZero();

    returnFunds(e, amount);

    uint216 ExchangeRate_ = getExchangeRate();

    assert ExchangeRate_ <= _ExchangeRate;
}

/*
    @Rule exchangeRateNeverZero
    @Description: ExchangeRate can never be zero.

    @Formula:
        {
            ExchangeRateBefore := getExchangeRate()
        }
            <invoke any method f>
        {
            getExchangeRate() != 0
        }

    @Notes: We used the following require to prove, that violation of this rule happened
            when totalSupply() == 0:
            require f.selector == sig:returnFunds(uint256).selector => totalSupply() != 0;
            This has been solved by Lukas in this commit:
            https://github.com/Certora/aave-stk-slashing-mgmt/pull/1/commits/8336dc0747965a06c7dc39b4f89273c4ef7ed18a
    @Link: https://prover.certora.com/output/40577/3fdb151c46c84b1ab323b99c80890273/?anonymousKey=68e37ada870b7b91c68a5eadaf6030f3989002a6
*/
rule exchangeRateNeverZero(method f) {
    env e; calldataarg args;
    uint216 _ER = getExchangeRate();
    require _ER != 0;

    f(e, args);

    uint216 ER_ = getExchangeRate();

    assert ER_ != 0;
}

/*
    @Rule integrityOfRedeem
    @Description: When amount to redeem is not greater than the cooldown amount of the
        message sender, previewRedeem computes the same underlying amount as redeem.

    @Formula:
        {
            totalUnderlying := previewRedeem(amount),
            receiverBalanceBefore := stake_token.balanceOf(receiver)
        }
            redeem(receiver, amount)
        {
            receiverBalanceAfter := stake_token.balanceOf(receiver)
            amount <= cooldownAmount(e.msg.sender) =>
                totalUnderlying == receiverBalanceAfter - receiverBalanceBefore
        }

    @Notes:
    @Link: https://prover.certora.com/output/40577/3fdb151c46c84b1ab323b99c80890273/?anonymousKey=68e37ada870b7b91c68a5eadaf6030f3989002a6
*/
rule integrityOfRedeem(method f, env e, address to, uint256 amount) {
    //    require balanceOf(e.msg.sender) >= amount;
    requireInvariant cooldownAmountNotGreaterThanBalance(e.msg.sender);
    require currentContract != to;
    uint256 totalUnderlying = previewRedeem(amount);
    uint256 _receiverBalance = stake_token.balanceOf(to);

    redeem(e, to, amount);

    uint256 receiverBalance_ = stake_token.balanceOf(to);

    assert(amount <= assert_uint256(cooldownAmount(e.msg.sender)) =>
           to_mathint(totalUnderlying) == receiverBalance_ - _receiverBalance);
}

/*
    @Rule previewStakeEquivalentStake
    @Description: Preview stake function returns the same shares amount to stake (doing the same calculation).

    @Formula:
        {
            amountOfShares := previewStake(amount),
            receiverBalanceBefore := balanceOf(receiver)
        }
            stake(receiver, amount)
        {
            amountOfShares = previewStake(amount) - receiverBalanceBefore
        }

    @Notes:
    @Link: https://prover.certora.com/output/40577/3fdb151c46c84b1ab323b99c80890273/?anonymousKey=68e37ada870b7b91c68a5eadaf6030f3989002a6
*/
rule previewStakeEquivalentStake(method f, env e, address to, uint256 amount) {
    requireInvariant totalSupplyGreaterThanUserBalance(to);
    uint256 amountOfShares = previewStake(amount);
    uint256 _receiverBalance = balanceOf(to);

    stake(e, to, amount);

    uint256 receiverBalance_ = balanceOf(to);

    assert(to_mathint(amountOfShares) == receiverBalance_ - _receiverBalance);
}



/* ====================================================================
   The following is a liveness rule that is suposed to check the following:
   In the post-slashing-period, a user can redeem his shares even with amount that 
   is higher than the amount of the cooldown.

   Status: PASS
   ==================================================================*/
rule redeem_in_post_slashing_period(env e) {
    address to;

    require e.msg.value == 0;
    address user = e.msg.sender;
    require_feasible_state(e,user);
    require_feasible_state(e,to);
    
    uint256 amount_to_redeem;
    require 0 < amount_to_redeem && amount_to_redeem <= assert_uint256(MAX_UINT104());
    uint256 sharesBefore = balanceOf(user); // number of shares
    require (amount_to_redeem <= sharesBefore);
    require (previewRedeem(amount_to_redeem) <= stake_token.balanceOf(currentContract));

    require sharesBefore > 0;
    require inPostSlashingPeriod();
    require getExchangeRate() != 0;

    redeem@withrevert(e, to, amount_to_redeem);
    assert !lastReverted;
    
    mathint soldShares = sharesBefore - balanceOf(user);

    assert amount_to_redeem <= assert_uint256(sharesBefore) =>
        soldShares == to_mathint(amount_to_redeem);
    assert amount_to_redeem > assert_uint256(sharesBefore) =>
        soldShares == to_mathint(sharesBefore);
}




/* ====================================================================
   Only slash and returnFunds can change the exchangeRate.

   Status: PASS
   ==================================================================*/
rule exchangeRate_cant_changed_unless_slash_returnFunds(method f, env e) filtered {
    f ->
    !f.isView && f.contract == currentContract &&
        f.selector!=sig:initialize(string,string,address,address,address,uint256,uint256).selector
        && f.selector != sig:slash(address,uint256).selector
        && f.selector != sig:returnFunds(uint256).selector
        }
{
    uint216 exchangeRate_before = getExchangeRate();

    calldataarg args;
    f(e,args);
    
    uint216 exchangeRate_after = getExchangeRate();

    assert (exchangeRate_before==exchangeRate_after);
}




/* ===========================================================================
   cooldown always update cooldown-info (even if we are during cooldown period)

   Status: PASS
   ==========================================================================*/
rule cooldown_always_updates_cooldown_info() {
    env e;
    uint40 block_timestamp = require_uint40(e.block.timestamp);
    cooldown(e);
    
    assert cooldownTimestamp(e.msg.sender)==block_timestamp;
    assert (assert_uint256(cooldownAmount(e.msg.sender))==balanceOf(e.msg.sender));
}


/* ===========================================================================
   Check that the function _updateCurrentUnclaimedRewards(user ...) is called 
   each time that the balance of user is changed.

   Status: PASS
   ==========================================================================*/
rule when_changing_bal_update_rewards_must_be_called(method f)
    filtered {f -> !f.isView && f.contract == currentContract}
{
    address alice;
    __clean(alice);

    uint256 alice_bal_1 = balanceOf(alice);

    env e; calldataarg args;
    f(e,args);
    
    uint256 alice_bal_2 = balanceOf(alice);

    assert (alice_bal_1 != alice_bal_2) => was_updated(alice)==true;
}


/* ===========================================================================
   transfer with from==to can't change any balance in the system.

   Status: PASS
   ==========================================================================*/
rule transfer_from_user_to_itself_changes_no_balance() {
    env e; env e2;
    address bob; address alice;
    uint256 amount;

    uint256 alice_bal_before = balanceOf(alice);
    transferFrom(e,bob,bob,amount);
    uint256 alice_bal_after = balanceOf(alice);

    assert (alice_bal_before==alice_bal_after);
}





/* ===========================================================================
   The exchange-rate is increased after a call to slash().
   Note: to avoid failures due to rounding, we make several assumptions on the
         exchangeRate, totalSupply, and slashablePercentage.

   Status: PASS
   ==========================================================================*/
rule slash_increases_exchangeRate(env e) {
    require (to_mathint(getExchangeRate()) <= 10*EXCHANGE_RATE_UNIT() );
    require (EXCHANGE_RATE_UNIT()/10 <= to_mathint(getExchangeRate()) );
    require totalSupply() >= 1000;
    require to_mathint(getMaxSlashablePercentage()) >= PERCENTAGE_FACTOR()/10;

    uint256 total_underline = previewRedeem(totalSupply());

    uint216 exchange_rate_before = getExchangeRate();
        
    address a; uint256 amount_to_slash;
    require to_mathint(amount_to_slash) >= 9 * total_underline / 10;
    slash(e,a,amount_to_slash);

    uint216 exchange_rate_after = getExchangeRate();

    assert exchange_rate_before < exchange_rate_after;
}

/* ===========================================================================
   The exchange-rate is increased after a call to slash().
   Note: to avoid failures due to rounding, we make several assumptions on the
         exchangeRate, totalSupply, and slashablePercentage.

   Status: PASS
   ==========================================================================*/
rule returnFunds_decreases_exchangeRate(env e) {
    require (to_mathint(getExchangeRate()) <= 10*EXCHANGE_RATE_UNIT() );
    require (EXCHANGE_RATE_UNIT()/10 <= to_mathint(getExchangeRate()) );
    require totalSupply() >= 1000;
    require to_mathint(getMaxSlashablePercentage()) >= PERCENTAGE_FACTOR()/10;

    uint256 total_underline = previewRedeem(totalSupply());

    uint216 exchange_rate_before = getExchangeRate();
        
    address a; uint256 amount_to_give;
    require to_mathint(amount_to_give) >= 9 * total_underline / 10;
    returnFunds(e,amount_to_give);

    uint216 exchange_rate_after = getExchangeRate();

    assert exchange_rate_before > exchange_rate_after;
}



/* ===========================================================================
   If in post-slashing-period, only settleSlashing() can enable slashing again.

   Status: PASS
   Note: this rule is getting a failure from the rule_sanity check for all methods
   except settleSlashing(). This is the corect behaviour.
   ==========================================================================*/
rule slashing_cant_occur_during_post_slashing_period() {
    
    require inPostSlashingPeriod();

    method f;
    env e; calldataarg args;
    f(e,args);

    env e2;
    address a; uint256 amount;
    slash(e2,a,amount);
    bool reverted = lastReverted;
    
    assert !reverted => f.selector==sig:settleSlashing().selector;
}




/* ===========================================================================
   If we start with a "feasible-state", and the user has enough shares, then
   redeem must succeed.
   Note: this rule was written originally in order to understand what should be 
   a "feasible-state".

   Status: PASS
   ==========================================================================*/
rule redeem_not_reverting(env e) {
    require e.msg.value == 0;
    address user = e.msg.sender;
    require_feasible_state(e,user);
   
    uint256 amount_to_redeem;
    require 0 < amount_to_redeem && amount_to_redeem <= assert_uint256(MAX_UINT104());

    uint256 sharesBefore = balanceOf(user); // number of shares
    require (amount_to_redeem <= sharesBefore);
    require (previewRedeem(amount_to_redeem) <= stake_token.balanceOf(currentContract));

    require sharesBefore > 0;
    require inPostSlashingPeriod();
    require getExchangeRate() != 0;

    redeem@withrevert(e, user, amount_to_redeem);
    assert !lastReverted;
}
