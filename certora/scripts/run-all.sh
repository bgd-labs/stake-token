

echo "1:"
certoraRun  certora/conf/frontRun.conf   \
            --rule front_run__stake \
            --msg "1. frontRun.conf:: front_run__stake"

echo "2:"
certoraRun  certora/conf/frontRun.conf   \
            --rule front_run__stake__on_stakeWithPermit \
            --msg "2. frontRun.conf:: front_run__stake__on_stakeWithPermit"

echo "3:"
certoraRun  certora/conf/frontRun.conf   \
            --rule front_run__redeem \
            --msg "3. frontRun.conf:: front_run__redeem"

echo "4:"
certoraRun  certora/conf/frontRun.conf   \
            --rule front_run__redeem__on_redeemOnBahalf \
            --msg "4. frontRun.conf:: front_run__redeem__on_redeemOnBahalf"

echo "5:"
certoraRun  certora/conf/frontRun.conf   \
            --rule front_run__balance \
            --msg "5. frontRun.conf:: front_run__balance"

echo "6:"
certoraRun  certora/conf/frontRun.conf   \
            --rule front_run__cooldown_info \
            --msg "6. frontRun.conf:: front_run__cooldown_info"

echo "7:"
certoraRun  certora/conf/allProps.conf \
            --rule integrityOfStaking \
            --rule noStakingPostSlashingPeriod \
            --rule noSlashingMoreThanMax \
            --rule integrityOfSlashing \
            --rule integrityOfReturnFunds \
            --rule noRedeemOutOfUnstakeWindow \
            --rule totalSupplyDoesNotDropToZero \
            --rule cooldownCorrectness \
            --rule rewardsGetterEquivalentClaim \
            --rule rewardsMonotonicallyIncrease \
            --rule rewardsIncreaseForNonClaimFunctions \
            --rule indexesMonotonicallyIncrease \
            --rule slashingDontDecreaseExchangeRate \
            --rule returnFundsDontIncreaseExchangeRate \
            --rule exchangeRateNeverZero \
            --rule integrityOfRedeem \
            --rule previewStakeEquivalentStake \
            --rule redeem_in_post_slashing_period \
            --rule exchangeRate_cant_changed_unless_slash_returnFunds \
            --rule cooldown_always_updates_cooldown_info \
            --rule when_changing_bal_update_rewards_must_be_called \
            --rule transfer_from_user_to_itself_changes_no_balance \
            --rule slash_increases_exchangeRate \
            --rule returnFunds_decreases_exchangeRate \
            --rule redeem_not_reverting \
            --msg "7. allProps.conf::  all rules"


echo "8:"
certoraRun  certora/conf/allProps.conf \
            --rule_sanity none \
            --rule slashing_cant_occur_during_post_slashing_period \
            --msg "8. slashing_cant_occur_during_post_slashing_period"

echo "9:"
certoraRun  certora/conf/propertiesWithSummarization.conf \
            --msg "9. propertiesWithSummarization.conf"

echo "10:"
certoraRun  certora/conf/invariants.conf \
            --msg "10. invariants.conf"



