| Name                  | Type                                                    | Slot | Offset | Bytes | Contract                        |
| --------------------- | ------------------------------------------------------- | ---- | ------ | ----- | ------------------------------- |
| \_balances            | mapping(address => struct ERC20.DelegationAwareBalance) | 0    | 0      | 32    | tmp/NewFlattened.sol:StakeToken |
| \_allowances          | mapping(address => mapping(address => uint256))         | 1    | 0      | 32    | tmp/NewFlattened.sol:StakeToken |
| \_totalSupply         | uint256                                                 | 2    | 0      | 32    | tmp/NewFlattened.sol:StakeToken |
| \_name                | string                                                  | 3    | 0      | 32    | tmp/NewFlattened.sol:StakeToken |
| \_symbol              | string                                                  | 4    | 0      | 32    | tmp/NewFlattened.sol:StakeToken |
| \_nameFallback        | string                                                  | 5    | 0      | 32    | tmp/NewFlattened.sol:StakeToken |
| \_versionFallback     | string                                                  | 6    | 0      | 32    | tmp/NewFlattened.sol:StakeToken |
| \_nonces              | mapping(address => uint256)                             | 7    | 0      | 32    | tmp/NewFlattened.sol:StakeToken |
| stakerRewardsToClaim  | mapping(address => uint256)                             | 8    | 0      | 32    | tmp/NewFlattened.sol:StakeToken |
| stakersCooldowns      | mapping(address => struct IStakeToken.CooldownSnapshot) | 9    | 0      | 32    | tmp/NewFlattened.sol:StakeToken |
| \_smConfig            | struct IStakeToken.SmConfig                             | 10   | 0      | 32    | tmp/NewFlattened.sol:StakeToken |
| \_currentExchangeRate | uint216                                                 | 11   | 0      | 27    | tmp/NewFlattened.sol:StakeToken |
| slashingAdmin         | address                                                 | 12   | 0      | 20    | tmp/NewFlattened.sol:StakeToken |
| minAssetsRemaining    | uint256                                                 | 13   | 0      | 32    | tmp/NewFlattened.sol:StakeToken |
