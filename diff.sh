# diffs the contract against what is currently deployed as stkABPT, storage as well as code

# download stkABPT
cast etherscan-source --chain 1 -d etherscan/stkAAVE 0x0fE58FE1CaA69951dC924A8c222bE19013B89476

# flatten
forge flatten etherscan/stkAAVE/StakedAaveV3/src/contracts/StakedTokenV3.sol -o tmp/EtherscanFlattened.sol
forge flatten src/contracts/StakeToken.sol -o tmp/NewFlattened.sol

# fetch storage layout
forge inspect tmp/EtherscanFlattened.sol:StakedTokenV3 storage-layout --pretty > diffs/OldLayout.md
forge inspect tmp/NewFlattened.sol:StakeToken storage-layout --pretty > diffs/NewLayout.md

# diff the code
make git-diff before=tmp/EtherscanFlattened.sol after=tmp/NewFlattened.sol out=CodeDiff
