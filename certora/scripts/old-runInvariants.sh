certoraRun certora/harness/StakedAaveV3Harness.sol \
    certora/harness/DummyERC20Impl.sol \
    --link StakedAaveV3Harness:STAKED_TOKEN=DummyERC20Impl \
    --link StakedAaveV3Harness:REWARD_TOKEN=DummyERC20Impl \
    --verify StakedAaveV3Harness:certora/specs/invariants.spec \
    --solc solc8.17 \
    --cloud \
    --send_only \
    --optimistic_loop \
    --loop_iter 3 \
    --rule $1 $2 $3 $4 $5 $6 $7 $8 $9 ${10} ${11} ${12} ${13} ${14} ${15} ${16} \
    --msg "invariants"
