| Name                                | Type                                                            | Slot | Offset | Bytes | Contract                                 |
|-------------------------------------|-----------------------------------------------------------------|------|--------|-------|------------------------------------------|
| _balances                           | mapping(address => struct BaseAaveToken.DelegationAwareBalance) | 0    | 0      | 32    | tmp/EtherscanFlattened.sol:StakedTokenV3 |
| _allowances                         | mapping(address => mapping(address => uint256))                 | 1    | 0      | 32    | tmp/EtherscanFlattened.sol:StakedTokenV3 |
| _totalSupply                        | uint256                                                         | 2    | 0      | 32    | tmp/EtherscanFlattened.sol:StakedTokenV3 |
| _name                               | string                                                          | 3    | 0      | 32    | tmp/EtherscanFlattened.sol:StakedTokenV3 |
| _symbol                             | string                                                          | 4    | 0      | 32    | tmp/EtherscanFlattened.sol:StakedTokenV3 |
| ______DEPRECATED_OLD_ERC20_DECIMALS | uint8                                                           | 5    | 0      | 1     | tmp/EtherscanFlattened.sol:StakedTokenV3 |
| __________DEPRECATED_GOV_V2_PART    | uint256[3]                                                      | 6    | 0      | 96    | tmp/EtherscanFlattened.sol:StakedTokenV3 |
| lastInitializedRevision             | uint256                                                         | 9    | 0      | 32    | tmp/EtherscanFlattened.sol:StakedTokenV3 |
| ______gap                           | uint256[50]                                                     | 10   | 0      | 1600  | tmp/EtherscanFlattened.sol:StakedTokenV3 |
| assets                              | mapping(address => struct AaveDistributionManager.AssetData)    | 60   | 0      | 32    | tmp/EtherscanFlattened.sol:StakedTokenV3 |
| stakerRewardsToClaim                | mapping(address => uint256)                                     | 61   | 0      | 32    | tmp/EtherscanFlattened.sol:StakedTokenV3 |
| stakersCooldowns                    | mapping(address => struct IStakedTokenV2.CooldownSnapshot)      | 62   | 0      | 32    | tmp/EtherscanFlattened.sol:StakedTokenV3 |
| ______DEPRECATED_FROM_STK_AAVE_V2   | uint256[5]                                                      | 63   | 0      | 160   | tmp/EtherscanFlattened.sol:StakedTokenV3 |
| _nonces                             | mapping(address => uint256)                                     | 68   | 0      | 32    | tmp/EtherscanFlattened.sol:StakedTokenV3 |
| _admins                             | mapping(uint256 => address)                                     | 69   | 0      | 32    | tmp/EtherscanFlattened.sol:StakedTokenV3 |
| _pendingAdmins                      | mapping(uint256 => address)                                     | 70   | 0      | 32    | tmp/EtherscanFlattened.sol:StakedTokenV3 |
| _votingDelegatee                    | mapping(address => address)                                     | 71   | 0      | 32    | tmp/EtherscanFlattened.sol:StakedTokenV3 |
| _propositionDelegatee               | mapping(address => address)                                     | 72   | 0      | 32    | tmp/EtherscanFlattened.sol:StakedTokenV3 |
| ______gap                           | uint256[6]                                                      | 73   | 0      | 192   | tmp/EtherscanFlattened.sol:StakedTokenV3 |
| _cooldownSeconds                    | uint256                                                         | 79   | 0      | 32    | tmp/EtherscanFlattened.sol:StakedTokenV3 |
| _maxSlashablePercentage             | uint256                                                         | 80   | 0      | 32    | tmp/EtherscanFlattened.sol:StakedTokenV3 |
| _currentExchangeRate                | uint216                                                         | 81   | 0      | 27    | tmp/EtherscanFlattened.sol:StakedTokenV3 |
| inPostSlashingPeriod                | bool                                                            | 81   | 27     | 1     | tmp/EtherscanFlattened.sol:StakedTokenV3 |
