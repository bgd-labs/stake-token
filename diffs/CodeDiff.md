```diff
diff --git a/tmp/EtherscanFlattened.sol b/tmp/NewFlattened.sol
index 5320452..c8a0414 100644
--- a/tmp/EtherscanFlattened.sol
+++ b/tmp/NewFlattened.sol
@@ -1,7 +1,236 @@
-// SPDX-License-Identifier: agpl-3.0
+// SPDX-License-Identifier: BUSL-1.1
 pragma solidity ^0.8.0;
 
-// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)
+// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)
+
+/**
+ * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
+ * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
+ * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
+ * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
+ *
+ * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
+ * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
+ * case an upgrade adds a module that needs to be initialized.
+ *
+ * For example:
+ *
+ * [.hljs-theme-light.nopadding]
+ * ```solidity
+ * contract MyToken is ERC20Upgradeable {
+ *     function initialize() initializer public {
+ *         __ERC20_init("MyToken", "MTK");
+ *     }
+ * }
+ *
+ * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
+ *     function initializeV2() reinitializer(2) public {
+ *         __ERC20Permit_init("MyToken");
+ *     }
+ * }
+ * ```
+ *
+ * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
+ * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
+ *
+ * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
+ * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
+ *
+ * [CAUTION]
+ * ====
+ * Avoid leaving a contract uninitialized.
+ *
+ * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
+ * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
+ * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
+ *
+ * [.hljs-theme-light.nopadding]
+ * ```
+ * /// @custom:oz-upgrades-unsafe-allow constructor
+ * constructor() {
+ *     _disableInitializers();
+ * }
+ * ```
+ * ====
+ */
+abstract contract Initializable {
+  /**
+   * @dev Storage of the initializable contract.
+   *
+   * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
+   * when using with upgradeable contracts.
+   *
+   * @custom:storage-location erc7201:openzeppelin.storage.Initializable
+   */
+  struct InitializableStorage {
+    /**
+     * @dev Indicates that the contract has been initialized.
+     */
+    uint64 _initialized;
+    /**
+     * @dev Indicates that the contract is in the process of being initialized.
+     */
+    bool _initializing;
+  }
+
+  // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
+  bytes32 private constant INITIALIZABLE_STORAGE =
+    0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;
+
+  /**
+   * @dev The contract is already initialized.
+   */
+  error InvalidInitialization();
+
+  /**
+   * @dev The contract is not initializing.
+   */
+  error NotInitializing();
+
+  /**
+   * @dev Triggered when the contract has been initialized or reinitialized.
+   */
+  event Initialized(uint64 version);
+
+  /**
+   * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
+   * `onlyInitializing` functions can be used to initialize parent contracts.
+   *
+   * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
+   * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
+   * production.
+   *
+   * Emits an {Initialized} event.
+   */
+  modifier initializer() {
+    // solhint-disable-next-line var-name-mixedcase
+    InitializableStorage storage $ = _getInitializableStorage();
+
+    // Cache values to avoid duplicated sloads
+    bool isTopLevelCall = !$._initializing;
+    uint64 initialized = $._initialized;
+
+    // Allowed calls:
+    // - initialSetup: the contract is not in the initializing state and no previous version was
+    //                 initialized
+    // - construction: the contract is initialized at version 1 (no reininitialization) and the
+    //                 current contract is just being deployed
+    bool initialSetup = initialized == 0 && isTopLevelCall;
+    bool construction = initialized == 1 && address(this).code.length == 0;
+
+    if (!initialSetup && !construction) {
+      revert InvalidInitialization();
+    }
+    $._initialized = 1;
+    if (isTopLevelCall) {
+      $._initializing = true;
+    }
+    _;
+    if (isTopLevelCall) {
+      $._initializing = false;
+      emit Initialized(1);
+    }
+  }
+
+  /**
+   * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
+   * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
+   * used to initialize parent contracts.
+   *
+   * A reinitializer may be used after the original initialization step. This is essential to configure modules that
+   * are added through upgrades and that require initialization.
+   *
+   * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
+   * cannot be nested. If one is invoked in the context of another, execution will revert.
+   *
+   * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
+   * a contract, executing them in the right order is up to the developer or operator.
+   *
+   * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
+   *
+   * Emits an {Initialized} event.
+   */
+  modifier reinitializer(uint64 version) {
+    // solhint-disable-next-line var-name-mixedcase
+    InitializableStorage storage $ = _getInitializableStorage();
+
+    if ($._initializing || $._initialized >= version) {
+      revert InvalidInitialization();
+    }
+    $._initialized = version;
+    $._initializing = true;
+    _;
+    $._initializing = false;
+    emit Initialized(version);
+  }
+
+  /**
+   * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
+   * {initializer} and {reinitializer} modifiers, directly or indirectly.
+   */
+  modifier onlyInitializing() {
+    _checkInitializing();
+    _;
+  }
+
+  /**
+   * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
+   */
+  function _checkInitializing() internal view virtual {
+    if (!_isInitializing()) {
+      revert NotInitializing();
+    }
+  }
+
+  /**
+   * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
+   * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
+   * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
+   * through proxies.
+   *
+   * Emits an {Initialized} event the first time it is successfully executed.
+   */
+  function _disableInitializers() internal virtual {
+    // solhint-disable-next-line var-name-mixedcase
+    InitializableStorage storage $ = _getInitializableStorage();
+
+    if ($._initializing) {
+      revert InvalidInitialization();
+    }
+    if ($._initialized != type(uint64).max) {
+      $._initialized = type(uint64).max;
+      emit Initialized(type(uint64).max);
+    }
+  }
+
+  /**
+   * @dev Returns the highest version that has been initialized. See {reinitializer}.
+   */
+  function _getInitializedVersion() internal view returns (uint64) {
+    return _getInitializableStorage()._initialized;
+  }
+
+  /**
+   * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
+   */
+  function _isInitializing() internal view returns (bool) {
+    return _getInitializableStorage()._initializing;
+  }
+
+  /**
+   * @dev Returns a pointer to the storage namespace.
+   */
+  // solhint-disable-next-line var-name-mixedcase
+  function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
+    assembly {
+      $.slot := INITIALIZABLE_STORAGE
+    }
+  }
+}
+
+// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)
+
+// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)
 
 /**
  * @dev Interface of the ERC20 standard as defined in the EIP.
@@ -22,23 +251,23 @@ interface IERC20 {
   event Approval(address indexed owner, address indexed spender, uint256 value);
 
   /**
-   * @dev Returns the amount of tokens in existence.
+   * @dev Returns the value of tokens in existence.
    */
   function totalSupply() external view returns (uint256);
 
   /**
-   * @dev Returns the amount of tokens owned by `account`.
+   * @dev Returns the value of tokens owned by `account`.
    */
   function balanceOf(address account) external view returns (uint256);
 
   /**
-   * @dev Moves `amount` tokens from the caller's account to `to`.
+   * @dev Moves a `value` amount of tokens from the caller's account to `to`.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
    */
-  function transfer(address to, uint256 amount) external returns (bool);
+  function transfer(address to, uint256 value) external returns (bool);
 
   /**
    * @dev Returns the remaining number of tokens that `spender` will be
@@ -50,7 +279,8 @@ interface IERC20 {
   function allowance(address owner, address spender) external view returns (uint256);
 
   /**
-   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
+   * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
+   * caller's tokens.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
@@ -63,26 +293,1551 @@ interface IERC20 {
    *
    * Emits an {Approval} event.
    */
-  function approve(address spender, uint256 amount) external returns (bool);
+  function approve(address spender, uint256 value) external returns (bool);
 
   /**
-   * @dev Moves `amount` tokens from `from` to `to` using the
-   * allowance mechanism. `amount` is then deducted from the caller's
+   * @dev Moves a `value` amount of tokens from `from` to `to` using the
+   * allowance mechanism. `value` is then deducted from the caller's
    * allowance.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
    */
-  function transferFrom(address from, address to, uint256 amount) external returns (bool);
+  function transferFrom(address from, address to, uint256 value) external returns (bool);
 }
 
-// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)
+// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)
+
+/**
+ * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
+ * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
+ *
+ * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
+ * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
+ * need to send a transaction, and thus is not required to hold Ether at all.
+ *
+ * ==== Security Considerations
+ *
+ * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
+ * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
+ * considered as an intention to spend the allowance in any specific way. The second is that because permits have
+ * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
+ * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
+ * generally recommended is:
+ *
+ * ```solidity
+ * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
+ *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
+ *     doThing(..., value);
+ * }
+ *
+ * function doThing(..., uint256 value) public {
+ *     token.safeTransferFrom(msg.sender, address(this), value);
+ *     ...
+ * }
+ * ```
+ *
+ * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
+ * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
+ * {SafeERC20-safeTransferFrom}).
+ *
+ * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
+ * contracts should have entry points that don't rely on permit.
+ */
+interface IERC20Permit {
+  /**
+   * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
+   * given ``owner``'s signed approval.
+   *
+   * IMPORTANT: The same issues {IERC20-approve} has related to transaction
+   * ordering also apply here.
+   *
+   * Emits an {Approval} event.
+   *
+   * Requirements:
+   *
+   * - `spender` cannot be the zero address.
+   * - `deadline` must be a timestamp in the future.
+   * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
+   * over the EIP712-formatted function arguments.
+   * - the signature must use ``owner``'s current nonce (see {nonces}).
+   *
+   * For more information on the signature format, see the
+   * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
+   * section].
+   *
+   * CAUTION: See Security Considerations above.
+   */
+  function permit(
+    address owner,
+    address spender,
+    uint256 value,
+    uint256 deadline,
+    uint8 v,
+    bytes32 r,
+    bytes32 s
+  ) external;
+
+  /**
+   * @dev Returns the current nonce for `owner`. This value must be
+   * included whenever a signature is generated for {permit}.
+   *
+   * Every successful call to {permit} increases ``owner``'s nonce by one. This
+   * prevents a signature from being used multiple times.
+   */
+  function nonces(address owner) external view returns (uint256);
+
+  /**
+   * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
+   */
+  // solhint-disable-next-line func-name-mixedcase
+  function DOMAIN_SEPARATOR() external view returns (bytes32);
+}
+
+// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)
+
+/**
+ * @dev Collection of functions related to the address type
+ */
+library Address {
+  /**
+   * @dev The ETH balance of the account is not enough to perform the operation.
+   */
+  error AddressInsufficientBalance(address account);
+
+  /**
+   * @dev There's no code at `target` (it is not a contract).
+   */
+  error AddressEmptyCode(address target);
+
+  /**
+   * @dev A call to an address target failed. The target may have reverted.
+   */
+  error FailedInnerCall();
+
+  /**
+   * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
+   * `recipient`, forwarding all available gas and reverting on errors.
+   *
+   * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
+   * of certain opcodes, possibly making contracts go over the 2300 gas limit
+   * imposed by `transfer`, making them unable to receive funds via
+   * `transfer`. {sendValue} removes this limitation.
+   *
+   * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
+   *
+   * IMPORTANT: because control is transferred to `recipient`, care must be
+   * taken to not create reentrancy vulnerabilities. Consider using
+   * {ReentrancyGuard} or the
+   * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
+   */
+  function sendValue(address payable recipient, uint256 amount) internal {
+    if (address(this).balance < amount) {
+      revert AddressInsufficientBalance(address(this));
+    }
+
+    (bool success, ) = recipient.call{value: amount}('');
+    if (!success) {
+      revert FailedInnerCall();
+    }
+  }
+
+  /**
+   * @dev Performs a Solidity function call using a low level `call`. A
+   * plain `call` is an unsafe replacement for a function call: use this
+   * function instead.
+   *
+   * If `target` reverts with a revert reason or custom error, it is bubbled
+   * up by this function (like regular Solidity function calls). However, if
+   * the call reverted with no returned reason, this function reverts with a
+   * {FailedInnerCall} error.
+   *
+   * Returns the raw returned data. To convert to the expected return value,
+   * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
+   *
+   * Requirements:
+   *
+   * - `target` must be a contract.
+   * - calling `target` with `data` must not revert.
+   */
+  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
+    return functionCallWithValue(target, data, 0);
+  }
+
+  /**
+   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
+   * but also transferring `value` wei to `target`.
+   *
+   * Requirements:
+   *
+   * - the calling contract must have an ETH balance of at least `value`.
+   * - the called Solidity function must be `payable`.
+   */
+  function functionCallWithValue(
+    address target,
+    bytes memory data,
+    uint256 value
+  ) internal returns (bytes memory) {
+    if (address(this).balance < value) {
+      revert AddressInsufficientBalance(address(this));
+    }
+    (bool success, bytes memory returndata) = target.call{value: value}(data);
+    return verifyCallResultFromTarget(target, success, returndata);
+  }
+
+  /**
+   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
+   * but performing a static call.
+   */
+  function functionStaticCall(
+    address target,
+    bytes memory data
+  ) internal view returns (bytes memory) {
+    (bool success, bytes memory returndata) = target.staticcall(data);
+    return verifyCallResultFromTarget(target, success, returndata);
+  }
+
+  /**
+   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
+   * but performing a delegate call.
+   */
+  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
+    (bool success, bytes memory returndata) = target.delegatecall(data);
+    return verifyCallResultFromTarget(target, success, returndata);
+  }
+
+  /**
+   * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
+   * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
+   * unsuccessful call.
+   */
+  function verifyCallResultFromTarget(
+    address target,
+    bool success,
+    bytes memory returndata
+  ) internal view returns (bytes memory) {
+    if (!success) {
+      _revert(returndata);
+    } else {
+      // only check if target is a contract if the call was successful and the return data is empty
+      // otherwise we already know that it was a contract
+      if (returndata.length == 0 && target.code.length == 0) {
+        revert AddressEmptyCode(target);
+      }
+      return returndata;
+    }
+  }
+
+  /**
+   * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
+   * revert reason or with a default {FailedInnerCall} error.
+   */
+  function verifyCallResult(
+    bool success,
+    bytes memory returndata
+  ) internal pure returns (bytes memory) {
+    if (!success) {
+      _revert(returndata);
+    } else {
+      return returndata;
+    }
+  }
+
+  /**
+   * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
+   */
+  function _revert(bytes memory returndata) private pure {
+    // Look for revert reason and bubble it up if present
+    if (returndata.length > 0) {
+      // The easiest way to bubble the revert reason is using memory via assembly
+      /// @solidity memory-safe-assembly
+      assembly {
+        let returndata_size := mload(returndata)
+        revert(add(32, returndata), returndata_size)
+      }
+    } else {
+      revert FailedInnerCall();
+    }
+  }
+}
+
+/**
+ * @title SafeERC20
+ * @dev Wrappers around ERC20 operations that throw on failure (when the token
+ * contract returns false). Tokens that return no value (and instead revert or
+ * throw on failure) are also supported, non-reverting calls are assumed to be
+ * successful.
+ * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
+ * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
+ */
+library SafeERC20 {
+  using Address for address;
+
+  /**
+   * @dev An operation with an ERC20 token failed.
+   */
+  error SafeERC20FailedOperation(address token);
+
+  /**
+   * @dev Indicates a failed `decreaseAllowance` request.
+   */
+  error SafeERC20FailedDecreaseAllowance(
+    address spender,
+    uint256 currentAllowance,
+    uint256 requestedDecrease
+  );
+
+  /**
+   * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
+   * non-reverting calls are assumed to be successful.
+   */
+  function safeTransfer(IERC20 token, address to, uint256 value) internal {
+    _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
+  }
+
+  /**
+   * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
+   * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
+   */
+  function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
+    _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
+  }
+
+  /**
+   * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
+   * non-reverting calls are assumed to be successful.
+   */
+  function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
+    uint256 oldAllowance = token.allowance(address(this), spender);
+    forceApprove(token, spender, oldAllowance + value);
+  }
+
+  /**
+   * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
+   * value, non-reverting calls are assumed to be successful.
+   */
+  function safeDecreaseAllowance(
+    IERC20 token,
+    address spender,
+    uint256 requestedDecrease
+  ) internal {
+    unchecked {
+      uint256 currentAllowance = token.allowance(address(this), spender);
+      if (currentAllowance < requestedDecrease) {
+        revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
+      }
+      forceApprove(token, spender, currentAllowance - requestedDecrease);
+    }
+  }
+
+  /**
+   * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
+   * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
+   * to be set to zero before setting it to a non-zero value, such as USDT.
+   */
+  function forceApprove(IERC20 token, address spender, uint256 value) internal {
+    bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));
+
+    if (!_callOptionalReturnBool(token, approvalCall)) {
+      _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
+      _callOptionalReturn(token, approvalCall);
+    }
+  }
+
+  /**
+   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
+   * on the return value: the return value is optional (but if data is returned, it must not be false).
+   * @param token The token targeted by the call.
+   * @param data The call data (encoded using abi.encode or one of its variants).
+   */
+  function _callOptionalReturn(IERC20 token, bytes memory data) private {
+    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
+    // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
+    // the target address contains contract code and also asserts for success in the low-level call.
+
+    bytes memory returndata = address(token).functionCall(data);
+    if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
+      revert SafeERC20FailedOperation(address(token));
+    }
+  }
+
+  /**
+   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
+   * on the return value: the return value is optional (but if data is returned, it must not be false).
+   * @param token The token targeted by the call.
+   * @param data The call data (encoded using abi.encode or one of its variants).
+   *
+   * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
+   */
+  function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
+    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
+    // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
+    // and not revert is the subcall reverts.
+
+    (bool success, bytes memory returndata) = address(token).call(data);
+    return
+      success &&
+      (returndata.length == 0 || abi.decode(returndata, (bool))) &&
+      address(token).code.length > 0;
+  }
+}
+
+// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SafeCast.sol)
+// This file was procedurally generated from scripts/generate/templates/SafeCast.js.
+
+/**
+ * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
+ * checks.
+ *
+ * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
+ * easily result in undesired exploitation or bugs, since developers usually
+ * assume that overflows raise errors. `SafeCast` restores this intuition by
+ * reverting the transaction when such an operation overflows.
+ *
+ * Using this library instead of the unchecked operations eliminates an entire
+ * class of bugs, so it's recommended to use it always.
+ */
+library SafeCast {
+  /**
+   * @dev Value doesn't fit in an uint of `bits` size.
+   */
+  error SafeCastOverflowedUintDowncast(uint8 bits, uint256 value);
+
+  /**
+   * @dev An int value doesn't fit in an uint of `bits` size.
+   */
+  error SafeCastOverflowedIntToUint(int256 value);
+
+  /**
+   * @dev Value doesn't fit in an int of `bits` size.
+   */
+  error SafeCastOverflowedIntDowncast(uint8 bits, int256 value);
+
+  /**
+   * @dev An uint value doesn't fit in an int of `bits` size.
+   */
+  error SafeCastOverflowedUintToInt(uint256 value);
+
+  /**
+   * @dev Returns the downcasted uint248 from uint256, reverting on
+   * overflow (when the input is greater than largest uint248).
+   *
+   * Counterpart to Solidity's `uint248` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 248 bits
+   */
+  function toUint248(uint256 value) internal pure returns (uint248) {
+    if (value > type(uint248).max) {
+      revert SafeCastOverflowedUintDowncast(248, value);
+    }
+    return uint248(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint240 from uint256, reverting on
+   * overflow (when the input is greater than largest uint240).
+   *
+   * Counterpart to Solidity's `uint240` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 240 bits
+   */
+  function toUint240(uint256 value) internal pure returns (uint240) {
+    if (value > type(uint240).max) {
+      revert SafeCastOverflowedUintDowncast(240, value);
+    }
+    return uint240(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint232 from uint256, reverting on
+   * overflow (when the input is greater than largest uint232).
+   *
+   * Counterpart to Solidity's `uint232` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 232 bits
+   */
+  function toUint232(uint256 value) internal pure returns (uint232) {
+    if (value > type(uint232).max) {
+      revert SafeCastOverflowedUintDowncast(232, value);
+    }
+    return uint232(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint224 from uint256, reverting on
+   * overflow (when the input is greater than largest uint224).
+   *
+   * Counterpart to Solidity's `uint224` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 224 bits
+   */
+  function toUint224(uint256 value) internal pure returns (uint224) {
+    if (value > type(uint224).max) {
+      revert SafeCastOverflowedUintDowncast(224, value);
+    }
+    return uint224(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint216 from uint256, reverting on
+   * overflow (when the input is greater than largest uint216).
+   *
+   * Counterpart to Solidity's `uint216` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 216 bits
+   */
+  function toUint216(uint256 value) internal pure returns (uint216) {
+    if (value > type(uint216).max) {
+      revert SafeCastOverflowedUintDowncast(216, value);
+    }
+    return uint216(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint208 from uint256, reverting on
+   * overflow (when the input is greater than largest uint208).
+   *
+   * Counterpart to Solidity's `uint208` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 208 bits
+   */
+  function toUint208(uint256 value) internal pure returns (uint208) {
+    if (value > type(uint208).max) {
+      revert SafeCastOverflowedUintDowncast(208, value);
+    }
+    return uint208(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint200 from uint256, reverting on
+   * overflow (when the input is greater than largest uint200).
+   *
+   * Counterpart to Solidity's `uint200` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 200 bits
+   */
+  function toUint200(uint256 value) internal pure returns (uint200) {
+    if (value > type(uint200).max) {
+      revert SafeCastOverflowedUintDowncast(200, value);
+    }
+    return uint200(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint192 from uint256, reverting on
+   * overflow (when the input is greater than largest uint192).
+   *
+   * Counterpart to Solidity's `uint192` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 192 bits
+   */
+  function toUint192(uint256 value) internal pure returns (uint192) {
+    if (value > type(uint192).max) {
+      revert SafeCastOverflowedUintDowncast(192, value);
+    }
+    return uint192(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint184 from uint256, reverting on
+   * overflow (when the input is greater than largest uint184).
+   *
+   * Counterpart to Solidity's `uint184` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 184 bits
+   */
+  function toUint184(uint256 value) internal pure returns (uint184) {
+    if (value > type(uint184).max) {
+      revert SafeCastOverflowedUintDowncast(184, value);
+    }
+    return uint184(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint176 from uint256, reverting on
+   * overflow (when the input is greater than largest uint176).
+   *
+   * Counterpart to Solidity's `uint176` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 176 bits
+   */
+  function toUint176(uint256 value) internal pure returns (uint176) {
+    if (value > type(uint176).max) {
+      revert SafeCastOverflowedUintDowncast(176, value);
+    }
+    return uint176(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint168 from uint256, reverting on
+   * overflow (when the input is greater than largest uint168).
+   *
+   * Counterpart to Solidity's `uint168` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 168 bits
+   */
+  function toUint168(uint256 value) internal pure returns (uint168) {
+    if (value > type(uint168).max) {
+      revert SafeCastOverflowedUintDowncast(168, value);
+    }
+    return uint168(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint160 from uint256, reverting on
+   * overflow (when the input is greater than largest uint160).
+   *
+   * Counterpart to Solidity's `uint160` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 160 bits
+   */
+  function toUint160(uint256 value) internal pure returns (uint160) {
+    if (value > type(uint160).max) {
+      revert SafeCastOverflowedUintDowncast(160, value);
+    }
+    return uint160(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint152 from uint256, reverting on
+   * overflow (when the input is greater than largest uint152).
+   *
+   * Counterpart to Solidity's `uint152` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 152 bits
+   */
+  function toUint152(uint256 value) internal pure returns (uint152) {
+    if (value > type(uint152).max) {
+      revert SafeCastOverflowedUintDowncast(152, value);
+    }
+    return uint152(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint144 from uint256, reverting on
+   * overflow (when the input is greater than largest uint144).
+   *
+   * Counterpart to Solidity's `uint144` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 144 bits
+   */
+  function toUint144(uint256 value) internal pure returns (uint144) {
+    if (value > type(uint144).max) {
+      revert SafeCastOverflowedUintDowncast(144, value);
+    }
+    return uint144(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint136 from uint256, reverting on
+   * overflow (when the input is greater than largest uint136).
+   *
+   * Counterpart to Solidity's `uint136` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 136 bits
+   */
+  function toUint136(uint256 value) internal pure returns (uint136) {
+    if (value > type(uint136).max) {
+      revert SafeCastOverflowedUintDowncast(136, value);
+    }
+    return uint136(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint128 from uint256, reverting on
+   * overflow (when the input is greater than largest uint128).
+   *
+   * Counterpart to Solidity's `uint128` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 128 bits
+   */
+  function toUint128(uint256 value) internal pure returns (uint128) {
+    if (value > type(uint128).max) {
+      revert SafeCastOverflowedUintDowncast(128, value);
+    }
+    return uint128(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint120 from uint256, reverting on
+   * overflow (when the input is greater than largest uint120).
+   *
+   * Counterpart to Solidity's `uint120` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 120 bits
+   */
+  function toUint120(uint256 value) internal pure returns (uint120) {
+    if (value > type(uint120).max) {
+      revert SafeCastOverflowedUintDowncast(120, value);
+    }
+    return uint120(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint112 from uint256, reverting on
+   * overflow (when the input is greater than largest uint112).
+   *
+   * Counterpart to Solidity's `uint112` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 112 bits
+   */
+  function toUint112(uint256 value) internal pure returns (uint112) {
+    if (value > type(uint112).max) {
+      revert SafeCastOverflowedUintDowncast(112, value);
+    }
+    return uint112(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint104 from uint256, reverting on
+   * overflow (when the input is greater than largest uint104).
+   *
+   * Counterpart to Solidity's `uint104` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 104 bits
+   */
+  function toUint104(uint256 value) internal pure returns (uint104) {
+    if (value > type(uint104).max) {
+      revert SafeCastOverflowedUintDowncast(104, value);
+    }
+    return uint104(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint96 from uint256, reverting on
+   * overflow (when the input is greater than largest uint96).
+   *
+   * Counterpart to Solidity's `uint96` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 96 bits
+   */
+  function toUint96(uint256 value) internal pure returns (uint96) {
+    if (value > type(uint96).max) {
+      revert SafeCastOverflowedUintDowncast(96, value);
+    }
+    return uint96(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint88 from uint256, reverting on
+   * overflow (when the input is greater than largest uint88).
+   *
+   * Counterpart to Solidity's `uint88` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 88 bits
+   */
+  function toUint88(uint256 value) internal pure returns (uint88) {
+    if (value > type(uint88).max) {
+      revert SafeCastOverflowedUintDowncast(88, value);
+    }
+    return uint88(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint80 from uint256, reverting on
+   * overflow (when the input is greater than largest uint80).
+   *
+   * Counterpart to Solidity's `uint80` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 80 bits
+   */
+  function toUint80(uint256 value) internal pure returns (uint80) {
+    if (value > type(uint80).max) {
+      revert SafeCastOverflowedUintDowncast(80, value);
+    }
+    return uint80(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint72 from uint256, reverting on
+   * overflow (when the input is greater than largest uint72).
+   *
+   * Counterpart to Solidity's `uint72` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 72 bits
+   */
+  function toUint72(uint256 value) internal pure returns (uint72) {
+    if (value > type(uint72).max) {
+      revert SafeCastOverflowedUintDowncast(72, value);
+    }
+    return uint72(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint64 from uint256, reverting on
+   * overflow (when the input is greater than largest uint64).
+   *
+   * Counterpart to Solidity's `uint64` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 64 bits
+   */
+  function toUint64(uint256 value) internal pure returns (uint64) {
+    if (value > type(uint64).max) {
+      revert SafeCastOverflowedUintDowncast(64, value);
+    }
+    return uint64(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint56 from uint256, reverting on
+   * overflow (when the input is greater than largest uint56).
+   *
+   * Counterpart to Solidity's `uint56` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 56 bits
+   */
+  function toUint56(uint256 value) internal pure returns (uint56) {
+    if (value > type(uint56).max) {
+      revert SafeCastOverflowedUintDowncast(56, value);
+    }
+    return uint56(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint48 from uint256, reverting on
+   * overflow (when the input is greater than largest uint48).
+   *
+   * Counterpart to Solidity's `uint48` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 48 bits
+   */
+  function toUint48(uint256 value) internal pure returns (uint48) {
+    if (value > type(uint48).max) {
+      revert SafeCastOverflowedUintDowncast(48, value);
+    }
+    return uint48(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint40 from uint256, reverting on
+   * overflow (when the input is greater than largest uint40).
+   *
+   * Counterpart to Solidity's `uint40` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 40 bits
+   */
+  function toUint40(uint256 value) internal pure returns (uint40) {
+    if (value > type(uint40).max) {
+      revert SafeCastOverflowedUintDowncast(40, value);
+    }
+    return uint40(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint32 from uint256, reverting on
+   * overflow (when the input is greater than largest uint32).
+   *
+   * Counterpart to Solidity's `uint32` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 32 bits
+   */
+  function toUint32(uint256 value) internal pure returns (uint32) {
+    if (value > type(uint32).max) {
+      revert SafeCastOverflowedUintDowncast(32, value);
+    }
+    return uint32(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint24 from uint256, reverting on
+   * overflow (when the input is greater than largest uint24).
+   *
+   * Counterpart to Solidity's `uint24` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 24 bits
+   */
+  function toUint24(uint256 value) internal pure returns (uint24) {
+    if (value > type(uint24).max) {
+      revert SafeCastOverflowedUintDowncast(24, value);
+    }
+    return uint24(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint16 from uint256, reverting on
+   * overflow (when the input is greater than largest uint16).
+   *
+   * Counterpart to Solidity's `uint16` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 16 bits
+   */
+  function toUint16(uint256 value) internal pure returns (uint16) {
+    if (value > type(uint16).max) {
+      revert SafeCastOverflowedUintDowncast(16, value);
+    }
+    return uint16(value);
+  }
+
+  /**
+   * @dev Returns the downcasted uint8 from uint256, reverting on
+   * overflow (when the input is greater than largest uint8).
+   *
+   * Counterpart to Solidity's `uint8` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 8 bits
+   */
+  function toUint8(uint256 value) internal pure returns (uint8) {
+    if (value > type(uint8).max) {
+      revert SafeCastOverflowedUintDowncast(8, value);
+    }
+    return uint8(value);
+  }
+
+  /**
+   * @dev Converts a signed int256 into an unsigned uint256.
+   *
+   * Requirements:
+   *
+   * - input must be greater than or equal to 0.
+   */
+  function toUint256(int256 value) internal pure returns (uint256) {
+    if (value < 0) {
+      revert SafeCastOverflowedIntToUint(value);
+    }
+    return uint256(value);
+  }
+
+  /**
+   * @dev Returns the downcasted int248 from int256, reverting on
+   * overflow (when the input is less than smallest int248 or
+   * greater than largest int248).
+   *
+   * Counterpart to Solidity's `int248` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 248 bits
+   */
+  function toInt248(int256 value) internal pure returns (int248 downcasted) {
+    downcasted = int248(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(248, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int240 from int256, reverting on
+   * overflow (when the input is less than smallest int240 or
+   * greater than largest int240).
+   *
+   * Counterpart to Solidity's `int240` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 240 bits
+   */
+  function toInt240(int256 value) internal pure returns (int240 downcasted) {
+    downcasted = int240(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(240, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int232 from int256, reverting on
+   * overflow (when the input is less than smallest int232 or
+   * greater than largest int232).
+   *
+   * Counterpart to Solidity's `int232` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 232 bits
+   */
+  function toInt232(int256 value) internal pure returns (int232 downcasted) {
+    downcasted = int232(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(232, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int224 from int256, reverting on
+   * overflow (when the input is less than smallest int224 or
+   * greater than largest int224).
+   *
+   * Counterpart to Solidity's `int224` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 224 bits
+   */
+  function toInt224(int256 value) internal pure returns (int224 downcasted) {
+    downcasted = int224(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(224, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int216 from int256, reverting on
+   * overflow (when the input is less than smallest int216 or
+   * greater than largest int216).
+   *
+   * Counterpart to Solidity's `int216` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 216 bits
+   */
+  function toInt216(int256 value) internal pure returns (int216 downcasted) {
+    downcasted = int216(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(216, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int208 from int256, reverting on
+   * overflow (when the input is less than smallest int208 or
+   * greater than largest int208).
+   *
+   * Counterpart to Solidity's `int208` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 208 bits
+   */
+  function toInt208(int256 value) internal pure returns (int208 downcasted) {
+    downcasted = int208(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(208, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int200 from int256, reverting on
+   * overflow (when the input is less than smallest int200 or
+   * greater than largest int200).
+   *
+   * Counterpart to Solidity's `int200` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 200 bits
+   */
+  function toInt200(int256 value) internal pure returns (int200 downcasted) {
+    downcasted = int200(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(200, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int192 from int256, reverting on
+   * overflow (when the input is less than smallest int192 or
+   * greater than largest int192).
+   *
+   * Counterpart to Solidity's `int192` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 192 bits
+   */
+  function toInt192(int256 value) internal pure returns (int192 downcasted) {
+    downcasted = int192(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(192, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int184 from int256, reverting on
+   * overflow (when the input is less than smallest int184 or
+   * greater than largest int184).
+   *
+   * Counterpart to Solidity's `int184` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 184 bits
+   */
+  function toInt184(int256 value) internal pure returns (int184 downcasted) {
+    downcasted = int184(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(184, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int176 from int256, reverting on
+   * overflow (when the input is less than smallest int176 or
+   * greater than largest int176).
+   *
+   * Counterpart to Solidity's `int176` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 176 bits
+   */
+  function toInt176(int256 value) internal pure returns (int176 downcasted) {
+    downcasted = int176(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(176, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int168 from int256, reverting on
+   * overflow (when the input is less than smallest int168 or
+   * greater than largest int168).
+   *
+   * Counterpart to Solidity's `int168` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 168 bits
+   */
+  function toInt168(int256 value) internal pure returns (int168 downcasted) {
+    downcasted = int168(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(168, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int160 from int256, reverting on
+   * overflow (when the input is less than smallest int160 or
+   * greater than largest int160).
+   *
+   * Counterpart to Solidity's `int160` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 160 bits
+   */
+  function toInt160(int256 value) internal pure returns (int160 downcasted) {
+    downcasted = int160(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(160, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int152 from int256, reverting on
+   * overflow (when the input is less than smallest int152 or
+   * greater than largest int152).
+   *
+   * Counterpart to Solidity's `int152` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 152 bits
+   */
+  function toInt152(int256 value) internal pure returns (int152 downcasted) {
+    downcasted = int152(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(152, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int144 from int256, reverting on
+   * overflow (when the input is less than smallest int144 or
+   * greater than largest int144).
+   *
+   * Counterpart to Solidity's `int144` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 144 bits
+   */
+  function toInt144(int256 value) internal pure returns (int144 downcasted) {
+    downcasted = int144(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(144, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int136 from int256, reverting on
+   * overflow (when the input is less than smallest int136 or
+   * greater than largest int136).
+   *
+   * Counterpart to Solidity's `int136` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 136 bits
+   */
+  function toInt136(int256 value) internal pure returns (int136 downcasted) {
+    downcasted = int136(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(136, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int128 from int256, reverting on
+   * overflow (when the input is less than smallest int128 or
+   * greater than largest int128).
+   *
+   * Counterpart to Solidity's `int128` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 128 bits
+   */
+  function toInt128(int256 value) internal pure returns (int128 downcasted) {
+    downcasted = int128(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(128, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int120 from int256, reverting on
+   * overflow (when the input is less than smallest int120 or
+   * greater than largest int120).
+   *
+   * Counterpart to Solidity's `int120` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 120 bits
+   */
+  function toInt120(int256 value) internal pure returns (int120 downcasted) {
+    downcasted = int120(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(120, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int112 from int256, reverting on
+   * overflow (when the input is less than smallest int112 or
+   * greater than largest int112).
+   *
+   * Counterpart to Solidity's `int112` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 112 bits
+   */
+  function toInt112(int256 value) internal pure returns (int112 downcasted) {
+    downcasted = int112(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(112, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int104 from int256, reverting on
+   * overflow (when the input is less than smallest int104 or
+   * greater than largest int104).
+   *
+   * Counterpart to Solidity's `int104` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 104 bits
+   */
+  function toInt104(int256 value) internal pure returns (int104 downcasted) {
+    downcasted = int104(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(104, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int96 from int256, reverting on
+   * overflow (when the input is less than smallest int96 or
+   * greater than largest int96).
+   *
+   * Counterpart to Solidity's `int96` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 96 bits
+   */
+  function toInt96(int256 value) internal pure returns (int96 downcasted) {
+    downcasted = int96(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(96, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int88 from int256, reverting on
+   * overflow (when the input is less than smallest int88 or
+   * greater than largest int88).
+   *
+   * Counterpart to Solidity's `int88` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 88 bits
+   */
+  function toInt88(int256 value) internal pure returns (int88 downcasted) {
+    downcasted = int88(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(88, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int80 from int256, reverting on
+   * overflow (when the input is less than smallest int80 or
+   * greater than largest int80).
+   *
+   * Counterpart to Solidity's `int80` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 80 bits
+   */
+  function toInt80(int256 value) internal pure returns (int80 downcasted) {
+    downcasted = int80(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(80, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int72 from int256, reverting on
+   * overflow (when the input is less than smallest int72 or
+   * greater than largest int72).
+   *
+   * Counterpart to Solidity's `int72` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 72 bits
+   */
+  function toInt72(int256 value) internal pure returns (int72 downcasted) {
+    downcasted = int72(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(72, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int64 from int256, reverting on
+   * overflow (when the input is less than smallest int64 or
+   * greater than largest int64).
+   *
+   * Counterpart to Solidity's `int64` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 64 bits
+   */
+  function toInt64(int256 value) internal pure returns (int64 downcasted) {
+    downcasted = int64(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(64, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int56 from int256, reverting on
+   * overflow (when the input is less than smallest int56 or
+   * greater than largest int56).
+   *
+   * Counterpart to Solidity's `int56` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 56 bits
+   */
+  function toInt56(int256 value) internal pure returns (int56 downcasted) {
+    downcasted = int56(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(56, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int48 from int256, reverting on
+   * overflow (when the input is less than smallest int48 or
+   * greater than largest int48).
+   *
+   * Counterpart to Solidity's `int48` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 48 bits
+   */
+  function toInt48(int256 value) internal pure returns (int48 downcasted) {
+    downcasted = int48(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(48, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int40 from int256, reverting on
+   * overflow (when the input is less than smallest int40 or
+   * greater than largest int40).
+   *
+   * Counterpart to Solidity's `int40` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 40 bits
+   */
+  function toInt40(int256 value) internal pure returns (int40 downcasted) {
+    downcasted = int40(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(40, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int32 from int256, reverting on
+   * overflow (when the input is less than smallest int32 or
+   * greater than largest int32).
+   *
+   * Counterpart to Solidity's `int32` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 32 bits
+   */
+  function toInt32(int256 value) internal pure returns (int32 downcasted) {
+    downcasted = int32(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(32, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int24 from int256, reverting on
+   * overflow (when the input is less than smallest int24 or
+   * greater than largest int24).
+   *
+   * Counterpart to Solidity's `int24` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 24 bits
+   */
+  function toInt24(int256 value) internal pure returns (int24 downcasted) {
+    downcasted = int24(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(24, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int16 from int256, reverting on
+   * overflow (when the input is less than smallest int16 or
+   * greater than largest int16).
+   *
+   * Counterpart to Solidity's `int16` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 16 bits
+   */
+  function toInt16(int256 value) internal pure returns (int16 downcasted) {
+    downcasted = int16(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(16, value);
+    }
+  }
+
+  /**
+   * @dev Returns the downcasted int8 from int256, reverting on
+   * overflow (when the input is less than smallest int8 or
+   * greater than largest int8).
+   *
+   * Counterpart to Solidity's `int8` operator.
+   *
+   * Requirements:
+   *
+   * - input must fit into 8 bits
+   */
+  function toInt8(int256 value) internal pure returns (int8 downcasted) {
+    downcasted = int8(value);
+    if (downcasted != value) {
+      revert SafeCastOverflowedIntDowncast(8, value);
+    }
+  }
+
+  /**
+   * @dev Converts an unsigned uint256 into a signed int256.
+   *
+   * Requirements:
+   *
+   * - input must be less than or equal to maxInt256.
+   */
+  function toInt256(uint256 value) internal pure returns (int256) {
+    // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
+    if (value > uint256(type(int256).max)) {
+      revert SafeCastOverflowedUintToInt(value);
+    }
+    return int256(value);
+  }
+}
+
+// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)
 
 /**
  * @dev Interface for the optional metadata functions from the ERC20 standard.
- *
- * _Available since v4.1._
  */
 interface IERC20Metadata is IERC20 {
   /**
@@ -101,11 +1856,195 @@ interface IERC20Metadata is IERC20 {
   function decimals() external view returns (uint8);
 }
 
-// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)
+// Modified version of OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/ERC20Permit.sol)
+// @dev using locally modified version of ERC20 token
 
-// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)
+// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/ECDSA.sol)
 
-// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)
+/**
+ * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
+ *
+ * These functions can be used to verify that a message was signed by the holder
+ * of the private keys of a given address.
+ */
+library ECDSA {
+  enum RecoverError {
+    NoError,
+    InvalidSignature,
+    InvalidSignatureLength,
+    InvalidSignatureS
+  }
+
+  /**
+   * @dev The signature derives the `address(0)`.
+   */
+  error ECDSAInvalidSignature();
+
+  /**
+   * @dev The signature has an invalid length.
+   */
+  error ECDSAInvalidSignatureLength(uint256 length);
+
+  /**
+   * @dev The signature has an S value that is in the upper half order.
+   */
+  error ECDSAInvalidSignatureS(bytes32 s);
+
+  /**
+   * @dev Returns the address that signed a hashed message (`hash`) with `signature` or an error. This will not
+   * return address(0) without also returning an error description. Errors are documented using an enum (error type)
+   * and a bytes32 providing additional information about the error.
+   *
+   * If no error is returned, then the address can be used for verification purposes.
+   *
+   * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
+   * this function rejects them by requiring the `s` value to be in the lower
+   * half order, and the `v` value to be either 27 or 28.
+   *
+   * IMPORTANT: `hash` _must_ be the result of a hash operation for the
+   * verification to be secure: it is possible to craft signatures that
+   * recover to arbitrary addresses for non-hashed data. A safe way to ensure
+   * this is by receiving a hash of the original message (which may otherwise
+   * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
+   *
+   * Documentation for signature generation:
+   * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
+   * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
+   */
+  function tryRecover(
+    bytes32 hash,
+    bytes memory signature
+  ) internal pure returns (address, RecoverError, bytes32) {
+    if (signature.length == 65) {
+      bytes32 r;
+      bytes32 s;
+      uint8 v;
+      // ecrecover takes the signature parameters, and the only way to get them
+      // currently is to use assembly.
+      /// @solidity memory-safe-assembly
+      assembly {
+        r := mload(add(signature, 0x20))
+        s := mload(add(signature, 0x40))
+        v := byte(0, mload(add(signature, 0x60)))
+      }
+      return tryRecover(hash, v, r, s);
+    } else {
+      return (address(0), RecoverError.InvalidSignatureLength, bytes32(signature.length));
+    }
+  }
+
+  /**
+   * @dev Returns the address that signed a hashed message (`hash`) with
+   * `signature`. This address can then be used for verification purposes.
+   *
+   * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
+   * this function rejects them by requiring the `s` value to be in the lower
+   * half order, and the `v` value to be either 27 or 28.
+   *
+   * IMPORTANT: `hash` _must_ be the result of a hash operation for the
+   * verification to be secure: it is possible to craft signatures that
+   * recover to arbitrary addresses for non-hashed data. A safe way to ensure
+   * this is by receiving a hash of the original message (which may otherwise
+   * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
+   */
+  function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
+    (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, signature);
+    _throwError(error, errorArg);
+    return recovered;
+  }
+
+  /**
+   * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
+   *
+   * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
+   */
+  function tryRecover(
+    bytes32 hash,
+    bytes32 r,
+    bytes32 vs
+  ) internal pure returns (address, RecoverError, bytes32) {
+    unchecked {
+      bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
+      // We do not check for an overflow here since the shift operation results in 0 or 1.
+      uint8 v = uint8((uint256(vs) >> 255) + 27);
+      return tryRecover(hash, v, r, s);
+    }
+  }
+
+  /**
+   * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
+   */
+  function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
+    (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, r, vs);
+    _throwError(error, errorArg);
+    return recovered;
+  }
+
+  /**
+   * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
+   * `r` and `s` signature fields separately.
+   */
+  function tryRecover(
+    bytes32 hash,
+    uint8 v,
+    bytes32 r,
+    bytes32 s
+  ) internal pure returns (address, RecoverError, bytes32) {
+    // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
+    // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
+    // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
+    // signatures from current libraries generate a unique signature with an s-value in the lower half order.
+    //
+    // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
+    // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
+    // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
+    // these malleable signatures as well.
+    if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
+      return (address(0), RecoverError.InvalidSignatureS, s);
+    }
+
+    // If the signature is valid (and not malleable), return the signer address
+    address signer = ecrecover(hash, v, r, s);
+    if (signer == address(0)) {
+      return (address(0), RecoverError.InvalidSignature, bytes32(0));
+    }
+
+    return (signer, RecoverError.NoError, bytes32(0));
+  }
+
+  /**
+   * @dev Overload of {ECDSA-recover} that receives the `v`,
+   * `r` and `s` signature fields separately.
+   */
+  function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
+    (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, v, r, s);
+    _throwError(error, errorArg);
+    return recovered;
+  }
+
+  /**
+   * @dev Optionally reverts with the corresponding custom error according to the `error` argument provided.
+   */
+  function _throwError(RecoverError error, bytes32 errorArg) private pure {
+    if (error == RecoverError.NoError) {
+      return; // no error: do nothing
+    } else if (error == RecoverError.InvalidSignature) {
+      revert ECDSAInvalidSignature();
+    } else if (error == RecoverError.InvalidSignatureLength) {
+      revert ECDSAInvalidSignatureLength(uint256(errorArg));
+    } else if (error == RecoverError.InvalidSignatureS) {
+      revert ECDSAInvalidSignatureS(errorArg);
+    }
+  }
+}
+
+// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/EIP712.sol)
+
+// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/MessageHashUtils.sol)
+
+// OpenZeppelin Contracts (last updated v5.0.0) (utils/Strings.sol)
+
+// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)
 
 /**
  * @dev Standard math utilities missing in the Solidity language.
@@ -117,15 +2056,14 @@ library Math {
   error MathOverflowedMulDiv();
 
   enum Rounding {
-    Down, // Toward negative infinity
-    Up, // Toward infinity
-    Zero // Toward zero
+    Floor, // Toward negative infinity
+    Ceil, // Toward positive infinity
+    Trunc, // Toward zero
+    Expand // Away from zero
   }
 
   /**
    * @dev Returns the addition of two unsigned integers, with an overflow flag.
-   *
-   * _Available since v5.0._
    */
   function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
     unchecked {
@@ -137,8 +2075,6 @@ library Math {
 
   /**
    * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
-   *
-   * _Available since v5.0._
    */
   function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
     unchecked {
@@ -149,8 +2085,6 @@ library Math {
 
   /**
    * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
-   *
-   * _Available since v5.0._
    */
   function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
     unchecked {
@@ -166,8 +2100,6 @@ library Math {
 
   /**
    * @dev Returns the division of two unsigned integers, with a division by zero flag.
-   *
-   * _Available since v5.0._
    */
   function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
     unchecked {
@@ -178,8 +2110,6 @@ library Math {
 
   /**
    * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
-   *
-   * _Available since v5.0._
    */
   function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
     unchecked {
@@ -214,8 +2144,8 @@ library Math {
   /**
    * @dev Returns the ceiling of the division of two numbers.
    *
-   * This differs from standard division with `/` in that it rounds up instead
-   * of rounding down.
+   * This differs from standard division with `/` in that it rounds towards infinity instead
+   * of rounding towards zero.
    */
   function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
     if (b == 0) {
@@ -228,9 +2158,10 @@ library Math {
   }
 
   /**
-   * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
-   * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
-   * with further edits by Uniswap Labs also under MIT license.
+   * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
+   * denominator == 0.
+   * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
+   * Uniswap Labs also under MIT license.
    */
   function mulDiv(
     uint256 x,
@@ -241,11 +2172,10 @@ library Math {
       // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
       // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
       // variables such that product = prod1 * 2^256 + prod0.
-      uint256 prod0; // Least significant 256 bits of the product
+      uint256 prod0 = x * y; // Least significant 256 bits of the product
       uint256 prod1; // Most significant 256 bits of the product
       assembly {
         let mm := mulmod(x, y, not(0))
-        prod0 := mul(x, y)
         prod1 := sub(sub(mm, prod0), lt(mm, prod0))
       }
 
@@ -277,11 +2207,10 @@ library Math {
         prod0 := sub(prod0, remainder)
       }
 
-      // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
-      // See https://cs.stackexchange.com/q/138556/92363.
+      // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
+      // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.
 
-      // Does not overflow because the denominator cannot be zero at this stage in the function.
-      uint256 twos = denominator & (~denominator + 1);
+      uint256 twos = denominator & (0 - denominator);
       assembly {
         // Divide denominator by twos.
         denominator := div(denominator, twos)
@@ -301,8 +2230,8 @@ library Math {
       // four bits. That is, denominator * inv = 1 mod 2^4.
       uint256 inverse = (3 * denominator) ^ 2;
 
-      // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
-      // in modular arithmetic, doubling the correct bits in each step.
+      // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
+      // works in modular arithmetic, doubling the correct bits in each step.
       inverse *= 2 - denominator * inverse; // inverse mod 2^8
       inverse *= 2 - denominator * inverse; // inverse mod 2^16
       inverse *= 2 - denominator * inverse; // inverse mod 2^32
@@ -329,14 +2258,15 @@ library Math {
     Rounding rounding
   ) internal pure returns (uint256) {
     uint256 result = mulDiv(x, y, denominator);
-    if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
+    if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
       result += 1;
     }
     return result;
   }
 
   /**
-   * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
+   * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
+   * towards zero.
    *
    * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
    */
@@ -379,12 +2309,12 @@ library Math {
   function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
     unchecked {
       uint256 result = sqrt(a);
-      return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
+      return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
     }
   }
 
   /**
-   * @dev Return the log in base 2, rounded down, of a positive value.
+   * @dev Return the log in base 2 of a positive value rounded towards zero.
    * Returns 0 if given 0.
    */
   function log2(uint256 value) internal pure returns (uint256) {
@@ -432,12 +2362,12 @@ library Math {
   function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
     unchecked {
       uint256 result = log2(value);
-      return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
+      return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
     }
   }
 
   /**
-   * @dev Return the log in base 10, rounded down, of a positive value.
+   * @dev Return the log in base 10 of a positive value rounded towards zero.
    * Returns 0 if given 0.
    */
   function log10(uint256 value) internal pure returns (uint256) {
@@ -481,12 +2411,12 @@ library Math {
   function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
     unchecked {
       uint256 result = log10(value);
-      return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
+      return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
     }
   }
 
   /**
-   * @dev Return the log in base 256, rounded down, of a positive value.
+   * @dev Return the log in base 256 of a positive value rounded towards zero.
    * Returns 0 if given 0.
    *
    * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
@@ -524,12 +2454,19 @@ library Math {
   function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
     unchecked {
       uint256 result = log256(value);
-      return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
+      return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
     }
   }
+
+  /**
+   * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
+   */
+  function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
+    return uint8(rounding) % 2 == 1;
+  }
 }
 
-// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)
+// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)
 
 /**
  * @dev Standard signed math utilities missing in the Solidity language.
@@ -574,8 +2511,8 @@ library SignedMath {
  * @dev String operations.
  */
 library Strings {
-  bytes16 private constant _SYMBOLS = '0123456789abcdef';
-  uint8 private constant _ADDRESS_LENGTH = 20;
+  bytes16 private constant HEX_DIGITS = '0123456789abcdef';
+  uint8 private constant ADDRESS_LENGTH = 20;
 
   /**
    * @dev The `value` string doesn't fit in the specified `length`.
@@ -598,7 +2535,7 @@ library Strings {
         ptr--;
         /// @solidity memory-safe-assembly
         assembly {
-          mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
+          mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
         }
         value /= 10;
         if (value == 0) break;
@@ -632,7 +2569,7 @@ library Strings {
     buffer[0] = '0';
     buffer[1] = 'x';
     for (uint256 i = 2 * length + 1; i > 1; --i) {
-      buffer[i] = _SYMBOLS[localValue & 0xf];
+      buffer[i] = HEX_DIGITS[localValue & 0xf];
       localValue >>= 4;
     }
     if (localValue != 0) {
@@ -642,10 +2579,11 @@ library Strings {
   }
 
   /**
-   * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
+   * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
+   * representation.
    */
   function toHexString(address addr) internal pure returns (string memory) {
-    return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
+    return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
   }
 
   /**
@@ -657,1229 +2595,100 @@ library Strings {
 }
 
 /**
- * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
+ * @dev Signature message hash utilities for producing digests to be consumed by {ECDSA} recovery or signing.
  *
- * These functions can be used to verify that a message was signed by the holder
- * of the private keys of a given address.
+ * The library provides methods for generating a hash of a message that conforms to the
+ * https://eips.ethereum.org/EIPS/eip-191[EIP 191] and https://eips.ethereum.org/EIPS/eip-712[EIP 712]
+ * specifications.
  */
-library ECDSA {
-  enum RecoverError {
-    NoError,
-    InvalidSignature,
-    InvalidSignatureLength,
-    InvalidSignatureS
-  }
-
+library MessageHashUtils {
   /**
-   * @dev The signature derives the `address(0)`.
-   */
-  error ECDSAInvalidSignature();
-
-  /**
-   * @dev The signature has an invalid length.
-   */
-  error ECDSAInvalidSignatureLength(uint256 length);
-
-  /**
-   * @dev The signature has an S value that is in the upper half order.
-   */
-  error ECDSAInvalidSignatureS(bytes32 s);
-
-  function _throwError(RecoverError error, bytes32 errorArg) private pure {
-    if (error == RecoverError.NoError) {
-      return; // no error: do nothing
-    } else if (error == RecoverError.InvalidSignature) {
-      revert ECDSAInvalidSignature();
-    } else if (error == RecoverError.InvalidSignatureLength) {
-      revert ECDSAInvalidSignatureLength(uint256(errorArg));
-    } else if (error == RecoverError.InvalidSignatureS) {
-      revert ECDSAInvalidSignatureS(errorArg);
-    }
-  }
-
-  /**
-   * @dev Returns the address that signed a hashed message (`hash`) with
-   * `signature` or error string. This address can then be used for verification purposes.
-   *
-   * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
-   * this function rejects them by requiring the `s` value to be in the lower
-   * half order, and the `v` value to be either 27 or 28.
-   *
-   * IMPORTANT: `hash` _must_ be the result of a hash operation for the
-   * verification to be secure: it is possible to craft signatures that
-   * recover to arbitrary addresses for non-hashed data. A safe way to ensure
-   * this is by receiving a hash of the original message (which may otherwise
-   * be too long), and then calling {toEthSignedMessageHash} on it.
-   *
-   * Documentation for signature generation:
-   * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
-   * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
-   *
-   * _Available since v4.3._
-   */
-  function tryRecover(
-    bytes32 hash,
-    bytes memory signature
-  ) internal pure returns (address, RecoverError, bytes32) {
-    if (signature.length == 65) {
-      bytes32 r;
-      bytes32 s;
-      uint8 v;
-      // ecrecover takes the signature parameters, and the only way to get them
-      // currently is to use assembly.
-      /// @solidity memory-safe-assembly
-      assembly {
-        r := mload(add(signature, 0x20))
-        s := mload(add(signature, 0x40))
-        v := byte(0, mload(add(signature, 0x60)))
-      }
-      return tryRecover(hash, v, r, s);
-    } else {
-      return (address(0), RecoverError.InvalidSignatureLength, bytes32(signature.length));
-    }
-  }
-
-  /**
-   * @dev Returns the address that signed a hashed message (`hash`) with
-   * `signature`. This address can then be used for verification purposes.
-   *
-   * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
-   * this function rejects them by requiring the `s` value to be in the lower
-   * half order, and the `v` value to be either 27 or 28.
+   * @dev Returns the keccak256 digest of an EIP-191 signed data with version
+   * `0x45` (`personal_sign` messages).
    *
-   * IMPORTANT: `hash` _must_ be the result of a hash operation for the
-   * verification to be secure: it is possible to craft signatures that
-   * recover to arbitrary addresses for non-hashed data. A safe way to ensure
-   * this is by receiving a hash of the original message (which may otherwise
-   * be too long), and then calling {toEthSignedMessageHash} on it.
-   */
-  function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
-    (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, signature);
-    _throwError(error, errorArg);
-    return recovered;
-  }
-
-  /**
-   * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
+   * The digest is calculated by prefixing a bytes32 `messageHash` with
+   * `"\x19Ethereum Signed Message:\n32"` and hashing the result. It corresponds with the
+   * hash signed when using the https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`] JSON-RPC method.
    *
-   * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
-   *
-   * _Available since v4.3._
-   */
-  function tryRecover(
-    bytes32 hash,
-    bytes32 r,
-    bytes32 vs
-  ) internal pure returns (address, RecoverError, bytes32) {
-    unchecked {
-      bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
-      // We do not check for an overflow here since the shift operation results in 0 or 1.
-      uint8 v = uint8((uint256(vs) >> 255) + 27);
-      return tryRecover(hash, v, r, s);
-    }
-  }
-
-  /**
-   * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
-   *
-   * _Available since v4.2._
-   */
-  function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
-    (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, r, vs);
-    _throwError(error, errorArg);
-    return recovered;
-  }
-
-  /**
-   * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
-   * `r` and `s` signature fields separately.
-   *
-   * _Available since v4.3._
-   */
-  function tryRecover(
-    bytes32 hash,
-    uint8 v,
-    bytes32 r,
-    bytes32 s
-  ) internal pure returns (address, RecoverError, bytes32) {
-    // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
-    // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
-    // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
-    // signatures from current libraries generate a unique signature with an s-value in the lower half order.
-    //
-    // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
-    // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
-    // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
-    // these malleable signatures as well.
-    if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
-      return (address(0), RecoverError.InvalidSignatureS, s);
-    }
-
-    // If the signature is valid (and not malleable), return the signer address
-    address signer = ecrecover(hash, v, r, s);
-    if (signer == address(0)) {
-      return (address(0), RecoverError.InvalidSignature, bytes32(0));
-    }
-
-    return (signer, RecoverError.NoError, bytes32(0));
-  }
-
-  /**
-   * @dev Overload of {ECDSA-recover} that receives the `v`,
-   * `r` and `s` signature fields separately.
-   */
-  function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
-    (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, v, r, s);
-    _throwError(error, errorArg);
-    return recovered;
-  }
-
-  /**
-   * @dev Returns an Ethereum Signed Message, created from a `hash`. This
-   * produces hash corresponding to the one signed with the
-   * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
-   * JSON-RPC method as part of EIP-191.
+   * NOTE: The `messageHash` parameter is intended to be the result of hashing a raw message with
+   * keccak256, although any bytes32 value can be safely used because the final digest will
+   * be re-hashed.
    *
-   * See {recover}.
+   * See {ECDSA-recover}.
    */
-  function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
-    // 32 is the length in bytes of hash,
-    // enforced by the type signature above
+  function toEthSignedMessageHash(bytes32 messageHash) internal pure returns (bytes32 digest) {
     /// @solidity memory-safe-assembly
     assembly {
-      mstore(0x00, '\x19Ethereum Signed Message:\n32')
-      mstore(0x1c, hash)
-      message := keccak256(0x00, 0x3c)
+      mstore(0x00, '\x19Ethereum Signed Message:\n32') // 32 is the bytes-length of messageHash
+      mstore(0x1c, messageHash) // 0x1c (28) is the length of the prefix
+      digest := keccak256(0x00, 0x3c) // 0x3c is the length of the prefix (0x1c) + messageHash (0x20)
     }
   }
 
   /**
-   * @dev Returns an Ethereum Signed Message, created from `s`. This
-   * produces hash corresponding to the one signed with the
-   * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
-   * JSON-RPC method as part of EIP-191.
+   * @dev Returns the keccak256 digest of an EIP-191 signed data with version
+   * `0x45` (`personal_sign` messages).
    *
-   * See {recover}.
+   * The digest is calculated by prefixing an arbitrary `message` with
+   * `"\x19Ethereum Signed Message:\n" + len(message)` and hashing the result. It corresponds with the
+   * hash signed when using the https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`] JSON-RPC method.
+   *
+   * See {ECDSA-recover}.
    */
-  function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
+  function toEthSignedMessageHash(bytes memory message) internal pure returns (bytes32) {
     return
-      keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n', Strings.toString(s.length), s));
+      keccak256(
+        bytes.concat(
+          '\x19Ethereum Signed Message:\n',
+          bytes(Strings.toString(message.length)),
+          message
+        )
+      );
   }
 
   /**
-   * @dev Returns an Ethereum Signed Typed Data, created from a
-   * `domainSeparator` and a `structHash`. This produces hash corresponding
-   * to the one signed with the
-   * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
-   * JSON-RPC method as part of EIP-712.
+   * @dev Returns the keccak256 digest of an EIP-191 signed data with version
+   * `0x00` (data with intended validator).
    *
-   * See {recover}.
+   * The digest is calculated by prefixing an arbitrary `data` with `"\x19\x00"` and the intended
+   * `validator` address. Then hashing the result.
+   *
+   * See {ECDSA-recover}.
+   */
+  function toDataWithIntendedValidatorHash(
+    address validator,
+    bytes memory data
+  ) internal pure returns (bytes32) {
+    return keccak256(abi.encodePacked(hex'19_00', validator, data));
+  }
+
+  /**
+   * @dev Returns the keccak256 digest of an EIP-712 typed data (EIP-191 version `0x01`).
+   *
+   * The digest is calculated from a `domainSeparator` and a `structHash`, by prefixing them with
+   * `\x19\x01` and hashing the result. It corresponds to the hash signed by the
+   * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`] JSON-RPC method as part of EIP-712.
+   *
+   * See {ECDSA-recover}.
    */
   function toTypedDataHash(
     bytes32 domainSeparator,
     bytes32 structHash
-  ) internal pure returns (bytes32 data) {
+  ) internal pure returns (bytes32 digest) {
     /// @solidity memory-safe-assembly
     assembly {
       let ptr := mload(0x40)
       mstore(ptr, hex'19_01')
       mstore(add(ptr, 0x02), domainSeparator)
       mstore(add(ptr, 0x22), structHash)
-      data := keccak256(ptr, 0x42)
+      digest := keccak256(ptr, 0x42)
     }
   }
-
-  /**
-   * @dev Returns an Ethereum Signed Data with intended validator, created from a
-   * `validator` and `data` according to the version 0 of EIP-191.
-   *
-   * See {recover}.
-   */
-  function toDataWithIntendedValidatorHash(
-    address validator,
-    bytes memory data
-  ) internal pure returns (bytes32) {
-    return keccak256(abi.encodePacked(hex'19_00', validator, data));
-  }
-}
-
-/** @notice influenced by OpenZeppelin SafeCast lib, which is missing to uint72 cast
- * @author BGD Labs
- */
-library SafeCast72 {
-  /**
-   * @dev Returns the downcasted uint72 from uint256, reverting on
-   * overflow (when the input is greater than largest uint72).
-   *
-   * Counterpart to Solidity's `uint16` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 72 bits
-   */
-  function toUint72(uint256 value) internal pure returns (uint72) {
-    require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
-    return uint72(value);
-  }
-}
-
-interface IGovernancePowerDelegationToken {
-  enum GovernancePowerType {
-    VOTING,
-    PROPOSITION
-  }
-
-  /**
-   * @dev emitted when a user delegates to another
-   * @param delegator the user which delegated governance power
-   * @param delegatee the delegatee
-   * @param delegationType the type of delegation (VOTING, PROPOSITION)
-   **/
-  event DelegateChanged(
-    address indexed delegator,
-    address indexed delegatee,
-    GovernancePowerType delegationType
-  );
-
-  // @dev we removed DelegatedPowerChanged event because to reconstruct the full state of the system,
-  // is enough to have Transfer and DelegateChanged TODO: document it
-
-  /**
-   * @dev delegates the specific power to a delegatee
-   * @param delegatee the user which delegated power will change
-   * @param delegationType the type of delegation (VOTING, PROPOSITION)
-   **/
-  function delegateByType(address delegatee, GovernancePowerType delegationType) external;
-
-  /**
-   * @dev delegates all the governance powers to a specific user
-   * @param delegatee the user to which the powers will be delegated
-   **/
-  function delegate(address delegatee) external;
-
-  /**
-   * @dev returns the delegatee of an user
-   * @param delegator the address of the delegator
-   * @param delegationType the type of delegation (VOTING, PROPOSITION)
-   * @return address of the specified delegatee
-   **/
-  function getDelegateeByType(
-    address delegator,
-    GovernancePowerType delegationType
-  ) external view returns (address);
-
-  /**
-   * @dev returns delegates of an user
-   * @param delegator the address of the delegator
-   * @return a tuple of addresses the VOTING and PROPOSITION delegatee
-   **/
-  function getDelegates(address delegator) external view returns (address, address);
-
-  /**
-   * @dev returns the current voting or proposition power of a user.
-   * @param user the user
-   * @param delegationType the type of delegation (VOTING, PROPOSITION)
-   * @return the current voting or proposition power of a user
-   **/
-  function getPowerCurrent(
-    address user,
-    GovernancePowerType delegationType
-  ) external view returns (uint256);
-
-  /**
-   * @dev returns the current voting or proposition power of a user.
-   * @param user the user
-   * @return the current voting and proposition power of a user
-   **/
-  function getPowersCurrent(address user) external view returns (uint256, uint256);
-
-  /**
-   * @dev implements the permit function as for https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
-   * @param delegator the owner of the funds
-   * @param delegatee the user to who owner delegates his governance power
-   * @param delegationType the type of governance power delegation (VOTING, PROPOSITION)
-   * @param deadline the deadline timestamp, type(uint256).max for no deadline
-   * @param v signature param
-   * @param s signature param
-   * @param r signature param
-   */
-  function metaDelegateByType(
-    address delegator,
-    address delegatee,
-    GovernancePowerType delegationType,
-    uint256 deadline,
-    uint8 v,
-    bytes32 r,
-    bytes32 s
-  ) external;
-
-  /**
-   * @dev implements the permit function as for https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
-   * @param delegator the owner of the funds
-   * @param delegatee the user to who delegator delegates his voting and proposition governance power
-   * @param deadline the deadline timestamp, type(uint256).max for no deadline
-   * @param v signature param
-   * @param s signature param
-   * @param r signature param
-   */
-  function metaDelegate(
-    address delegator,
-    address delegatee,
-    uint256 deadline,
-    uint8 v,
-    bytes32 r,
-    bytes32 s
-  ) external;
-}
-
-enum DelegationMode {
-  NO_DELEGATION,
-  VOTING_DELEGATED,
-  PROPOSITION_DELEGATED,
-  FULL_POWER_DELEGATED
-}
-
-/**
- * @notice The contract implements generic delegation functionality for the upcoming governance v3
- * @author BGD Labs
- * @dev to make it's pluggable to any exising token it has a set of virtual functions
- *   for simple access to balances and permit functionality
- * @dev ************ IMPORTANT SECURITY CONSIDERATION ************
- *   current version of the token can be used only with asset which has 18 decimals
- *   and possible totalSupply lower then 4722366482869645213696,
- *   otherwise at least POWER_SCALE_FACTOR should be adjusted !!!
- *   *************************************************************
- */
-abstract contract BaseDelegation is IGovernancePowerDelegationToken {
-  struct DelegationState {
-    uint72 delegatedPropositionBalance;
-    uint72 delegatedVotingBalance;
-    DelegationMode delegationMode;
-  }
-
-  mapping(address => address) internal _votingDelegatee;
-  mapping(address => address) internal _propositionDelegatee;
-
-  /** @dev we assume that for the governance system delegation with 18 decimals of precision is not needed,
-   *   by this constant we reduce it by 10, to 8 decimals.
-   *   In case of Aave token this will allow to work with up to 47'223'664'828'696,45213696 total supply
-   *   If your token already have less then 10 decimals, please change it to appropriate.
-   */
-  uint256 public constant POWER_SCALE_FACTOR = 1e10;
-
-  bytes32 public constant DELEGATE_BY_TYPE_TYPEHASH =
-    keccak256(
-      'DelegateByType(address delegator,address delegatee,uint8 delegationType,uint256 nonce,uint256 deadline)'
-    );
-  bytes32 public constant DELEGATE_TYPEHASH =
-    keccak256('Delegate(address delegator,address delegatee,uint256 nonce,uint256 deadline)');
-
-  /**
-   * @notice returns eip-2612 compatible domain separator
-   * @dev we expect that existing tokens, ie Aave, already have, so we want to reuse
-   * @return domain separator
-   */
-  function _getDomainSeparator() internal view virtual returns (bytes32);
-
-  /**
-   * @notice gets the delegation state of a user
-   * @param user address
-   * @return state of a user's delegation
-   */
-  function _getDelegationState(address user) internal view virtual returns (DelegationState memory);
-
-  /**
-   * @notice returns the token balance of a user
-   * @param user address
-   * @return current nonce before increase
-   */
-  function _getBalance(address user) internal view virtual returns (uint256);
-
-  /**
-   * @notice increases and return the current nonce of a user
-   * @dev should use `return nonce++;` pattern
-   * @param user address
-   * @return current nonce before increase
-   */
-  function _incrementNonces(address user) internal virtual returns (uint256);
-
-  /**
-   * @notice sets the delegation state of a user
-   * @param user address
-   * @param delegationState state of a user's delegation
-   */
-  function _setDelegationState(
-    address user,
-    DelegationState memory delegationState
-  ) internal virtual;
-
-  /// @inheritdoc IGovernancePowerDelegationToken
-  function delegateByType(
-    address delegatee,
-    GovernancePowerType delegationType
-  ) external virtual override {
-    _delegateByType(msg.sender, delegatee, delegationType);
-  }
-
-  /// @inheritdoc IGovernancePowerDelegationToken
-  function delegate(address delegatee) external override {
-    _delegateByType(msg.sender, delegatee, GovernancePowerType.VOTING);
-    _delegateByType(msg.sender, delegatee, GovernancePowerType.PROPOSITION);
-  }
-
-  /// @inheritdoc IGovernancePowerDelegationToken
-  function getDelegateeByType(
-    address delegator,
-    GovernancePowerType delegationType
-  ) external view override returns (address) {
-    return _getDelegateeByType(delegator, _getDelegationState(delegator), delegationType);
-  }
-
-  /// @inheritdoc IGovernancePowerDelegationToken
-  function getDelegates(address delegator) external view override returns (address, address) {
-    DelegationState memory delegatorBalance = _getDelegationState(delegator);
-    return (
-      _getDelegateeByType(delegator, delegatorBalance, GovernancePowerType.VOTING),
-      _getDelegateeByType(delegator, delegatorBalance, GovernancePowerType.PROPOSITION)
-    );
-  }
-
-  /// @inheritdoc IGovernancePowerDelegationToken
-  function getPowerCurrent(
-    address user,
-    GovernancePowerType delegationType
-  ) public view virtual override returns (uint256) {
-    DelegationState memory userState = _getDelegationState(user);
-    uint256 userOwnPower = uint8(userState.delegationMode) & (uint8(delegationType) + 1) == 0
-      ? _getBalance(user)
-      : 0;
-    uint256 userDelegatedPower = _getDelegatedPowerByType(userState, delegationType);
-    return userOwnPower + userDelegatedPower;
-  }
-
-  /// @inheritdoc IGovernancePowerDelegationToken
-  function getPowersCurrent(address user) external view override returns (uint256, uint256) {
-    return (
-      getPowerCurrent(user, GovernancePowerType.VOTING),
-      getPowerCurrent(user, GovernancePowerType.PROPOSITION)
-    );
-  }
-
-  /// @inheritdoc IGovernancePowerDelegationToken
-  function metaDelegateByType(
-    address delegator,
-    address delegatee,
-    GovernancePowerType delegationType,
-    uint256 deadline,
-    uint8 v,
-    bytes32 r,
-    bytes32 s
-  ) external override {
-    require(delegator != address(0), 'INVALID_OWNER');
-    //solium-disable-next-line
-    require(block.timestamp <= deadline, 'INVALID_EXPIRATION');
-    bytes32 digest = ECDSA.toTypedDataHash(
-      _getDomainSeparator(),
-      keccak256(
-        abi.encode(
-          DELEGATE_BY_TYPE_TYPEHASH,
-          delegator,
-          delegatee,
-          delegationType,
-          _incrementNonces(delegator),
-          deadline
-        )
-      )
-    );
-
-    require(delegator == ECDSA.recover(digest, v, r, s), 'INVALID_SIGNATURE');
-    _delegateByType(delegator, delegatee, delegationType);
-  }
-
-  /// @inheritdoc IGovernancePowerDelegationToken
-  function metaDelegate(
-    address delegator,
-    address delegatee,
-    uint256 deadline,
-    uint8 v,
-    bytes32 r,
-    bytes32 s
-  ) external override {
-    require(delegator != address(0), 'INVALID_OWNER');
-    //solium-disable-next-line
-    require(block.timestamp <= deadline, 'INVALID_EXPIRATION');
-    bytes32 digest = ECDSA.toTypedDataHash(
-      _getDomainSeparator(),
-      keccak256(
-        abi.encode(DELEGATE_TYPEHASH, delegator, delegatee, _incrementNonces(delegator), deadline)
-      )
-    );
-
-    require(delegator == ECDSA.recover(digest, v, r, s), 'INVALID_SIGNATURE');
-    _delegateByType(delegator, delegatee, GovernancePowerType.VOTING);
-    _delegateByType(delegator, delegatee, GovernancePowerType.PROPOSITION);
-  }
-
-  /**
-   * @dev Modifies the delegated power of a `delegatee` account by type (VOTING, PROPOSITION).
-   * Passing the impact on the delegation of `delegatee` account before and after to reduce conditionals and not lose
-   * any precision.
-   * @param impactOnDelegationBefore how much impact a balance of another account had over the delegation of a `delegatee`
-   * before an action.
-   * For example, if the action is a delegation from one account to another, the impact before the action will be 0.
-   * @param impactOnDelegationAfter how much impact a balance of another account will have  over the delegation of a `delegatee`
-   * after an action.
-   * For example, if the action is a delegation from one account to another, the impact after the action will be the whole balance
-   * of the account changing the delegatee.
-   * @param delegatee the user whom delegated governance power will be changed
-   * @param delegationType the type of governance power delegation (VOTING, PROPOSITION)
-   **/
-  function _governancePowerTransferByType(
-    uint256 impactOnDelegationBefore,
-    uint256 impactOnDelegationAfter,
-    address delegatee,
-    GovernancePowerType delegationType
-  ) internal {
-    if (delegatee == address(0)) return;
-    if (impactOnDelegationBefore == impactOnDelegationAfter) return;
-
-    // we use uint72, because this is the most optimal for AaveTokenV3
-    // To make delegated balance fit into uint72 we're decreasing precision of delegated balance by POWER_SCALE_FACTOR
-    uint72 impactOnDelegationBefore72 = SafeCast72.toUint72(
-      impactOnDelegationBefore / POWER_SCALE_FACTOR
-    );
-    uint72 impactOnDelegationAfter72 = SafeCast72.toUint72(
-      impactOnDelegationAfter / POWER_SCALE_FACTOR
-    );
-
-    DelegationState memory delegateeState = _getDelegationState(delegatee);
-    if (delegationType == GovernancePowerType.VOTING) {
-      delegateeState.delegatedVotingBalance =
-        delegateeState.delegatedVotingBalance -
-        impactOnDelegationBefore72 +
-        impactOnDelegationAfter72;
-    } else {
-      delegateeState.delegatedPropositionBalance =
-        delegateeState.delegatedPropositionBalance -
-        impactOnDelegationBefore72 +
-        impactOnDelegationAfter72;
-    }
-    _setDelegationState(delegatee, delegateeState);
-  }
-
-  /**
-   * @dev performs all state changes related delegation changes on transfer
-   * @param from token sender
-   * @param to token recipient
-   * @param fromBalanceBefore balance of the sender before transfer
-   * @param toBalanceBefore balance of the recipient before transfer
-   * @param amount amount of tokens sent
-   **/
-  function _delegationChangeOnTransfer(
-    address from,
-    address to,
-    uint256 fromBalanceBefore,
-    uint256 toBalanceBefore,
-    uint256 amount
-  ) internal {
-    if (from == to) {
-      return;
-    }
-
-    if (from != address(0)) {
-      DelegationState memory fromUserState = _getDelegationState(from);
-      uint256 fromBalanceAfter = fromBalanceBefore - amount;
-      if (fromUserState.delegationMode != DelegationMode.NO_DELEGATION) {
-        _governancePowerTransferByType(
-          fromBalanceBefore,
-          fromBalanceAfter,
-          _getDelegateeByType(from, fromUserState, GovernancePowerType.VOTING),
-          GovernancePowerType.VOTING
-        );
-        _governancePowerTransferByType(
-          fromBalanceBefore,
-          fromBalanceAfter,
-          _getDelegateeByType(from, fromUserState, GovernancePowerType.PROPOSITION),
-          GovernancePowerType.PROPOSITION
-        );
-      }
-    }
-
-    if (to != address(0)) {
-      DelegationState memory toUserState = _getDelegationState(to);
-      uint256 toBalanceAfter = toBalanceBefore + amount;
-
-      if (toUserState.delegationMode != DelegationMode.NO_DELEGATION) {
-        _governancePowerTransferByType(
-          toBalanceBefore,
-          toBalanceAfter,
-          _getDelegateeByType(to, toUserState, GovernancePowerType.VOTING),
-          GovernancePowerType.VOTING
-        );
-        _governancePowerTransferByType(
-          toBalanceBefore,
-          toBalanceAfter,
-          _getDelegateeByType(to, toUserState, GovernancePowerType.PROPOSITION),
-          GovernancePowerType.PROPOSITION
-        );
-      }
-    }
-  }
-
-  /**
-   * @dev Extracts from state and returns delegated governance power (Voting, Proposition)
-   * @param userState the current state of a user
-   * @param delegationType the type of governance power delegation (VOTING, PROPOSITION)
-   **/
-  function _getDelegatedPowerByType(
-    DelegationState memory userState,
-    GovernancePowerType delegationType
-  ) internal pure returns (uint256) {
-    return
-      POWER_SCALE_FACTOR *
-      (
-        delegationType == GovernancePowerType.VOTING
-          ? userState.delegatedVotingBalance
-          : userState.delegatedPropositionBalance
-      );
-  }
-
-  /**
-   * @dev Extracts from state and returns the delegatee of a delegator by type of governance power (Voting, Proposition)
-   * - If the delegator doesn't have any delegatee, returns address(0)
-   * @param delegator delegator
-   * @param userState the current state of a user
-   * @param delegationType the type of governance power delegation (VOTING, PROPOSITION)
-   **/
-  function _getDelegateeByType(
-    address delegator,
-    DelegationState memory userState,
-    GovernancePowerType delegationType
-  ) internal view returns (address) {
-    if (delegationType == GovernancePowerType.VOTING) {
-      return
-        /// With the & operation, we cover both VOTING_DELEGATED delegation and FULL_POWER_DELEGATED
-        /// as VOTING_DELEGATED is equivalent to 01 in binary and FULL_POWER_DELEGATED is equivalent to 11
-        (uint8(userState.delegationMode) & uint8(DelegationMode.VOTING_DELEGATED)) != 0
-          ? _votingDelegatee[delegator]
-          : address(0);
-    }
-    return
-      userState.delegationMode >= DelegationMode.PROPOSITION_DELEGATED
-        ? _propositionDelegatee[delegator]
-        : address(0);
-  }
-
-  /**
-   * @dev Changes user's delegatee address by type of governance power (Voting, Proposition)
-   * @param delegator delegator
-   * @param delegationType the type of governance power delegation (VOTING, PROPOSITION)
-   * @param _newDelegatee the new delegatee
-   **/
-  function _updateDelegateeByType(
-    address delegator,
-    GovernancePowerType delegationType,
-    address _newDelegatee
-  ) internal {
-    address newDelegatee = _newDelegatee == delegator ? address(0) : _newDelegatee;
-    if (delegationType == GovernancePowerType.VOTING) {
-      _votingDelegatee[delegator] = newDelegatee;
-    } else {
-      _propositionDelegatee[delegator] = newDelegatee;
-    }
-  }
-
-  /**
-   * @dev Updates the specific flag which signaling about existence of delegation of governance power (Voting, Proposition)
-   * @param userState a user state to change
-   * @param delegationType the type of governance power delegation (VOTING, PROPOSITION)
-   * @param willDelegate next state of delegation
-   **/
-  function _updateDelegationModeByType(
-    DelegationState memory userState,
-    GovernancePowerType delegationType,
-    bool willDelegate
-  ) internal pure returns (DelegationState memory) {
-    if (willDelegate) {
-      // Because GovernancePowerType starts from 0, we should add 1 first, then we apply bitwise OR
-      userState.delegationMode = DelegationMode(
-        uint8(userState.delegationMode) | (uint8(delegationType) + 1)
-      );
-    } else {
-      // First bitwise NEGATION, ie was 01, after XOR with 11 will be 10,
-      // then bitwise AND, which means it will keep only another delegation type if it exists
-      userState.delegationMode = DelegationMode(
-        uint8(userState.delegationMode) &
-          ((uint8(delegationType) + 1) ^ uint8(DelegationMode.FULL_POWER_DELEGATED))
-      );
-    }
-    return userState;
-  }
-
-  /**
-   * @dev This is the equivalent of an ERC20 transfer(), but for a power type: an atomic transfer of a balance (power).
-   * When needed, it decreases the power of the `delegator` and when needed, it increases the power of the `delegatee`
-   * @param delegator delegator
-   * @param _delegatee the user which delegated power will change
-   * @param delegationType the type of delegation (VOTING, PROPOSITION)
-   **/
-  function _delegateByType(
-    address delegator,
-    address _delegatee,
-    GovernancePowerType delegationType
-  ) internal {
-    // Here we unify the property that delegating power to address(0) == delegating power to yourself == no delegation
-    // So from now on, not being delegating is (exclusively) that delegatee == address(0)
-    address delegatee = _delegatee == delegator ? address(0) : _delegatee;
-
-    // We read the whole struct before validating delegatee, because in the optimistic case
-    // (_delegatee != currentDelegatee) we will reuse userState in the rest of the function
-    DelegationState memory delegatorState = _getDelegationState(delegator);
-    address currentDelegatee = _getDelegateeByType(delegator, delegatorState, delegationType);
-    if (delegatee == currentDelegatee) return;
-
-    bool delegatingNow = currentDelegatee != address(0);
-    bool willDelegateAfter = delegatee != address(0);
-    uint256 delegatorBalance = _getBalance(delegator);
-
-    if (delegatingNow) {
-      _governancePowerTransferByType(delegatorBalance, 0, currentDelegatee, delegationType);
-    }
-
-    if (willDelegateAfter) {
-      _governancePowerTransferByType(0, delegatorBalance, delegatee, delegationType);
-    }
-
-    _updateDelegateeByType(delegator, delegationType, delegatee);
-
-    if (willDelegateAfter != delegatingNow) {
-      _setDelegationState(
-        delegator,
-        _updateDelegationModeByType(delegatorState, delegationType, willDelegateAfter)
-      );
-    }
-
-    emit DelegateChanged(delegator, delegatee, delegationType);
-  }
-}
-
-library DistributionTypes {
-  struct AssetConfigInput {
-    uint128 emissionPerSecond;
-    uint256 totalStaked;
-    address underlyingAsset;
-  }
-
-  struct UserStakeInput {
-    address underlyingAsset;
-    uint256 stakedByUser;
-    uint256 totalStaked;
-  }
 }
 
-// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)
-
-// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)
-
-/**
- * @dev Collection of functions related to the address type
- */
-library Address {
-  /**
-   * @dev Returns true if `account` is a contract.
-   *
-   * [IMPORTANT]
-   * ====
-   * It is unsafe to assume that an address for which this function returns
-   * false is an externally-owned account (EOA) and not a contract.
-   *
-   * Among others, `isContract` will return false for the following
-   * types of addresses:
-   *
-   *  - an externally-owned account
-   *  - a contract in construction
-   *  - an address where a contract will be created
-   *  - an address where a contract lived, but was destroyed
-   * ====
-   *
-   * [IMPORTANT]
-   * ====
-   * You shouldn't rely on `isContract` to protect against flash loan attacks!
-   *
-   * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
-   * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
-   * constructor.
-   * ====
-   */
-  function isContract(address account) internal view returns (bool) {
-    // This method relies on extcodesize/address.code.length, which returns 0
-    // for contracts in construction, since the code is only stored at the end
-    // of the constructor execution.
-
-    return account.code.length > 0;
-  }
-
-  /**
-   * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
-   * `recipient`, forwarding all available gas and reverting on errors.
-   *
-   * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
-   * of certain opcodes, possibly making contracts go over the 2300 gas limit
-   * imposed by `transfer`, making them unable to receive funds via
-   * `transfer`. {sendValue} removes this limitation.
-   *
-   * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
-   *
-   * IMPORTANT: because control is transferred to `recipient`, care must be
-   * taken to not create reentrancy vulnerabilities. Consider using
-   * {ReentrancyGuard} or the
-   * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
-   */
-  function sendValue(address payable recipient, uint256 amount) internal {
-    require(address(this).balance >= amount, 'Address: insufficient balance');
-
-    (bool success, ) = recipient.call{value: amount}('');
-    require(success, 'Address: unable to send value, recipient may have reverted');
-  }
-
-  /**
-   * @dev Performs a Solidity function call using a low level `call`. A
-   * plain `call` is an unsafe replacement for a function call: use this
-   * function instead.
-   *
-   * If `target` reverts with a revert reason, it is bubbled up by this
-   * function (like regular Solidity function calls).
-   *
-   * Returns the raw returned data. To convert to the expected return value,
-   * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
-   *
-   * Requirements:
-   *
-   * - `target` must be a contract.
-   * - calling `target` with `data` must not revert.
-   *
-   * _Available since v3.1._
-   */
-  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
-    return functionCallWithValue(target, data, 0, 'Address: low-level call failed');
-  }
-
-  /**
-   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
-   * `errorMessage` as a fallback revert reason when `target` reverts.
-   *
-   * _Available since v3.1._
-   */
-  function functionCall(
-    address target,
-    bytes memory data,
-    string memory errorMessage
-  ) internal returns (bytes memory) {
-    return functionCallWithValue(target, data, 0, errorMessage);
-  }
-
-  /**
-   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
-   * but also transferring `value` wei to `target`.
-   *
-   * Requirements:
-   *
-   * - the calling contract must have an ETH balance of at least `value`.
-   * - the called Solidity function must be `payable`.
-   *
-   * _Available since v3.1._
-   */
-  function functionCallWithValue(
-    address target,
-    bytes memory data,
-    uint256 value
-  ) internal returns (bytes memory) {
-    return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
-  }
-
-  /**
-   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
-   * with `errorMessage` as a fallback revert reason when `target` reverts.
-   *
-   * _Available since v3.1._
-   */
-  function functionCallWithValue(
-    address target,
-    bytes memory data,
-    uint256 value,
-    string memory errorMessage
-  ) internal returns (bytes memory) {
-    require(address(this).balance >= value, 'Address: insufficient balance for call');
-    (bool success, bytes memory returndata) = target.call{value: value}(data);
-    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
-  }
-
-  /**
-   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
-   * but performing a static call.
-   *
-   * _Available since v3.3._
-   */
-  function functionStaticCall(
-    address target,
-    bytes memory data
-  ) internal view returns (bytes memory) {
-    return functionStaticCall(target, data, 'Address: low-level static call failed');
-  }
-
-  /**
-   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
-   * but performing a static call.
-   *
-   * _Available since v3.3._
-   */
-  function functionStaticCall(
-    address target,
-    bytes memory data,
-    string memory errorMessage
-  ) internal view returns (bytes memory) {
-    (bool success, bytes memory returndata) = target.staticcall(data);
-    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
-  }
-
-  /**
-   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
-   * but performing a delegate call.
-   *
-   * _Available since v3.4._
-   */
-  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
-    return functionDelegateCall(target, data, 'Address: low-level delegate call failed');
-  }
-
-  /**
-   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
-   * but performing a delegate call.
-   *
-   * _Available since v3.4._
-   */
-  function functionDelegateCall(
-    address target,
-    bytes memory data,
-    string memory errorMessage
-  ) internal returns (bytes memory) {
-    (bool success, bytes memory returndata) = target.delegatecall(data);
-    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
-  }
-
-  /**
-   * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
-   * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
-   *
-   * _Available since v4.8._
-   */
-  function verifyCallResultFromTarget(
-    address target,
-    bool success,
-    bytes memory returndata,
-    string memory errorMessage
-  ) internal view returns (bytes memory) {
-    if (success) {
-      if (returndata.length == 0) {
-        // only check isContract if the call was successful and the return data is empty
-        // otherwise we already know that it was a contract
-        require(isContract(target), 'Address: call to non-contract');
-      }
-      return returndata;
-    } else {
-      _revert(returndata, errorMessage);
-    }
-  }
-
-  /**
-   * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
-   * revert reason or using the provided one.
-   *
-   * _Available since v4.3._
-   */
-  function verifyCallResult(
-    bool success,
-    bytes memory returndata,
-    string memory errorMessage
-  ) internal pure returns (bytes memory) {
-    if (success) {
-      return returndata;
-    } else {
-      _revert(returndata, errorMessage);
-    }
-  }
-
-  function _revert(bytes memory returndata, string memory errorMessage) private pure {
-    // Look for revert reason and bubble it up if present
-    if (returndata.length > 0) {
-      // The easiest way to bubble the revert reason is using memory via assembly
-      /// @solidity memory-safe-assembly
-      assembly {
-        let returndata_size := mload(returndata)
-        revert(add(32, returndata), returndata_size)
-      }
-    } else {
-      revert(errorMessage);
-    }
-  }
-}
-
-/**
- * @title SafeERC20
- * @dev Wrappers around ERC20 operations that throw on failure (when the token
- * contract returns false). Tokens that return no value (and instead revert or
- * throw on failure) are also supported, non-reverting calls are assumed to be
- * successful.
- * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
- * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
- */
-library SafeERC20 {
-  using Address for address;
-
-  function safeTransfer(IERC20 token, address to, uint256 value) internal {
-    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
-  }
-
-  function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
-    _callOptionalReturn(
-      token,
-      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
-    );
-  }
-
-  /**
-   * @dev Deprecated. This function has issues similar to the ones found in
-   * {IERC20-approve}, and its usage is discouraged.
-   *
-   * Whenever possible, use {safeIncreaseAllowance} and
-   * {safeDecreaseAllowance} instead.
-   */
-  function safeApprove(IERC20 token, address spender, uint256 value) internal {
-    // safeApprove should only be called when setting an initial allowance,
-    // or when resetting it to zero. To increase and decrease it, use
-    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
-    require(
-      (value == 0) || (token.allowance(address(this), spender) == 0),
-      'SafeERC20: approve from non-zero to non-zero allowance'
-    );
-    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
-  }
-
-  function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
-    uint256 newAllowance = token.allowance(address(this), spender) + value;
-    _callOptionalReturn(
-      token,
-      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
-    );
-  }
-
-  function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
-    unchecked {
-      uint256 oldAllowance = token.allowance(address(this), spender);
-      require(oldAllowance >= value, 'SafeERC20: decreased allowance below zero');
-      uint256 newAllowance = oldAllowance - value;
-      _callOptionalReturn(
-        token,
-        abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
-      );
-    }
-  }
-
-  /**
-   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
-   * on the return value: the return value is optional (but if data is returned, it must not be false).
-   * @param token The token targeted by the call.
-   * @param data The call data (encoded using abi.encode or one of its variants).
-   */
-  function _callOptionalReturn(IERC20 token, bytes memory data) private {
-    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
-    // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
-    // the target address contains contract code and also asserts for success in the low-level call.
-
-    bytes memory returndata = address(token).functionCall(data, 'SafeERC20: low-level call failed');
-    if (returndata.length > 0) {
-      // Return data is optional
-      require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
-    }
-  }
-}
-
-interface IAaveDistributionManager {
-  function configureAssets(DistributionTypes.AssetConfigInput[] memory assetsConfigInput) external;
-}
-
-interface IStakedTokenV2 {
-  struct CooldownSnapshot {
-    uint40 timestamp;
-    uint216 amount;
-  }
-
-  event RewardsAccrued(address user, uint256 amount);
-  event RewardsClaimed(address indexed from, address indexed to, uint256 amount);
-  event Cooldown(address indexed user, uint256 amount);
-
-  /**
-   * @dev Allows staking a specified amount of STAKED_TOKEN
-   * @param to The address to receiving the shares
-   * @param amount The amount of assets to be staked
-   */
-  function stake(address to, uint256 amount) external;
-
-  /**
-   * @dev Redeems shares, and stop earning rewards
-   * @param to Address to redeem to
-   * @param amount Amount of shares to redeem
-   */
-  function redeem(address to, uint256 amount) external;
-
-  /**
-   * @dev Activates the cooldown period to unstake
-   * - It can't be called if the user is not staking
-   */
-  function cooldown() external;
-
-  /**
-   * @dev Claims an `amount` of `REWARD_TOKEN` to the address `to`
-   * @param to Address to send the claimed rewards
-   * @param amount Amount to stake
-   */
-  function claimRewards(address to, uint256 amount) external;
-
-  /**
-   * @dev Return the total rewards pending to claim by an staker
-   * @param staker The staker address
-   * @return The rewards
-   */
-  function getTotalRewardsBalance(address staker) external view returns (uint256);
-
-  /**
-   * @dev implements the permit function as for https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
-   * @param owner the owner of the funds
-   * @param spender the spender
-   * @param value the amount
-   * @param deadline the deadline timestamp, type(uint256).max for no deadline
-   * @param v signature param
-   * @param s signature param
-   * @param r signature param
-   */
-  function permit(
-    address owner,
-    address spender,
-    uint256 value,
-    uint256 deadline,
-    uint8 v,
-    bytes32 r,
-    bytes32 s
-  ) external;
-}
-
-// Contract modified from OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/EIP712.sol) to remove local
-// fallback storage variables, so contract does not affect on existing storage layout. This works as its used on contracts
-// that have name and revision < 32 bytes
-
-// OpenZeppelin Contracts (last updated v4.9.0) (utils/ShortStrings.sol)
+// OpenZeppelin Contracts (last updated v5.0.0) (utils/ShortStrings.sol)
 
-// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
+// OpenZeppelin Contracts (last updated v5.0.0) (utils/StorageSlot.sol)
 // This file was procedurally generated from scripts/generate/templates/StorageSlot.js.
 
 /**
@@ -1905,9 +2714,6 @@ interface IStakedTokenV2 {
  *     }
  * }
  * ```
- *
- * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
- * _Available since v4.9 for `string`, `bytes`._
  */
 library StorageSlot {
   struct AddressSlot {
@@ -2049,7 +2855,7 @@ type ShortString is bytes32;
  */
 library ShortStrings {
   // Used as an identifier for strings longer than 31 bytes.
-  bytes32 private constant _FALLBACK_SENTINEL =
+  bytes32 private constant FALLBACK_SENTINEL =
     0x00000000000000000000000000000000000000000000000000000000000000FF;
 
   error StringTooLong(string str);
@@ -2105,7 +2911,7 @@ library ShortStrings {
       return toShortString(value);
     } else {
       StorageSlot.getStringSlot(store).value = value;
-      return ShortString.wrap(_FALLBACK_SENTINEL);
+      return ShortString.wrap(FALLBACK_SENTINEL);
     }
   }
 
@@ -2116,7 +2922,7 @@ library ShortStrings {
     ShortString value,
     string storage store
   ) internal pure returns (string memory) {
-    if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
+    if (ShortString.unwrap(value) != FALLBACK_SENTINEL) {
       return toString(value);
     } else {
       return store;
@@ -2124,7 +2930,8 @@ library ShortStrings {
   }
 
   /**
-   * @dev Return the length of a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
+   * @dev Return the length of a string that was encoded to `ShortString` or written to storage using
+   * {setWithFallback}.
    *
    * WARNING: This will return the "byte length" of the string. This may not reflect the actual length in terms of
    * actual characters as the UTF-8 encoding of a single character can span over multiple bytes.
@@ -2133,7 +2940,7 @@ library ShortStrings {
     ShortString value,
     string storage store
   ) internal view returns (uint256) {
-    if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
+    if (ShortString.unwrap(value) != FALLBACK_SENTINEL) {
       return byteLength(value);
     } else {
       return bytes(store).length;
@@ -2141,7 +2948,7 @@ library ShortStrings {
   }
 }
 
-// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC5267.sol)
+// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC5267.sol)
 
 interface IERC5267 {
   /**
@@ -2170,9 +2977,10 @@ interface IERC5267 {
 /**
  * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
  *
- * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
- * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
- * they need in their contracts using a combination of `abi.encode` and `keccak256`.
+ * The encoding scheme specified in the EIP requires a domain separator and a hash of the typed structured data, whose
+ * encoding is very generic and therefore its implementation in Solidity is not feasible, thus this contract
+ * does not implement the encoding itself. Protocols need to implement the type-specific encoding they need in order to
+ * produce the hash of their typed data using a combination of `abi.encode` and `keccak256`.
  *
  * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
  * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
@@ -2185,17 +2993,15 @@ interface IERC5267 {
  * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
  *
  * NOTE: In the upgradeable version of this contract, the cached values will correspond to the address, and the domain
- * separator of the implementation contract. This will cause the `_domainSeparatorV4` function to always rebuild the
+ * separator of the implementation contract. This will cause the {_domainSeparatorV4} function to always rebuild the
  * separator from the immutable values, which is cheaper than accessing a cached version in cold storage.
  *
- * _Available since v3.4._
- *
- * @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
+ * @custom:oz-upgrades-unsafe-allow state-variable-immutable
  */
 abstract contract EIP712 is IERC5267 {
   using ShortStrings for *;
 
-  bytes32 private constant _TYPE_HASH =
+  bytes32 private constant TYPE_HASH =
     keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');
 
   // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
@@ -2209,6 +3015,8 @@ abstract contract EIP712 is IERC5267 {
 
   ShortString private immutable _name;
   ShortString private immutable _version;
+  string private _nameFallback;
+  string private _versionFallback;
 
   /**
    * @dev Initializes the domain separator and parameter caches.
@@ -2222,11 +3030,9 @@ abstract contract EIP712 is IERC5267 {
    * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
    * contract upgrade].
    */
-  /// @dev BGD: removed usage of fallback variables to not modify previous storage layout. As we know that the length of
-  ///           name and version will not be bigger than 32 bytes we use toShortString as there is no need to use the fallback system.
   constructor(string memory name, string memory version) {
-    _name = name.toShortString();
-    _version = version.toShortString();
+    _name = name.toShortStringWithFallback(_nameFallback);
+    _version = version.toShortStringWithFallback(_versionFallback);
     _hashedName = keccak256(bytes(name));
     _hashedVersion = keccak256(bytes(version));
 
@@ -2248,7 +3054,7 @@ abstract contract EIP712 is IERC5267 {
 
   function _buildDomainSeparator() private view returns (bytes32) {
     return
-      keccak256(abi.encode(_TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this)));
+      keccak256(abi.encode(TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this)));
   }
 
   /**
@@ -2267,13 +3073,11 @@ abstract contract EIP712 is IERC5267 {
    * ```
    */
   function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
-    return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
+    return MessageHashUtils.toTypedDataHash(_domainSeparatorV4(), structHash);
   }
 
   /**
-   * @dev See {EIP-5267}.
-   *
-   * _Available since v4.9._
+   * @dev See {IERC-5267}.
    */
   function eip712Domain()
     public
@@ -2305,13 +3109,10 @@ abstract contract EIP712 is IERC5267 {
    *
    * NOTE: By default this function reads _name which is an immutable value.
    * It only reads from storage if necessary (in case the value is too large to fit in a ShortString).
-   *
-   * _Available since v5.0._
    */
-  /// @dev BGD: we use toString instead of toStringWithFallback as we dont have fallback, to not modify previous storage layout
   // solhint-disable-next-line func-name-mixedcase
   function _EIP712Name() internal view returns (string memory) {
-    return _name.toString(); // _name.toStringWithFallback(_nameFallback);
+    return _name.toStringWithFallback(_nameFallback);
   }
 
   /**
@@ -2319,54 +3120,678 @@ abstract contract EIP712 is IERC5267 {
    *
    * NOTE: By default this function reads _version which is an immutable value.
    * It only reads from storage if necessary (in case the value is too large to fit in a ShortString).
-   *
-   * _Available since v5.0._
    */
-  /// @dev BGD: we use toString instead of toStringWithFallback as we dont have fallback, to not modify previous storage layout
   // solhint-disable-next-line func-name-mixedcase
   function _EIP712Version() internal view returns (string memory) {
-    return _version.toString();
+    return _version.toStringWithFallback(_versionFallback);
   }
 }
 
+// OpenZeppelin Contracts (last updated v5.0.0) (utils/Nonces.sol)
+
 /**
- * @title VersionedInitializable
+ * @dev Provides tracking nonces for addresses. Nonces will only increment.
+ */
+abstract contract Nonces {
+  /**
+   * @dev The nonce used for an `account` is not the expected current nonce.
+   */
+  error InvalidAccountNonce(address account, uint256 currentNonce);
+
+  mapping(address account => uint256) private _nonces;
+
+  /**
+   * @dev Returns the next unused nonce for an address.
+   */
+  function nonces(address owner) public view virtual returns (uint256) {
+    return _nonces[owner];
+  }
+
+  /**
+   * @dev Consumes a nonce.
+   *
+   * Returns the current value and increments nonce.
+   */
+  function _useNonce(address owner) internal virtual returns (uint256) {
+    // For each account, the nonce has an initial value of 0, can only be incremented by one, and cannot be
+    // decremented or reset. This guarantees that the nonce never overflows.
+    unchecked {
+      // It is important to do x++ and not ++x here.
+      return _nonces[owner]++;
+    }
+  }
+
+  /**
+   * @dev Same as {_useNonce} but checking that `nonce` is the next valid for `owner`.
+   */
+  function _useCheckedNonce(address owner, uint256 nonce) internal virtual {
+    uint256 current = _useNonce(owner);
+    if (nonce != current) {
+      revert InvalidAccountNonce(owner, current);
+    }
+  }
+}
+
+// Modified version of OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)
+// @dev modification is related to the structure of the user data adapted to the future governance use
+
+// @dev with addition of Initializable, so this implementation can be used only behind a proxy !!!
+
+// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)
+
+/**
+ * @dev Provides information about the current execution context, including the
+ * sender of the transaction and its data. While these are generally available
+ * via msg.sender and msg.data, they should not be accessed in such a direct
+ * manner, since when dealing with meta-transactions the account sending and
+ * paying for execution may not be the actual sender (as far as an application
+ * is concerned).
  *
- * @dev Helper contract to support initializer functions. To use it, replace
- * the constructor with a function that has the `initializer` modifier.
- * WARNING: Unlike constructors, initializer functions must be manually
- * invoked. This applies both to deploying an Initializable contract, as well
- * as extending an Initializable contract via inheritance.
- * WARNING: When used with inheritance, manual care must be taken to not invoke
- * a parent initializer twice, or ensure that all initializers are idempotent,
- * because this is not dealt with automatically as with constructors.
+ * This contract is only required for intermediate, library-like contracts.
+ */
+abstract contract Context {
+  function _msgSender() internal view virtual returns (address) {
+    return msg.sender;
+  }
+
+  function _msgData() internal view virtual returns (bytes calldata) {
+    return msg.data;
+  }
+
+  function _contextSuffixLength() internal view virtual returns (uint256) {
+    return 0;
+  }
+}
+
+// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
+
+/**
+ * @dev Standard ERC20 Errors
+ * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
+ */
+interface IERC20Errors {
+  /**
+   * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
+   * @param sender Address whose tokens are being transferred.
+   * @param balance Current balance for the interacting account.
+   * @param needed Minimum amount required to perform a transfer.
+   */
+  error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
+
+  /**
+   * @dev Indicates a failure with the token `sender`. Used in transfers.
+   * @param sender Address whose tokens are being transferred.
+   */
+  error ERC20InvalidSender(address sender);
+
+  /**
+   * @dev Indicates a failure with the token `receiver`. Used in transfers.
+   * @param receiver Address to which tokens are being transferred.
+   */
+  error ERC20InvalidReceiver(address receiver);
+
+  /**
+   * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
+   * @param spender Address that may be allowed to operate on tokens without being their owner.
+   * @param allowance Amount of tokens a `spender` is allowed to operate with.
+   * @param needed Minimum amount required to perform a transfer.
+   */
+  error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
+
+  /**
+   * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
+   * @param approver Address initiating an approval operation.
+   */
+  error ERC20InvalidApprover(address approver);
+
+  /**
+   * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
+   * @param spender Address that may be allowed to operate on tokens without being their owner.
+   */
+  error ERC20InvalidSpender(address spender);
+}
+
+/**
+ * @dev Standard ERC721 Errors
+ * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
+ */
+interface IERC721Errors {
+  /**
+   * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
+   * Used in balance queries.
+   * @param owner Address of the current owner of a token.
+   */
+  error ERC721InvalidOwner(address owner);
+
+  /**
+   * @dev Indicates a `tokenId` whose `owner` is the zero address.
+   * @param tokenId Identifier number of a token.
+   */
+  error ERC721NonexistentToken(uint256 tokenId);
+
+  /**
+   * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
+   * @param sender Address whose tokens are being transferred.
+   * @param tokenId Identifier number of a token.
+   * @param owner Address of the current owner of a token.
+   */
+  error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);
+
+  /**
+   * @dev Indicates a failure with the token `sender`. Used in transfers.
+   * @param sender Address whose tokens are being transferred.
+   */
+  error ERC721InvalidSender(address sender);
+
+  /**
+   * @dev Indicates a failure with the token `receiver`. Used in transfers.
+   * @param receiver Address to which tokens are being transferred.
+   */
+  error ERC721InvalidReceiver(address receiver);
+
+  /**
+   * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
+   * @param operator Address that may be allowed to operate on tokens without being their owner.
+   * @param tokenId Identifier number of a token.
+   */
+  error ERC721InsufficientApproval(address operator, uint256 tokenId);
+
+  /**
+   * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
+   * @param approver Address initiating an approval operation.
+   */
+  error ERC721InvalidApprover(address approver);
+
+  /**
+   * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
+   * @param operator Address that may be allowed to operate on tokens without being their owner.
+   */
+  error ERC721InvalidOperator(address operator);
+}
+
+/**
+ * @dev Standard ERC1155 Errors
+ * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
+ */
+interface IERC1155Errors {
+  /**
+   * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
+   * @param sender Address whose tokens are being transferred.
+   * @param balance Current balance for the interacting account.
+   * @param needed Minimum amount required to perform a transfer.
+   * @param tokenId Identifier number of a token.
+   */
+  error ERC1155InsufficientBalance(
+    address sender,
+    uint256 balance,
+    uint256 needed,
+    uint256 tokenId
+  );
+
+  /**
+   * @dev Indicates a failure with the token `sender`. Used in transfers.
+   * @param sender Address whose tokens are being transferred.
+   */
+  error ERC1155InvalidSender(address sender);
+
+  /**
+   * @dev Indicates a failure with the token `receiver`. Used in transfers.
+   * @param receiver Address to which tokens are being transferred.
+   */
+  error ERC1155InvalidReceiver(address receiver);
+
+  /**
+   * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
+   * @param operator Address that may be allowed to operate on tokens without being their owner.
+   * @param owner Address of the current owner of a token.
+   */
+  error ERC1155MissingApprovalForAll(address operator, address owner);
+
+  /**
+   * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
+   * @param approver Address initiating an approval operation.
+   */
+  error ERC1155InvalidApprover(address approver);
+
+  /**
+   * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
+   * @param operator Address that may be allowed to operate on tokens without being their owner.
+   */
+  error ERC1155InvalidOperator(address operator);
+
+  /**
+   * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
+   * Used in batch transfers.
+   * @param idsLength Length of the array of token identifiers
+   * @param valuesLength Length of the array of token amounts
+   */
+  error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
+}
+
+enum DelegationMode {
+  NO_DELEGATION,
+  VOTING_DELEGATED,
+  PROPOSITION_DELEGATED,
+  FULL_POWER_DELEGATED
+}
+
+/**
+ * @dev Implementation of the {IERC20} interface.
  *
- * @author Aave, inspired by the OpenZeppelin Initializable contract
+ * This implementation is agnostic to the way tokens are created. This means
+ * that a supply mechanism has to be added in a derived contract using {_mint}.
+ *
+ * TIP: For a detailed writeup see our guide
+ * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
+ * to implement supply mechanisms].
+ *
+ * The default value of {decimals} is 18. To change this, you should override
+ * this function so it returns a different value.
+ *
+ * We have followed general OpenZeppelin Contracts guidelines: functions revert
+ * instead returning `false` on failure. This behavior is nonetheless
+ * conventional and does not conflict with the expectations of ERC20
+ * applications.
+ *
+ * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
+ * This allows applications to reconstruct the allowance for all accounts just
+ * by listening to said events. Other implementations of the EIP may not emit
+ * these events, as it isn't required by the specification.
+ */
+abstract contract ERC20 is Context, Initializable, IERC20, IERC20Metadata, IERC20Errors {
+  struct DelegationAwareBalance {
+    uint104 balance; // maximum is 10T of 18 decimal asset
+    uint72 delegatedPropositionBalance;
+    uint72 delegatedVotingBalance;
+    DelegationMode delegationMode;
+  }
+
+  mapping(address => DelegationAwareBalance) internal _balances;
+
+  mapping(address account => mapping(address spender => uint256)) private _allowances;
+
+  uint256 private _totalSupply;
+
+  string private _name;
+  string private _symbol;
+
+  constructor() {
+    // @note using default oz version of Initializable with this call,
+    // to make further reviews and audits more simple
+    _disableInitializers();
+  }
+
+  /**
+   * @dev Sets the values for {name} and {symbol}.
+   *
+   * All two of these values are only be set once during the first initialization
+   */
+  function _initializeMetadata(
+    string calldata name_,
+    string calldata symbol_
+  ) internal initializer {
+    _name = name_;
+    _symbol = symbol_;
+  }
+
+  /**
+   * @dev Returns the name of the token.
+   */
+  function name() public view virtual returns (string memory) {
+    return _name;
+  }
+
+  /**
+   * @dev Returns the symbol of the token, usually a shorter version of the
+   * name.
+   */
+  function symbol() public view virtual returns (string memory) {
+    return _symbol;
+  }
+
+  /**
+   * @dev Returns the number of decimals used to get its user representation.
+   * For example, if `decimals` equals `2`, a balance of `505` tokens should
+   * be displayed to a user as `5.05` (`505 / 10 ** 2`).
+   *
+   * Tokens usually opt for a value of 18, imitating the relationship between
+   * Ether and Wei. This is the default value returned by this function, unless
+   * it's overridden.
+   *
+   * NOTE: This information is only used for _display_ purposes: it in
+   * no way affects any of the arithmetic of the contract, including
+   * {IERC20-balanceOf} and {IERC20-transfer}.
+   */
+  function decimals() public view virtual returns (uint8) {
+    return 18;
+  }
+
+  /**
+   * @dev See {IERC20-totalSupply}.
+   */
+  function totalSupply() public view virtual returns (uint256) {
+    return _totalSupply;
+  }
+
+  /**
+   * @dev See {IERC20-balanceOf}.
+   */
+  function balanceOf(address account) public view virtual returns (uint256) {
+    return _balances[account].balance;
+  }
+
+  /**
+   * @dev See {IERC20-transfer}.
+   *
+   * Requirements:
+   *
+   * - `to` cannot be the zero address.
+   * - the caller must have a balance of at least `value`.
+   */
+  function transfer(address to, uint256 value) public virtual returns (bool) {
+    address owner = _msgSender();
+    _transfer(owner, to, value);
+    return true;
+  }
+
+  /**
+   * @dev See {IERC20-allowance}.
+   */
+  function allowance(address owner, address spender) public view virtual returns (uint256) {
+    return _allowances[owner][spender];
+  }
+
+  /**
+   * @dev See {IERC20-approve}.
+   *
+   * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
+   * `transferFrom`. This is semantically equivalent to an infinite approval.
+   *
+   * Requirements:
+   *
+   * - `spender` cannot be the zero address.
+   */
+  function approve(address spender, uint256 value) public virtual returns (bool) {
+    address owner = _msgSender();
+    _approve(owner, spender, value);
+    return true;
+  }
+
+  /**
+   * @dev See {IERC20-transferFrom}.
+   *
+   * Emits an {Approval} event indicating the updated allowance. This is not
+   * required by the EIP. See the note at the beginning of {ERC20}.
+   *
+   * NOTE: Does not update the allowance if the current allowance
+   * is the maximum `uint256`.
+   *
+   * Requirements:
+   *
+   * - `from` and `to` cannot be the zero address.
+   * - `from` must have a balance of at least `value`.
+   * - the caller must have allowance for ``from``'s tokens of at least
+   * `value`.
+   */
+  function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
+    address spender = _msgSender();
+    _spendAllowance(from, spender, value);
+    _transfer(from, to, value);
+    return true;
+  }
+
+  /**
+   * @dev Moves a `value` amount of tokens from `from` to `to`.
+   *
+   * This internal function is equivalent to {transfer}, and can be used to
+   * e.g. implement automatic token fees, slashing mechanisms, etc.
+   *
+   * Emits a {Transfer} event.
+   *
+   * NOTE: This function is not virtual, {_update} should be overridden instead.
+   */
+  function _transfer(address from, address to, uint256 value) internal {
+    if (from == address(0)) {
+      revert ERC20InvalidSender(address(0));
+    }
+    if (to == address(0)) {
+      revert ERC20InvalidReceiver(address(0));
+    }
+    _update(from, to, value);
+  }
+
+  /**
+   * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
+   * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
+   * this function.
+   *
+   * Emits a {Transfer} event.
+   */
+  function _update(address from, address to, uint256 value) internal virtual {
+    if (from == address(0)) {
+      // Overflow check required: The rest of the code assumes that totalSupply never overflows
+      // @dev modified by BGD
+      _totalSupply = SafeCast.toUint104(_totalSupply + value);
+    } else {
+      uint104 fromBalance = _balances[from].balance;
+      if (fromBalance < value) {
+        revert ERC20InsufficientBalance(from, fromBalance, value);
+      }
+      unchecked {
+        // Overflow not possible: value <= fromBalance <= totalSupply.
+        _balances[from].balance = fromBalance - uint104(value);
+      }
+    }
+
+    if (to == address(0)) {
+      unchecked {
+        // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
+        _totalSupply -= value;
+      }
+    } else {
+      unchecked {
+        // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
+        _balances[to].balance += uint104(value);
+      }
+    }
+
+    emit Transfer(from, to, value);
+  }
+
+  /**
+   * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
+   * Relies on the `_update` mechanism
+   *
+   * Emits a {Transfer} event with `from` set to the zero address.
+   *
+   * NOTE: This function is not virtual, {_update} should be overridden instead.
+   */
+  function _mint(address account, uint256 value) internal {
+    if (account == address(0)) {
+      revert ERC20InvalidReceiver(address(0));
+    }
+    _update(address(0), account, value);
+  }
+
+  /**
+   * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
+   * Relies on the `_update` mechanism.
+   *
+   * Emits a {Transfer} event with `to` set to the zero address.
+   *
+   * NOTE: This function is not virtual, {_update} should be overridden instead
+   */
+  function _burn(address account, uint256 value) internal {
+    if (account == address(0)) {
+      revert ERC20InvalidSender(address(0));
+    }
+    _update(account, address(0), value);
+  }
+
+  /**
+   * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
+   *
+   * This internal function is equivalent to `approve`, and can be used to
+   * e.g. set automatic allowances for certain subsystems, etc.
+   *
+   * Emits an {Approval} event.
+   *
+   * Requirements:
+   *
+   * - `owner` cannot be the zero address.
+   * - `spender` cannot be the zero address.
+   *
+   * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
+   */
+  function _approve(address owner, address spender, uint256 value) internal {
+    _approve(owner, spender, value, true);
+  }
+
+  /**
+   * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
+   *
+   * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
+   * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
+   * `Approval` event during `transferFrom` operations.
+   *
+   * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
+   * true using the following override:
+   * ```
+   * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
+   *     super._approve(owner, spender, value, true);
+   * }
+   * ```
+   *
+   * Requirements are the same as {_approve}.
+   */
+  function _approve(
+    address owner,
+    address spender,
+    uint256 value,
+    bool emitEvent
+  ) internal virtual {
+    if (owner == address(0)) {
+      revert ERC20InvalidApprover(address(0));
+    }
+    if (spender == address(0)) {
+      revert ERC20InvalidSpender(address(0));
+    }
+    _allowances[owner][spender] = value;
+    if (emitEvent) {
+      emit Approval(owner, spender, value);
+    }
+  }
+
+  /**
+   * @dev Updates `owner` s allowance for `spender` based on spent `value`.
+   *
+   * Does not update the allowance value in case of infinite allowance.
+   * Revert if not enough allowance is available.
+   *
+   * Does not emit an {Approval} event.
+   */
+  function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
+    uint256 currentAllowance = allowance(owner, spender);
+    if (currentAllowance != type(uint256).max) {
+      if (currentAllowance < value) {
+        revert ERC20InsufficientAllowance(spender, currentAllowance, value);
+      }
+      unchecked {
+        _approve(owner, spender, currentAllowance - value, false);
+      }
+    }
+  }
+}
+
+/**
+ * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
+ * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
+ *
+ * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
+ * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
+ * need to send a transaction, and thus is not required to hold Ether at all.
  */
-abstract contract VersionedInitializable {
+abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712, Nonces {
+  bytes32 private constant PERMIT_TYPEHASH =
+    keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');
+
+  /**
+   * @dev Permit deadline has expired.
+   */
+  error ERC2612ExpiredSignature(uint256 deadline);
+
+  /**
+   * @dev Mismatched signature.
+   */
+  error ERC2612InvalidSigner(address signer, address owner);
+
   /**
-   * @dev Indicates that the contract has been initialized.
+   * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
+   *
+   * It's a good idea to use the same `name` that is defined as the ERC20 token name.
    */
-  uint256 internal lastInitializedRevision = 0;
+  constructor(string memory name) EIP712(name, '1') {}
 
   /**
-   * @dev Modifier to use in the initializer function of a contract.
+   * @inheritdoc IERC20Permit
    */
-  modifier initializer() {
-    uint256 revision = getRevision();
-    require(revision > lastInitializedRevision, 'Contract instance has already been initialized');
+  function permit(
+    address owner,
+    address spender,
+    uint256 value,
+    uint256 deadline,
+    uint8 v,
+    bytes32 r,
+    bytes32 s
+  ) public virtual {
+    if (block.timestamp > deadline) {
+      revert ERC2612ExpiredSignature(deadline);
+    }
 
-    lastInitializedRevision = revision;
+    bytes32 structHash = keccak256(
+      abi.encode(PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline)
+    );
 
-    _;
+    bytes32 hash = _hashTypedDataV4(structHash);
+
+    address signer = ECDSA.recover(hash, v, r, s);
+    if (signer != owner) {
+      revert ERC2612InvalidSigner(signer, owner);
+    }
+
+    _approve(owner, spender, value);
   }
 
-  /// @dev returns the revision number of the contract.
-  /// Needs to be defined in the inherited class as a constant.
-  function getRevision() internal pure virtual returns (uint256);
+  /**
+   * @inheritdoc IERC20Permit
+   */
+  function nonces(
+    address owner
+  ) public view virtual override(IERC20Permit, Nonces) returns (uint256) {
+    return super.nonces(owner);
+  }
 
-  // Reserved storage space to allow for layout changes in the future.
-  uint256[50] private ______gap;
+  /**
+   * @inheritdoc IERC20Permit
+   */
+  // solhint-disable-next-line func-name-mixedcase
+  function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
+    return _domainSeparatorV4();
+  }
+}
+
+library DistributionTypes {
+  struct AssetConfigInput {
+    uint128 emissionPerSecond;
+    uint256 totalStaked;
+    address underlyingAsset;
+  }
+
+  struct UserStakeInput {
+    address underlyingAsset;
+    uint256 stakedByUser;
+    uint256 totalStaked;
+  }
 }
 
 /**
@@ -2382,23 +3807,34 @@ contract AaveDistributionManager {
     mapping(address => uint256) users;
   }
 
-  uint256 public immutable DISTRIBUTION_END;
-
   address public immutable EMISSION_MANAGER;
 
   uint8 public constant PRECISION = 18;
 
   mapping(address => AssetData) public assets;
+  uint256 public distributionEnd;
 
   event AssetConfigUpdated(address indexed asset, uint256 emission);
   event AssetIndexUpdated(address indexed asset, uint256 index);
   event UserIndexUpdated(address indexed user, address indexed asset, uint256 index);
+  event DistributionEndChanged(uint256 endTimestamp);
 
-  constructor(address emissionManager, uint256 distributionDuration) {
-    DISTRIBUTION_END = block.timestamp + distributionDuration;
+  modifier onlyEmissionManager() {
+    require(msg.sender == EMISSION_MANAGER, 'CALLER_NOT_EMISSION_MANAGER');
+    _;
+  }
+
+  constructor(address emissionManager) {
     EMISSION_MANAGER = emissionManager;
   }
 
+  function setDistributionEnd(uint256 newDistributionEnd) external onlyEmissionManager {
+    require(newDistributionEnd >= block.timestamp, 'END_MUST_BE_GE_NOW');
+
+    distributionEnd = newDistributionEnd;
+    emit DistributionEndChanged(newDistributionEnd);
+  }
+
   /**
    * @dev Configures the distribution of rewards for a list of assets
    * @param assetsConfigInput The list of configurations to apply
@@ -2575,17 +4011,18 @@ contract AaveDistributionManager {
     uint128 lastUpdateTimestamp,
     uint256 totalBalance
   ) internal view returns (uint256) {
+    uint256 cachedDistributionEnd = distributionEnd;
     if (
       emissionPerSecond == 0 ||
       totalBalance == 0 ||
       lastUpdateTimestamp == block.timestamp ||
-      lastUpdateTimestamp >= DISTRIBUTION_END
+      lastUpdateTimestamp >= cachedDistributionEnd
     ) {
       return currentIndex;
     }
 
-    uint256 currentTimestamp = block.timestamp > DISTRIBUTION_END
-      ? DISTRIBUTION_END
+    uint256 currentTimestamp = block.timestamp > cachedDistributionEnd
+      ? cachedDistributionEnd
       : block.timestamp;
     uint256 timeDelta = currentTimestamp - lastUpdateTimestamp;
     return
@@ -2604,389 +4041,95 @@ contract AaveDistributionManager {
 }
 
 /**
- * @title MOCK CONTRACT TO KEEP VALID STORAGE LAYOUT
- * @dev WAS including snapshots of balances on transfer-related actions
- * @author BGD Labs
+ * @title RoleManager
+ * @notice Generic role manager to manage slashing and cooldown admin in StakedAaveV3.
+ *         It implements a claim admin role pattern to safely migrate between different admin addresses
+ * @author Aave
  **/
-abstract contract GovernancePowerWithSnapshot {
-  uint256[3] private __________DEPRECATED_GOV_V2_PART;
-}
+contract RoleManager {
+  struct InitAdmin {
+    uint256 role;
+    address admin;
+  }
 
-// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
+  mapping(uint256 => address) private _admins;
+  mapping(uint256 => address) private _pendingAdmins;
 
-/**
- * @dev Provides information about the current execution context, including the
- * sender of the transaction and its data. While these are generally available
- * via msg.sender and msg.data, they should not be accessed in such a direct
- * manner, since when dealing with meta-transactions the account sending and
- * paying for execution may not be the actual sender (as far as an application
- * is concerned).
- *
- * This contract is only required for intermediate, library-like contracts.
- */
-abstract contract Context {
-  function _msgSender() internal view virtual returns (address) {
-    return msg.sender;
-  }
+  event PendingAdminChanged(address indexed newPendingAdmin, uint256 role);
+  event RoleClaimed(address indexed newAdmin, uint256 role);
 
-  function _msgData() internal view virtual returns (bytes calldata) {
-    return msg.data;
+  modifier onlyRoleAdmin(uint256 role) {
+    require(_admins[role] == msg.sender, 'CALLER_NOT_ROLE_ADMIN');
+    _;
   }
-}
 
-// Inspired by OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)
-abstract contract BaseAaveToken is Context, IERC20Metadata {
-  struct DelegationAwareBalance {
-    uint104 balance;
-    uint72 delegatedPropositionBalance;
-    uint72 delegatedVotingBalance;
-    DelegationMode delegationMode;
+  modifier onlyPendingRoleAdmin(uint256 role) {
+    require(_pendingAdmins[role] == msg.sender, 'CALLER_NOT_PENDING_ROLE_ADMIN');
+    _;
   }
 
-  mapping(address => DelegationAwareBalance) internal _balances;
-
-  mapping(address => mapping(address => uint256)) internal _allowances;
-
-  uint256 internal _totalSupply;
-
-  string internal _name;
-  string internal _symbol;
-
-  // @dev DEPRECATED
-  // kept for backwards compatibility with old storage layout
-  uint8 private ______DEPRECATED_OLD_ERC20_DECIMALS;
-
   /**
-   * @dev Returns the name of the token.
-   */
-  function name() public view virtual override returns (string memory) {
-    return _name;
+   * @dev returns the admin associated with the specific role
+   * @param role the role associated with the admin being returned
+   **/
+  function getAdmin(uint256 role) public view returns (address) {
+    return _admins[role];
   }
 
   /**
-   * @dev Returns the symbol of the token, usually a shorter version of the
-   * name.
-   */
-  function symbol() public view virtual override returns (string memory) {
-    return _symbol;
-  }
-
-  function decimals() public view virtual override returns (uint8) {
-    return 18;
-  }
-
-  function totalSupply() public view virtual override returns (uint256) {
-    return _totalSupply;
-  }
-
-  function balanceOf(address account) public view virtual override returns (uint256) {
-    return _balances[account].balance;
-  }
-
-  function transfer(address to, uint256 amount) public virtual override returns (bool) {
-    address owner = _msgSender();
-    _transfer(owner, to, amount);
-    return true;
-  }
-
-  function allowance(
-    address owner,
-    address spender
-  ) public view virtual override returns (uint256) {
-    return _allowances[owner][spender];
-  }
-
-  function approve(address spender, uint256 amount) public virtual override returns (bool) {
-    address owner = _msgSender();
-    _approve(owner, spender, amount);
-    return true;
-  }
-
-  function transferFrom(
-    address from,
-    address to,
-    uint256 amount
-  ) public virtual override returns (bool) {
-    address spender = _msgSender();
-    _spendAllowance(from, spender, amount);
-    _transfer(from, to, amount);
-    return true;
-  }
-
-  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
-    address owner = _msgSender();
-    _approve(owner, spender, _allowances[owner][spender] + addedValue);
-    return true;
-  }
-
-  function decreaseAllowance(
-    address spender,
-    uint256 subtractedValue
-  ) public virtual returns (bool) {
-    address owner = _msgSender();
-    uint256 currentAllowance = _allowances[owner][spender];
-    require(currentAllowance >= subtractedValue, 'ERC20: decreased allowance below zero');
-    unchecked {
-      _approve(owner, spender, currentAllowance - subtractedValue);
-    }
-
-    return true;
-  }
-
-  function _transfer(address from, address to, uint256 amount) internal virtual {
-    require(from != address(0), 'ERC20: transfer from the zero address');
-    require(to != address(0), 'ERC20: transfer to the zero address');
-
-    if (from != to) {
-      uint104 fromBalanceBefore = _balances[from].balance;
-      uint104 toBalanceBefore = _balances[to].balance;
-
-      require(fromBalanceBefore >= amount, 'ERC20: transfer amount exceeds balance');
-      unchecked {
-        _balances[from].balance = fromBalanceBefore - uint104(amount);
-      }
-
-      _balances[to].balance = toBalanceBefore + uint104(amount);
-
-      _afterTokenTransfer(from, to, fromBalanceBefore, toBalanceBefore, amount);
-    }
-    emit Transfer(from, to, amount);
-  }
-
-  function _approve(address owner, address spender, uint256 amount) internal virtual {
-    require(owner != address(0), 'ERC20: approve from the zero address');
-    require(spender != address(0), 'ERC20: approve to the zero address');
-
-    _allowances[owner][spender] = amount;
-    emit Approval(owner, spender, amount);
-  }
-
-  function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
-    uint256 currentAllowance = allowance(owner, spender);
-    if (currentAllowance != type(uint256).max) {
-      require(currentAllowance >= amount, 'ERC20: insufficient allowance');
-      unchecked {
-        _approve(owner, spender, currentAllowance - amount);
-      }
-    }
+   * @dev returns the pending admin associated with the specific role
+   * @param role the role associated with the pending admin being returned
+   **/
+  function getPendingAdmin(uint256 role) public view returns (address) {
+    return _pendingAdmins[role];
   }
 
   /**
-   * @dev after token transfer hook, added for delegation system
-   * @param from token sender
-   * @param to token recipient
-   * @param fromBalanceBefore balance of the sender before transfer
-   * @param toBalanceBefore balance of the recipient before transfer
-   * @param amount amount of tokens sent
+   * @dev sets the pending admin for a specific role
+   * @param role the role associated with the new pending admin being set
+   * @param newPendingAdmin the address of the new pending admin
    **/
-  function _afterTokenTransfer(
-    address from,
-    address to,
-    uint256 fromBalanceBefore,
-    uint256 toBalanceBefore,
-    uint256 amount
-  ) internal virtual {}
-}
-
-/**
- * @title BaseMintableAaveToken
- * @author BGD labs
- * @notice extension for BaseAaveToken adding mint/burn and transfer hooks
- */
-contract BaseMintableAaveToken is BaseAaveToken {
-  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
-   * the total supply.
-   *
-   * Emits a {Transfer} event with `from` set to the zero address.
-   *
-   * Requirements:
-   *
-   * - `account` cannot be the zero address.
-   */
-  function _mint(address account, uint104 amount) internal virtual {
-    require(account != address(0), 'ERC20: mint to the zero address');
-
-    uint104 balanceBefore = _balances[account].balance;
-    _totalSupply += amount;
-    _balances[account].balance += amount;
-    emit Transfer(address(0), account, amount);
-
-    _afterTokenTransfer(address(0), account, 0, balanceBefore, amount);
+  function setPendingAdmin(uint256 role, address newPendingAdmin) public onlyRoleAdmin(role) {
+    _pendingAdmins[role] = newPendingAdmin;
+    emit PendingAdminChanged(newPendingAdmin, role);
   }
 
   /**
-   * @dev Destroys `amount` tokens from `account`, reducing the
-   * total supply.
-   *
-   * Emits a {Transfer} event with `to` set to the zero address.
-   *
-   * Requirements:
-   *
-   * - `account` cannot be the zero address.
-   * - `account` must have at least `amount` tokens.
-   */
-  function _burn(address account, uint104 amount) internal virtual {
-    require(account != address(0), 'ERC20: burn from the zero address');
-
-    uint104 accountBalance = _balances[account].balance;
-    require(accountBalance >= amount, 'ERC20: burn amount exceeds balance');
-    unchecked {
-      _balances[account].balance = accountBalance - amount;
-      // Overflow not possible: amount <= accountBalance <= totalSupply.
-      _totalSupply -= amount;
+   * @dev allows the caller to become a specific role admin
+   * @param role the role associated with the admin claiming the new role
+   **/
+  function claimRoleAdmin(uint256 role) external onlyPendingRoleAdmin(role) {
+    _admins[role] = msg.sender;
+    _pendingAdmins[role] = address(0);
+    emit RoleClaimed(msg.sender, role);
+  }
+
+  function _initAdmins(InitAdmin[] memory initAdmins) internal {
+    for (uint256 i = 0; i < initAdmins.length; i++) {
+      require(
+        _admins[initAdmins[i].role] == address(0) && initAdmins[i].admin != address(0),
+        'ADMIN_CANNOT_BE_INITIALIZED'
+      );
+      _admins[initAdmins[i].role] = initAdmins[i].admin;
+      emit RoleClaimed(initAdmins[i].admin, initAdmins[i].role);
     }
-
-    emit Transfer(account, address(0), amount);
-
-    _afterTokenTransfer(account, address(0), accountBalance, 0, amount);
   }
 }
 
-/**
- * @title StakedTokenV2
- * @notice Contract to stake Aave token, tokenize the position and get rewards, inheriting from a distribution manager contract
- * @author BGD Labs
- */
-abstract contract StakedTokenV2 is
-  IStakedTokenV2,
-  BaseMintableAaveToken,
-  GovernancePowerWithSnapshot,
-  VersionedInitializable,
-  AaveDistributionManager,
-  EIP712
-{
-  using SafeERC20 for IERC20;
-
-  IERC20 public immutable STAKED_TOKEN;
-  IERC20 public immutable REWARD_TOKEN;
-
-  /// @notice Seconds available to redeem once the cooldown period is fulfilled
-  uint256 public immutable UNSTAKE_WINDOW;
-
-  /// @notice Address to pull from the rewards, needs to have approved this contract
-  address public immutable REWARDS_VAULT;
-
-  mapping(address => uint256) public stakerRewardsToClaim;
-  mapping(address => CooldownSnapshot) public stakersCooldowns;
-
-  /// @dev End of Storage layout from StakedToken v1
-  uint256[5] private ______DEPRECATED_FROM_STK_AAVE_V2;
-
-  bytes32 public constant PERMIT_TYPEHASH =
-    keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');
-
-  /// @dev owner => next valid nonce to submit with permit()
-  mapping(address => uint256) public _nonces;
-
-  constructor(
-    IERC20 stakedToken,
-    IERC20 rewardToken,
-    uint256 unstakeWindow,
-    address rewardsVault,
-    address emissionManager,
-    uint128 distributionDuration
-  ) AaveDistributionManager(emissionManager, distributionDuration) EIP712('Staked Aave', '2') {
-    STAKED_TOKEN = stakedToken;
-    REWARD_TOKEN = rewardToken;
-    UNSTAKE_WINDOW = unstakeWindow;
-    REWARDS_VAULT = rewardsVault;
-  }
-
-  /**
-   * @notice Get the domain separator for the token
-   * @dev Return cached value if chainId matches cache, otherwise recomputes separator
-   * @return The domain separator of the token at current chain
-   */
-  function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
-    return _domainSeparatorV4();
-  }
-
-  /// @dev maintained for backwards compatibility. See EIP712 _EIP712Version
-  function EIP712_REVISION() external view returns (bytes memory) {
-    return bytes(_EIP712Version());
-  }
-
-  /// @inheritdoc IStakedTokenV2
-  function stake(address onBehalfOf, uint256 amount) external virtual override;
-
-  /// @inheritdoc IStakedTokenV2
-  function redeem(address to, uint256 amount) external virtual override;
-
-  /// @inheritdoc IStakedTokenV2
-  function cooldown() external virtual override;
-
-  /// @inheritdoc IStakedTokenV2
-  function claimRewards(address to, uint256 amount) external virtual override;
-
-  /// @inheritdoc IStakedTokenV2
-  function getTotalRewardsBalance(address staker) external view returns (uint256) {
-    DistributionTypes.UserStakeInput[]
-      memory userStakeInputs = new DistributionTypes.UserStakeInput[](1);
-    userStakeInputs[0] = DistributionTypes.UserStakeInput({
-      underlyingAsset: address(this),
-      stakedByUser: balanceOf(staker),
-      totalStaked: totalSupply()
-    });
-    return stakerRewardsToClaim[staker] + _getUnclaimedRewards(staker, userStakeInputs);
-  }
-
-  /// @inheritdoc IStakedTokenV2
-  function permit(
-    address owner,
-    address spender,
-    uint256 value,
-    uint256 deadline,
-    uint8 v,
-    bytes32 r,
-    bytes32 s
-  ) external {
-    require(owner != address(0), 'INVALID_OWNER');
-    //solium-disable-next-line
-    require(block.timestamp <= deadline, 'INVALID_EXPIRATION');
-    uint256 currentValidNonce = _nonces[owner];
-    bytes32 digest = _hashTypedDataV4(
-      keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, currentValidNonce, deadline))
-    );
+interface IAaveDistributionManager {
+  function configureAssets(DistributionTypes.AssetConfigInput[] memory assetsConfigInput) external;
+}
 
-    require(owner == ECDSA.recover(digest, v, r, s), 'INVALID_SIGNATURE');
-    unchecked {
-      _nonces[owner] = currentValidNonce + 1;
-    }
-    _approve(owner, spender, value);
+interface IStakeToken is IAaveDistributionManager {
+  struct CooldownSnapshot {
+    uint40 timestamp;
+    uint216 amount;
   }
 
-  /**
-   * @dev Updates the user state related with his accrued rewards
-   * @param user Address of the user
-   * @param userBalance The current balance of the user
-   * @param updateStorage Boolean flag used to update or not the stakerRewardsToClaim of the user
-   * @return The unclaimed rewards that were added to the total accrued
-   */
-  function _updateCurrentUnclaimedRewards(
-    address user,
-    uint256 userBalance,
-    bool updateStorage
-  ) internal returns (uint256) {
-    uint256 accruedRewards = _updateUserAssetInternal(
-      user,
-      address(this),
-      userBalance,
-      totalSupply()
-    );
-    uint256 unclaimedRewards = stakerRewardsToClaim[user] + accruedRewards;
-
-    if (accruedRewards != 0) {
-      if (updateStorage) {
-        stakerRewardsToClaim[user] = unclaimedRewards;
-      }
-      emit RewardsAccrued(user, accruedRewards);
-    }
-
-    return unclaimedRewards;
-  }
-}
+  event RewardsAccrued(address user, uint256 amount);
+  event RewardsClaimed(address indexed from, address indexed to, uint256 amount);
+  event Cooldown(address indexed user, uint256 amount);
 
-interface IStakedTokenV3 is IStakedTokenV2 {
   event Staked(address indexed from, address indexed to, uint256 assets, uint256 shares);
   event Redeem(address indexed from, address indexed to, uint256 assets, uint256 shares);
   event MaxSlashablePercentageChanged(uint256 newPercentage);
@@ -2997,6 +4140,40 @@ interface IStakedTokenV3 is IStakedTokenV2 {
   event FundsReturned(uint256 amount);
   event SlashingSettled();
 
+  /**
+   * @dev Allows staking a specified amount of STAKED_TOKEN
+   * @param to The address to receiving the shares
+   * @param amount The amount of assets to be staked
+   */
+  function stake(address to, uint256 amount) external;
+
+  /**
+   * @dev Redeems shares, and stop earning rewards
+   * @param to Address to redeem to
+   * @param amount Amount of shares to redeem
+   */
+  function redeem(address to, uint256 amount) external;
+
+  /**
+   * @dev Activates the cooldown period to unstake
+   * - It can't be called if the user is not staking
+   */
+  function cooldown() external;
+
+  /**
+   * @dev Claims an `amount` of `REWARD_TOKEN` to the address `to`
+   * @param to Address to send the claimed rewards
+   * @param amount Amount to stake
+   */
+  function claimRewards(address to, uint256 amount) external;
+
+  /**
+   * @dev Return the total rewards pending to claim by an staker
+   * @param staker The staker address
+   * @return The rewards
+   */
+  function getTotalRewardsBalance(address staker) external view returns (uint256);
+
   /**
    * @dev Allows staking a certain amount of STAKED_TOKEN with gasless approvals (permit)
    * @param amount The amount to be staked
@@ -3050,12 +4227,6 @@ interface IStakedTokenV3 is IStakedTokenV2 {
    */
   function getCooldownSeconds() external view returns (uint256);
 
-  /**
-   * @dev Getter of the cooldown seconds
-   * @return cooldownSeconds the amount of seconds between starting the cooldown and being able to redeem
-   */
-  function COOLDOWN_SECONDS() external view returns (uint256); // @deprecated
-
   /**
    * @dev Setter of cooldown seconds
    * Can only be called by the cooldown admin
@@ -3182,1240 +4353,7 @@ library PercentageMath {
   }
 }
 
-/**
- * @title RoleManager
- * @notice Generic role manager to manage slashing and cooldown admin in StakedAaveV3.
- *         It implements a claim admin role pattern to safely migrate between different admin addresses
- * @author Aave
- **/
-contract RoleManager {
-  struct InitAdmin {
-    uint256 role;
-    address admin;
-  }
-
-  mapping(uint256 => address) private _admins;
-  mapping(uint256 => address) private _pendingAdmins;
-
-  event PendingAdminChanged(address indexed newPendingAdmin, uint256 role);
-  event RoleClaimed(address indexed newAdmin, uint256 role);
-
-  modifier onlyRoleAdmin(uint256 role) {
-    require(_admins[role] == msg.sender, 'CALLER_NOT_ROLE_ADMIN');
-    _;
-  }
-
-  modifier onlyPendingRoleAdmin(uint256 role) {
-    require(_pendingAdmins[role] == msg.sender, 'CALLER_NOT_PENDING_ROLE_ADMIN');
-    _;
-  }
-
-  /**
-   * @dev returns the admin associated with the specific role
-   * @param role the role associated with the admin being returned
-   **/
-  function getAdmin(uint256 role) public view returns (address) {
-    return _admins[role];
-  }
-
-  /**
-   * @dev returns the pending admin associated with the specific role
-   * @param role the role associated with the pending admin being returned
-   **/
-  function getPendingAdmin(uint256 role) public view returns (address) {
-    return _pendingAdmins[role];
-  }
-
-  /**
-   * @dev sets the pending admin for a specific role
-   * @param role the role associated with the new pending admin being set
-   * @param newPendingAdmin the address of the new pending admin
-   **/
-  function setPendingAdmin(uint256 role, address newPendingAdmin) public onlyRoleAdmin(role) {
-    _pendingAdmins[role] = newPendingAdmin;
-    emit PendingAdminChanged(newPendingAdmin, role);
-  }
-
-  /**
-   * @dev allows the caller to become a specific role admin
-   * @param role the role associated with the admin claiming the new role
-   **/
-  function claimRoleAdmin(uint256 role) external onlyPendingRoleAdmin(role) {
-    _admins[role] = msg.sender;
-    _pendingAdmins[role] = address(0);
-    emit RoleClaimed(msg.sender, role);
-  }
-
-  function _initAdmins(InitAdmin[] memory initAdmins) internal {
-    for (uint256 i = 0; i < initAdmins.length; i++) {
-      require(
-        _admins[initAdmins[i].role] == address(0) && initAdmins[i].admin != address(0),
-        'ADMIN_CANNOT_BE_INITIALIZED'
-      );
-      _admins[initAdmins[i].role] = initAdmins[i].admin;
-      emit RoleClaimed(initAdmins[i].admin, initAdmins[i].role);
-    }
-  }
-}
-
-// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
-// This file was procedurally generated from scripts/generate/templates/SafeCast.js.
-
-/**
- * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
- * checks.
- *
- * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
- * easily result in undesired exploitation or bugs, since developers usually
- * assume that overflows raise errors. `SafeCast` restores this intuition by
- * reverting the transaction when such an operation overflows.
- *
- * Using this library instead of the unchecked operations eliminates an entire
- * class of bugs, so it's recommended to use it always.
- *
- * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
- * all math on `uint256` and `int256` and then downcasting.
- */
-library SafeCast {
-  /**
-   * @dev Returns the downcasted uint248 from uint256, reverting on
-   * overflow (when the input is greater than largest uint248).
-   *
-   * Counterpart to Solidity's `uint248` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 248 bits
-   *
-   * _Available since v4.7._
-   */
-  function toUint248(uint256 value) internal pure returns (uint248) {
-    require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
-    return uint248(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint240 from uint256, reverting on
-   * overflow (when the input is greater than largest uint240).
-   *
-   * Counterpart to Solidity's `uint240` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 240 bits
-   *
-   * _Available since v4.7._
-   */
-  function toUint240(uint256 value) internal pure returns (uint240) {
-    require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
-    return uint240(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint232 from uint256, reverting on
-   * overflow (when the input is greater than largest uint232).
-   *
-   * Counterpart to Solidity's `uint232` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 232 bits
-   *
-   * _Available since v4.7._
-   */
-  function toUint232(uint256 value) internal pure returns (uint232) {
-    require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
-    return uint232(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint224 from uint256, reverting on
-   * overflow (when the input is greater than largest uint224).
-   *
-   * Counterpart to Solidity's `uint224` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 224 bits
-   *
-   * _Available since v4.2._
-   */
-  function toUint224(uint256 value) internal pure returns (uint224) {
-    require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
-    return uint224(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint216 from uint256, reverting on
-   * overflow (when the input is greater than largest uint216).
-   *
-   * Counterpart to Solidity's `uint216` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 216 bits
-   *
-   * _Available since v4.7._
-   */
-  function toUint216(uint256 value) internal pure returns (uint216) {
-    require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
-    return uint216(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint208 from uint256, reverting on
-   * overflow (when the input is greater than largest uint208).
-   *
-   * Counterpart to Solidity's `uint208` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 208 bits
-   *
-   * _Available since v4.7._
-   */
-  function toUint208(uint256 value) internal pure returns (uint208) {
-    require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
-    return uint208(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint200 from uint256, reverting on
-   * overflow (when the input is greater than largest uint200).
-   *
-   * Counterpart to Solidity's `uint200` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 200 bits
-   *
-   * _Available since v4.7._
-   */
-  function toUint200(uint256 value) internal pure returns (uint200) {
-    require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
-    return uint200(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint192 from uint256, reverting on
-   * overflow (when the input is greater than largest uint192).
-   *
-   * Counterpart to Solidity's `uint192` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 192 bits
-   *
-   * _Available since v4.7._
-   */
-  function toUint192(uint256 value) internal pure returns (uint192) {
-    require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
-    return uint192(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint184 from uint256, reverting on
-   * overflow (when the input is greater than largest uint184).
-   *
-   * Counterpart to Solidity's `uint184` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 184 bits
-   *
-   * _Available since v4.7._
-   */
-  function toUint184(uint256 value) internal pure returns (uint184) {
-    require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
-    return uint184(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint176 from uint256, reverting on
-   * overflow (when the input is greater than largest uint176).
-   *
-   * Counterpart to Solidity's `uint176` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 176 bits
-   *
-   * _Available since v4.7._
-   */
-  function toUint176(uint256 value) internal pure returns (uint176) {
-    require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
-    return uint176(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint168 from uint256, reverting on
-   * overflow (when the input is greater than largest uint168).
-   *
-   * Counterpart to Solidity's `uint168` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 168 bits
-   *
-   * _Available since v4.7._
-   */
-  function toUint168(uint256 value) internal pure returns (uint168) {
-    require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
-    return uint168(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint160 from uint256, reverting on
-   * overflow (when the input is greater than largest uint160).
-   *
-   * Counterpart to Solidity's `uint160` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 160 bits
-   *
-   * _Available since v4.7._
-   */
-  function toUint160(uint256 value) internal pure returns (uint160) {
-    require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
-    return uint160(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint152 from uint256, reverting on
-   * overflow (when the input is greater than largest uint152).
-   *
-   * Counterpart to Solidity's `uint152` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 152 bits
-   *
-   * _Available since v4.7._
-   */
-  function toUint152(uint256 value) internal pure returns (uint152) {
-    require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
-    return uint152(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint144 from uint256, reverting on
-   * overflow (when the input is greater than largest uint144).
-   *
-   * Counterpart to Solidity's `uint144` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 144 bits
-   *
-   * _Available since v4.7._
-   */
-  function toUint144(uint256 value) internal pure returns (uint144) {
-    require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
-    return uint144(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint136 from uint256, reverting on
-   * overflow (when the input is greater than largest uint136).
-   *
-   * Counterpart to Solidity's `uint136` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 136 bits
-   *
-   * _Available since v4.7._
-   */
-  function toUint136(uint256 value) internal pure returns (uint136) {
-    require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
-    return uint136(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint128 from uint256, reverting on
-   * overflow (when the input is greater than largest uint128).
-   *
-   * Counterpart to Solidity's `uint128` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 128 bits
-   *
-   * _Available since v2.5._
-   */
-  function toUint128(uint256 value) internal pure returns (uint128) {
-    require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
-    return uint128(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint120 from uint256, reverting on
-   * overflow (when the input is greater than largest uint120).
-   *
-   * Counterpart to Solidity's `uint120` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 120 bits
-   *
-   * _Available since v4.7._
-   */
-  function toUint120(uint256 value) internal pure returns (uint120) {
-    require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
-    return uint120(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint112 from uint256, reverting on
-   * overflow (when the input is greater than largest uint112).
-   *
-   * Counterpart to Solidity's `uint112` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 112 bits
-   *
-   * _Available since v4.7._
-   */
-  function toUint112(uint256 value) internal pure returns (uint112) {
-    require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
-    return uint112(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint104 from uint256, reverting on
-   * overflow (when the input is greater than largest uint104).
-   *
-   * Counterpart to Solidity's `uint104` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 104 bits
-   *
-   * _Available since v4.7._
-   */
-  function toUint104(uint256 value) internal pure returns (uint104) {
-    require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
-    return uint104(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint96 from uint256, reverting on
-   * overflow (when the input is greater than largest uint96).
-   *
-   * Counterpart to Solidity's `uint96` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 96 bits
-   *
-   * _Available since v4.2._
-   */
-  function toUint96(uint256 value) internal pure returns (uint96) {
-    require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
-    return uint96(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint88 from uint256, reverting on
-   * overflow (when the input is greater than largest uint88).
-   *
-   * Counterpart to Solidity's `uint88` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 88 bits
-   *
-   * _Available since v4.7._
-   */
-  function toUint88(uint256 value) internal pure returns (uint88) {
-    require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
-    return uint88(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint80 from uint256, reverting on
-   * overflow (when the input is greater than largest uint80).
-   *
-   * Counterpart to Solidity's `uint80` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 80 bits
-   *
-   * _Available since v4.7._
-   */
-  function toUint80(uint256 value) internal pure returns (uint80) {
-    require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
-    return uint80(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint72 from uint256, reverting on
-   * overflow (when the input is greater than largest uint72).
-   *
-   * Counterpart to Solidity's `uint72` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 72 bits
-   *
-   * _Available since v4.7._
-   */
-  function toUint72(uint256 value) internal pure returns (uint72) {
-    require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
-    return uint72(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint64 from uint256, reverting on
-   * overflow (when the input is greater than largest uint64).
-   *
-   * Counterpart to Solidity's `uint64` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 64 bits
-   *
-   * _Available since v2.5._
-   */
-  function toUint64(uint256 value) internal pure returns (uint64) {
-    require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
-    return uint64(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint56 from uint256, reverting on
-   * overflow (when the input is greater than largest uint56).
-   *
-   * Counterpart to Solidity's `uint56` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 56 bits
-   *
-   * _Available since v4.7._
-   */
-  function toUint56(uint256 value) internal pure returns (uint56) {
-    require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
-    return uint56(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint48 from uint256, reverting on
-   * overflow (when the input is greater than largest uint48).
-   *
-   * Counterpart to Solidity's `uint48` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 48 bits
-   *
-   * _Available since v4.7._
-   */
-  function toUint48(uint256 value) internal pure returns (uint48) {
-    require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
-    return uint48(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint40 from uint256, reverting on
-   * overflow (when the input is greater than largest uint40).
-   *
-   * Counterpart to Solidity's `uint40` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 40 bits
-   *
-   * _Available since v4.7._
-   */
-  function toUint40(uint256 value) internal pure returns (uint40) {
-    require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
-    return uint40(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint32 from uint256, reverting on
-   * overflow (when the input is greater than largest uint32).
-   *
-   * Counterpart to Solidity's `uint32` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 32 bits
-   *
-   * _Available since v2.5._
-   */
-  function toUint32(uint256 value) internal pure returns (uint32) {
-    require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
-    return uint32(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint24 from uint256, reverting on
-   * overflow (when the input is greater than largest uint24).
-   *
-   * Counterpart to Solidity's `uint24` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 24 bits
-   *
-   * _Available since v4.7._
-   */
-  function toUint24(uint256 value) internal pure returns (uint24) {
-    require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
-    return uint24(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint16 from uint256, reverting on
-   * overflow (when the input is greater than largest uint16).
-   *
-   * Counterpart to Solidity's `uint16` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 16 bits
-   *
-   * _Available since v2.5._
-   */
-  function toUint16(uint256 value) internal pure returns (uint16) {
-    require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
-    return uint16(value);
-  }
-
-  /**
-   * @dev Returns the downcasted uint8 from uint256, reverting on
-   * overflow (when the input is greater than largest uint8).
-   *
-   * Counterpart to Solidity's `uint8` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 8 bits
-   *
-   * _Available since v2.5._
-   */
-  function toUint8(uint256 value) internal pure returns (uint8) {
-    require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
-    return uint8(value);
-  }
-
-  /**
-   * @dev Converts a signed int256 into an unsigned uint256.
-   *
-   * Requirements:
-   *
-   * - input must be greater than or equal to 0.
-   *
-   * _Available since v3.0._
-   */
-  function toUint256(int256 value) internal pure returns (uint256) {
-    require(value >= 0, 'SafeCast: value must be positive');
-    return uint256(value);
-  }
-
-  /**
-   * @dev Returns the downcasted int248 from int256, reverting on
-   * overflow (when the input is less than smallest int248 or
-   * greater than largest int248).
-   *
-   * Counterpart to Solidity's `int248` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 248 bits
-   *
-   * _Available since v4.7._
-   */
-  function toInt248(int256 value) internal pure returns (int248 downcasted) {
-    downcasted = int248(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int240 from int256, reverting on
-   * overflow (when the input is less than smallest int240 or
-   * greater than largest int240).
-   *
-   * Counterpart to Solidity's `int240` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 240 bits
-   *
-   * _Available since v4.7._
-   */
-  function toInt240(int256 value) internal pure returns (int240 downcasted) {
-    downcasted = int240(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int232 from int256, reverting on
-   * overflow (when the input is less than smallest int232 or
-   * greater than largest int232).
-   *
-   * Counterpart to Solidity's `int232` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 232 bits
-   *
-   * _Available since v4.7._
-   */
-  function toInt232(int256 value) internal pure returns (int232 downcasted) {
-    downcasted = int232(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int224 from int256, reverting on
-   * overflow (when the input is less than smallest int224 or
-   * greater than largest int224).
-   *
-   * Counterpart to Solidity's `int224` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 224 bits
-   *
-   * _Available since v4.7._
-   */
-  function toInt224(int256 value) internal pure returns (int224 downcasted) {
-    downcasted = int224(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int216 from int256, reverting on
-   * overflow (when the input is less than smallest int216 or
-   * greater than largest int216).
-   *
-   * Counterpart to Solidity's `int216` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 216 bits
-   *
-   * _Available since v4.7._
-   */
-  function toInt216(int256 value) internal pure returns (int216 downcasted) {
-    downcasted = int216(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int208 from int256, reverting on
-   * overflow (when the input is less than smallest int208 or
-   * greater than largest int208).
-   *
-   * Counterpart to Solidity's `int208` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 208 bits
-   *
-   * _Available since v4.7._
-   */
-  function toInt208(int256 value) internal pure returns (int208 downcasted) {
-    downcasted = int208(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int200 from int256, reverting on
-   * overflow (when the input is less than smallest int200 or
-   * greater than largest int200).
-   *
-   * Counterpart to Solidity's `int200` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 200 bits
-   *
-   * _Available since v4.7._
-   */
-  function toInt200(int256 value) internal pure returns (int200 downcasted) {
-    downcasted = int200(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int192 from int256, reverting on
-   * overflow (when the input is less than smallest int192 or
-   * greater than largest int192).
-   *
-   * Counterpart to Solidity's `int192` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 192 bits
-   *
-   * _Available since v4.7._
-   */
-  function toInt192(int256 value) internal pure returns (int192 downcasted) {
-    downcasted = int192(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int184 from int256, reverting on
-   * overflow (when the input is less than smallest int184 or
-   * greater than largest int184).
-   *
-   * Counterpart to Solidity's `int184` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 184 bits
-   *
-   * _Available since v4.7._
-   */
-  function toInt184(int256 value) internal pure returns (int184 downcasted) {
-    downcasted = int184(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int176 from int256, reverting on
-   * overflow (when the input is less than smallest int176 or
-   * greater than largest int176).
-   *
-   * Counterpart to Solidity's `int176` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 176 bits
-   *
-   * _Available since v4.7._
-   */
-  function toInt176(int256 value) internal pure returns (int176 downcasted) {
-    downcasted = int176(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int168 from int256, reverting on
-   * overflow (when the input is less than smallest int168 or
-   * greater than largest int168).
-   *
-   * Counterpart to Solidity's `int168` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 168 bits
-   *
-   * _Available since v4.7._
-   */
-  function toInt168(int256 value) internal pure returns (int168 downcasted) {
-    downcasted = int168(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int160 from int256, reverting on
-   * overflow (when the input is less than smallest int160 or
-   * greater than largest int160).
-   *
-   * Counterpart to Solidity's `int160` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 160 bits
-   *
-   * _Available since v4.7._
-   */
-  function toInt160(int256 value) internal pure returns (int160 downcasted) {
-    downcasted = int160(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int152 from int256, reverting on
-   * overflow (when the input is less than smallest int152 or
-   * greater than largest int152).
-   *
-   * Counterpart to Solidity's `int152` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 152 bits
-   *
-   * _Available since v4.7._
-   */
-  function toInt152(int256 value) internal pure returns (int152 downcasted) {
-    downcasted = int152(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int144 from int256, reverting on
-   * overflow (when the input is less than smallest int144 or
-   * greater than largest int144).
-   *
-   * Counterpart to Solidity's `int144` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 144 bits
-   *
-   * _Available since v4.7._
-   */
-  function toInt144(int256 value) internal pure returns (int144 downcasted) {
-    downcasted = int144(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int136 from int256, reverting on
-   * overflow (when the input is less than smallest int136 or
-   * greater than largest int136).
-   *
-   * Counterpart to Solidity's `int136` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 136 bits
-   *
-   * _Available since v4.7._
-   */
-  function toInt136(int256 value) internal pure returns (int136 downcasted) {
-    downcasted = int136(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int128 from int256, reverting on
-   * overflow (when the input is less than smallest int128 or
-   * greater than largest int128).
-   *
-   * Counterpart to Solidity's `int128` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 128 bits
-   *
-   * _Available since v3.1._
-   */
-  function toInt128(int256 value) internal pure returns (int128 downcasted) {
-    downcasted = int128(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int120 from int256, reverting on
-   * overflow (when the input is less than smallest int120 or
-   * greater than largest int120).
-   *
-   * Counterpart to Solidity's `int120` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 120 bits
-   *
-   * _Available since v4.7._
-   */
-  function toInt120(int256 value) internal pure returns (int120 downcasted) {
-    downcasted = int120(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int112 from int256, reverting on
-   * overflow (when the input is less than smallest int112 or
-   * greater than largest int112).
-   *
-   * Counterpart to Solidity's `int112` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 112 bits
-   *
-   * _Available since v4.7._
-   */
-  function toInt112(int256 value) internal pure returns (int112 downcasted) {
-    downcasted = int112(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int104 from int256, reverting on
-   * overflow (when the input is less than smallest int104 or
-   * greater than largest int104).
-   *
-   * Counterpart to Solidity's `int104` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 104 bits
-   *
-   * _Available since v4.7._
-   */
-  function toInt104(int256 value) internal pure returns (int104 downcasted) {
-    downcasted = int104(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int96 from int256, reverting on
-   * overflow (when the input is less than smallest int96 or
-   * greater than largest int96).
-   *
-   * Counterpart to Solidity's `int96` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 96 bits
-   *
-   * _Available since v4.7._
-   */
-  function toInt96(int256 value) internal pure returns (int96 downcasted) {
-    downcasted = int96(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int88 from int256, reverting on
-   * overflow (when the input is less than smallest int88 or
-   * greater than largest int88).
-   *
-   * Counterpart to Solidity's `int88` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 88 bits
-   *
-   * _Available since v4.7._
-   */
-  function toInt88(int256 value) internal pure returns (int88 downcasted) {
-    downcasted = int88(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int80 from int256, reverting on
-   * overflow (when the input is less than smallest int80 or
-   * greater than largest int80).
-   *
-   * Counterpart to Solidity's `int80` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 80 bits
-   *
-   * _Available since v4.7._
-   */
-  function toInt80(int256 value) internal pure returns (int80 downcasted) {
-    downcasted = int80(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int72 from int256, reverting on
-   * overflow (when the input is less than smallest int72 or
-   * greater than largest int72).
-   *
-   * Counterpart to Solidity's `int72` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 72 bits
-   *
-   * _Available since v4.7._
-   */
-  function toInt72(int256 value) internal pure returns (int72 downcasted) {
-    downcasted = int72(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int64 from int256, reverting on
-   * overflow (when the input is less than smallest int64 or
-   * greater than largest int64).
-   *
-   * Counterpart to Solidity's `int64` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 64 bits
-   *
-   * _Available since v3.1._
-   */
-  function toInt64(int256 value) internal pure returns (int64 downcasted) {
-    downcasted = int64(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int56 from int256, reverting on
-   * overflow (when the input is less than smallest int56 or
-   * greater than largest int56).
-   *
-   * Counterpart to Solidity's `int56` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 56 bits
-   *
-   * _Available since v4.7._
-   */
-  function toInt56(int256 value) internal pure returns (int56 downcasted) {
-    downcasted = int56(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int48 from int256, reverting on
-   * overflow (when the input is less than smallest int48 or
-   * greater than largest int48).
-   *
-   * Counterpart to Solidity's `int48` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 48 bits
-   *
-   * _Available since v4.7._
-   */
-  function toInt48(int256 value) internal pure returns (int48 downcasted) {
-    downcasted = int48(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int40 from int256, reverting on
-   * overflow (when the input is less than smallest int40 or
-   * greater than largest int40).
-   *
-   * Counterpart to Solidity's `int40` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 40 bits
-   *
-   * _Available since v4.7._
-   */
-  function toInt40(int256 value) internal pure returns (int40 downcasted) {
-    downcasted = int40(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int32 from int256, reverting on
-   * overflow (when the input is less than smallest int32 or
-   * greater than largest int32).
-   *
-   * Counterpart to Solidity's `int32` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 32 bits
-   *
-   * _Available since v3.1._
-   */
-  function toInt32(int256 value) internal pure returns (int32 downcasted) {
-    downcasted = int32(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int24 from int256, reverting on
-   * overflow (when the input is less than smallest int24 or
-   * greater than largest int24).
-   *
-   * Counterpart to Solidity's `int24` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 24 bits
-   *
-   * _Available since v4.7._
-   */
-  function toInt24(int256 value) internal pure returns (int24 downcasted) {
-    downcasted = int24(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int16 from int256, reverting on
-   * overflow (when the input is less than smallest int16 or
-   * greater than largest int16).
-   *
-   * Counterpart to Solidity's `int16` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 16 bits
-   *
-   * _Available since v3.1._
-   */
-  function toInt16(int256 value) internal pure returns (int16 downcasted) {
-    downcasted = int16(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
-  }
-
-  /**
-   * @dev Returns the downcasted int8 from int256, reverting on
-   * overflow (when the input is less than smallest int8 or
-   * greater than largest int8).
-   *
-   * Counterpart to Solidity's `int8` operator.
-   *
-   * Requirements:
-   *
-   * - input must fit into 8 bits
-   *
-   * _Available since v3.1._
-   */
-  function toInt8(int256 value) internal pure returns (int8 downcasted) {
-    downcasted = int8(value);
-    require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
-  }
-
-  /**
-   * @dev Converts an unsigned uint256 into a signed int256.
-   *
-   * Requirements:
-   *
-   * - input must be less than or equal to maxInt256.
-   *
-   * _Available since v3.0._
-   */
-  function toInt256(uint256 value) internal pure returns (int256) {
-    // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
-    require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
-    return int256(value);
-  }
-}
-
-interface IERC20WithPermit is IERC20 {
-  function permit(
-    address owner,
-    address spender,
-    uint256 value,
-    uint256 deadline,
-    uint8 v,
-    bytes32 r,
-    bytes32 s
-  ) external;
-}
-
-/**
- * @title StakedTokenV3
- * @notice Contract to stake Aave token, tokenize the position and get rewards, inheriting from a distribution manager contract
- * @author BGD Labs
- */
-contract StakedTokenV3 is
-  StakedTokenV2,
-  IStakedTokenV3,
-  RoleManager,
-  IAaveDistributionManager,
-  BaseDelegation
-{
+contract StakeToken is ERC20Permit, AaveDistributionManager, RoleManager, IStakeToken {
   using SafeERC20 for IERC20;
   using PercentageMath for uint256;
   using SafeCast for uint256;
@@ -4431,8 +4369,18 @@ contract StakedTokenV3 is
   // as returnFunds can be called permissionless an attacker could spam returnFunds(1) to produce exchangeRate snapshots making voting expensive
   uint256 public immutable LOWER_BOUND;
 
-  // Reserved storage space to allow for layout changes in the future.
-  uint256[6] private ______gap;
+  IERC20 public immutable STAKED_TOKEN;
+  IERC20 public immutable REWARD_TOKEN;
+
+  /// @notice Seconds available to redeem once the cooldown period is fulfilled
+  uint256 public immutable UNSTAKE_WINDOW;
+
+  /// @notice Address to pull from the rewards, needs to have approved this contract
+  address public immutable REWARDS_VAULT;
+
+  mapping(address => uint256) public stakerRewardsToClaim;
+  mapping(address => CooldownSnapshot) public stakersCooldowns;
+
   /// @notice Seconds between starting cooldown and being able to withdraw
   uint256 internal _cooldownSeconds;
   /// @notice The maximum amount of funds that can be slashed at any given time
@@ -4458,56 +4406,32 @@ contract StakedTokenV3 is
   }
 
   constructor(
+    string memory name,
     IERC20 stakedToken,
     IERC20 rewardToken,
     uint256 unstakeWindow,
     address rewardsVault,
-    address emissionManager,
-    uint128 distributionDuration
-  )
-    StakedTokenV2(
-      stakedToken,
-      rewardToken,
-      unstakeWindow,
-      rewardsVault,
-      emissionManager,
-      distributionDuration
-    )
-  {
-    // brick initialize
-    lastInitializedRevision = REVISION();
+    address emissionManager
+  ) ERC20Permit(name) AaveDistributionManager(emissionManager) {
     uint256 decimals = IERC20Metadata(address(stakedToken)).decimals();
     LOWER_BOUND = 10 ** decimals;
+    STAKED_TOKEN = stakedToken;
+    REWARD_TOKEN = rewardToken;
+    UNSTAKE_WINDOW = unstakeWindow;
+    REWARDS_VAULT = rewardsVault;
   }
 
-  /**
-   * @dev returns the revision of the implementation contract
-   * @return The revision
-   */
-  function REVISION() public pure virtual returns (uint256) {
-    return 4;
-  }
-
-  /**
-   * @dev returns the revision of the implementation contract
-   * @return The revision
-   */
-  function getRevision() internal pure virtual override returns (uint256) {
-    return REVISION();
-  }
-
-  /**
-   * @dev Called by the proxy contract
-   */
-  function initialize() external virtual initializer {}
-
-  function _initialize(
+  function initialize(
+    string calldata name,
+    string calldata symbol,
     address slashingAdmin,
     address cooldownPauseAdmin,
     address claimHelper,
     uint256 maxSlashablePercentage,
     uint256 cooldownSeconds
-  ) internal {
+  ) external virtual initializer {
+    _initializeMetadata(name, symbol);
+
     InitAdmin[] memory initAdmins = new InitAdmin[](3);
     initAdmins[0] = InitAdmin(SLASH_ADMIN_ROLE, slashingAdmin);
     initAdmins[1] = InitAdmin(COOLDOWN_ADMIN_ROLE, cooldownPauseAdmin);
@@ -4523,9 +4447,7 @@ contract StakedTokenV3 is
   /// @inheritdoc IAaveDistributionManager
   function configureAssets(
     DistributionTypes.AssetConfigInput[] memory assetsConfigInput
-  ) external override {
-    require(msg.sender == EMISSION_MANAGER, 'ONLY_EMISSION_MANAGER');
-
+  ) external onlyEmissionManager {
     for (uint256 i = 0; i < assetsConfigInput.length; i++) {
       assetsConfigInput[i].totalStaked = totalSupply();
     }
@@ -4533,26 +4455,26 @@ contract StakedTokenV3 is
     _configureAssets(assetsConfigInput);
   }
 
-  /// @inheritdoc IStakedTokenV3
+  /// @inheritdoc IStakeToken
   function previewStake(uint256 assets) public view returns (uint256) {
     return (assets * _currentExchangeRate) / EXCHANGE_RATE_UNIT;
   }
 
-  /// @inheritdoc IStakedTokenV2
-  function stake(address to, uint256 amount) external override(IStakedTokenV2, StakedTokenV2) {
+  /// @inheritdoc IStakeToken
+  function stake(address to, uint256 amount) external {
     _stake(msg.sender, to, amount);
   }
 
-  /// @inheritdoc IStakedTokenV3
+  /// @inheritdoc IStakeToken
   function stakeWithPermit(
     uint256 amount,
     uint256 deadline,
     uint8 v,
     bytes32 r,
     bytes32 s
-  ) external override {
+  ) external {
     try
-      IERC20WithPermit(address(STAKED_TOKEN)).permit(
+      IERC20Permit(address(STAKED_TOKEN)).permit(
         msg.sender,
         address(this),
         amount,
@@ -4569,94 +4491,69 @@ contract StakedTokenV3 is
     _stake(msg.sender, msg.sender, amount);
   }
 
-  /// @inheritdoc IStakedTokenV2
-  function cooldown() external override(IStakedTokenV2, StakedTokenV2) {
+  /// @inheritdoc IStakeToken
+  function cooldown() external {
     _cooldown(msg.sender);
   }
 
-  /// @inheritdoc IStakedTokenV3
-  function cooldownOnBehalfOf(address from) external override onlyClaimHelper {
+  /// @inheritdoc IStakeToken
+  function cooldownOnBehalfOf(address from) external onlyClaimHelper {
     _cooldown(from);
   }
 
-  function _cooldown(address from) internal {
-    uint256 amount = balanceOf(from);
-    require(amount != 0, 'INVALID_BALANCE_ON_COOLDOWN');
-    stakersCooldowns[from] = CooldownSnapshot({
-      timestamp: uint40(block.timestamp),
-      amount: uint216(amount)
-    });
-
-    emit Cooldown(from, amount);
-  }
-
-  /// @inheritdoc IStakedTokenV2
-  function redeem(address to, uint256 amount) external override(IStakedTokenV2, StakedTokenV2) {
+  /// @inheritdoc IStakeToken
+  function redeem(address to, uint256 amount) external {
     _redeem(msg.sender, to, amount.toUint104());
   }
 
-  /// @inheritdoc IStakedTokenV3
-  function redeemOnBehalf(
-    address from,
-    address to,
-    uint256 amount
-  ) external override onlyClaimHelper {
+  /// @inheritdoc IStakeToken
+  function redeemOnBehalf(address from, address to, uint256 amount) external onlyClaimHelper {
     _redeem(from, to, amount.toUint104());
   }
 
-  /// @inheritdoc IStakedTokenV2
-  function claimRewards(
-    address to,
-    uint256 amount
-  ) external override(IStakedTokenV2, StakedTokenV2) {
+  /// @inheritdoc IStakeToken
+  function claimRewards(address to, uint256 amount) external {
     _claimRewards(msg.sender, to, amount);
   }
 
-  /// @inheritdoc IStakedTokenV3
+  /// @inheritdoc IStakeToken
   function claimRewardsOnBehalf(
     address from,
     address to,
     uint256 amount
-  ) external override onlyClaimHelper returns (uint256) {
+  ) external onlyClaimHelper returns (uint256) {
     return _claimRewards(from, to, amount);
   }
 
-  /// @inheritdoc IStakedTokenV3
-  function claimRewardsAndRedeem(
-    address to,
-    uint256 claimAmount,
-    uint256 redeemAmount
-  ) external override {
+  /// @inheritdoc IStakeToken
+  function claimRewardsAndRedeem(address to, uint256 claimAmount, uint256 redeemAmount) external {
     _claimRewards(msg.sender, to, claimAmount);
     _redeem(msg.sender, to, redeemAmount.toUint104());
   }
 
-  /// @inheritdoc IStakedTokenV3
+  /// @inheritdoc IStakeToken
   function claimRewardsAndRedeemOnBehalf(
     address from,
     address to,
     uint256 claimAmount,
     uint256 redeemAmount
-  ) external override onlyClaimHelper {
+  ) external onlyClaimHelper {
     _claimRewards(from, to, claimAmount);
     _redeem(from, to, redeemAmount.toUint104());
   }
 
-  /// @inheritdoc IStakedTokenV3
-  function getExchangeRate() public view override returns (uint216) {
+  /// @inheritdoc IStakeToken
+  function getExchangeRate() public view returns (uint216) {
     return _currentExchangeRate;
   }
 
-  /// @inheritdoc IStakedTokenV3
-  function previewRedeem(uint256 shares) public view override returns (uint256) {
+  /// @inheritdoc IStakeToken
+  function previewRedeem(uint256 shares) public view returns (uint256) {
     return (EXCHANGE_RATE_UNIT * shares) / _currentExchangeRate;
   }
 
-  /// @inheritdoc IStakedTokenV3
-  function slash(
-    address destination,
-    uint256 amount
-  ) external override onlySlashingAdmin returns (uint256) {
+  /// @inheritdoc IStakeToken
+  function slash(address destination, uint256 amount) external onlySlashingAdmin returns (uint256) {
     require(!inPostSlashingPeriod, 'PREVIOUS_SLASHING_NOT_SETTLED');
     require(amount > 0, 'ZERO_AMOUNT');
     uint256 currentShares = totalSupply();
@@ -4678,8 +4575,8 @@ contract StakedTokenV3 is
     return amount;
   }
 
-  /// @inheritdoc IStakedTokenV3
-  function returnFunds(uint256 amount) external override {
+  /// @inheritdoc IStakeToken
+  function returnFunds(uint256 amount) external {
     require(amount >= LOWER_BOUND, 'AMOUNT_LT_MINIMUM');
     uint256 currentShares = totalSupply();
     require(currentShares >= LOWER_BOUND, 'SHARES_LT_MINIMUM');
@@ -4690,35 +4587,53 @@ contract StakedTokenV3 is
     emit FundsReturned(amount);
   }
 
-  /// @inheritdoc IStakedTokenV3
-  function settleSlashing() external override onlySlashingAdmin {
+  /// @inheritdoc IStakeToken
+  function settleSlashing() external onlySlashingAdmin {
     inPostSlashingPeriod = false;
     emit SlashingSettled();
   }
 
-  /// @inheritdoc IStakedTokenV3
-  function setMaxSlashablePercentage(uint256 percentage) external override onlySlashingAdmin {
+  /// @inheritdoc IStakeToken
+  function setMaxSlashablePercentage(uint256 percentage) external onlySlashingAdmin {
     _setMaxSlashablePercentage(percentage);
   }
 
-  /// @inheritdoc IStakedTokenV3
-  function getMaxSlashablePercentage() external view override returns (uint256) {
+  /// @inheritdoc IStakeToken
+  function getMaxSlashablePercentage() external view returns (uint256) {
     return _maxSlashablePercentage;
   }
 
-  /// @inheritdoc IStakedTokenV3
+  /// @inheritdoc IStakeToken
   function setCooldownSeconds(uint256 cooldownSeconds) external onlyCooldownAdmin {
     _setCooldownSeconds(cooldownSeconds);
   }
 
-  /// @inheritdoc IStakedTokenV3
+  /// @inheritdoc IStakeToken
   function getCooldownSeconds() external view returns (uint256) {
     return _cooldownSeconds;
   }
 
-  /// @inheritdoc IStakedTokenV3
-  function COOLDOWN_SECONDS() external view returns (uint256) {
-    return _cooldownSeconds;
+  /// @inheritdoc IStakeToken
+  function getTotalRewardsBalance(address staker) external view returns (uint256) {
+    DistributionTypes.UserStakeInput[]
+      memory userStakeInputs = new DistributionTypes.UserStakeInput[](1);
+    userStakeInputs[0] = DistributionTypes.UserStakeInput({
+      underlyingAsset: address(this),
+      stakedByUser: balanceOf(staker),
+      totalStaked: totalSupply()
+    });
+    return stakerRewardsToClaim[staker] + _getUnclaimedRewards(staker, userStakeInputs);
+  }
+
+  function _cooldown(address from) internal {
+    uint256 amount = balanceOf(from);
+    require(amount != 0, 'INVALID_BALANCE_ON_COOLDOWN');
+    stakersCooldowns[from] = CooldownSnapshot({
+      timestamp: uint40(block.timestamp),
+      amount: uint216(amount)
+    });
+
+    emit Cooldown(from, amount);
   }
 
   /**
@@ -4761,31 +4676,6 @@ contract StakedTokenV3 is
     return amountToClaim;
   }
 
-  /**
-   * @dev Claims an `amount` of `REWARD_TOKEN` and stakes.
-   * @param from The address of the from from which to claim
-   * @param to Address to stake to
-   * @param amount Amount to claim
-   * @return amount claimed
-   */
-  function _claimRewardsAndStakeOnBehalf(
-    address from,
-    address to,
-    uint256 amount
-  ) internal returns (uint256) {
-    require(REWARD_TOKEN == STAKED_TOKEN, 'REWARD_TOKEN_IS_NOT_STAKED_TOKEN');
-
-    uint256 userUpdatedRewards = _updateCurrentUnclaimedRewards(from, balanceOf(from), true);
-    uint256 amountToClaim = (amount > userUpdatedRewards) ? userUpdatedRewards : amount;
-
-    if (amountToClaim != 0) {
-      _claimRewards(from, address(this), amountToClaim);
-      _stake(address(this), to, amountToClaim);
-    }
-
-    return amountToClaim;
-  }
-
   /**
    * @dev Allows staking a specified amount of STAKED_TOKEN
    * @param to The address to receiving the shares
@@ -4811,10 +4701,10 @@ contract StakedTokenV3 is
 
     uint256 sharesToMint = previewStake(amount);
 
-    STAKED_TOKEN.safeTransferFrom(from, address(this), amount);
-
     _mint(to, sharesToMint.toUint104());
 
+    STAKED_TOKEN.safeTransferFrom(from, address(this), amount);
+
     emit Staked(from, to, amount, sharesToMint);
   }
 
@@ -4845,20 +4735,10 @@ contract StakedTokenV3 is
 
     uint256 amountToRedeem = (amount > maxRedeemable) ? maxRedeemable : amount;
 
-    _updateCurrentUnclaimedRewards(from, balanceOfFrom, true);
-
     uint256 underlyingToRedeem = previewRedeem(amountToRedeem);
 
     _burn(from, amountToRedeem.toUint104());
 
-    if (cooldownSnapshot.timestamp != 0) {
-      if (cooldownSnapshot.amount - amountToRedeem == 0) {
-        delete stakersCooldowns[from];
-      } else {
-        stakersCooldowns[from].amount = stakersCooldowns[from].amount - amountToRedeem.toUint184();
-      }
-    }
-
     IERC20(STAKED_TOKEN).safeTransfer(to, underlyingToRedeem);
 
     emit Redeem(from, to, underlyingToRedeem, amountToRedeem);
@@ -4888,81 +4768,68 @@ contract StakedTokenV3 is
     return (((totalShares * EXCHANGE_RATE_UNIT) + totalAssets - 1) / totalAssets).toUint216();
   }
 
-  function _transfer(address from, address to, uint256 amount) internal override {
-    uint256 balanceOfFrom = balanceOf(from);
-    // Sender
-    _updateCurrentUnclaimedRewards(from, balanceOfFrom, true);
+  /**
+   * @dev Updates the user state related with his accrued rewards
+   * @param user Address of the user
+   * @param userBalance The current balance of the user
+   * @param updateStorage Boolean flag used to update or not the stakerRewardsToClaim of the user
+   * @return The unclaimed rewards that were added to the total accrued
+   */
+  function _updateCurrentUnclaimedRewards(
+    address user,
+    uint256 userBalance,
+    bool updateStorage
+  ) internal returns (uint256) {
+    uint256 accruedRewards = _updateUserAssetInternal(
+      user,
+      address(this),
+      userBalance,
+      totalSupply()
+    );
+    uint256 unclaimedRewards = stakerRewardsToClaim[user] + accruedRewards;
 
-    // Recipient
-    if (from != to) {
+    if (accruedRewards != 0) {
+      if (updateStorage) {
+        stakerRewardsToClaim[user] = unclaimedRewards;
+      }
+      emit RewardsAccrued(user, accruedRewards);
+    }
+
+    return unclaimedRewards;
+  }
+
+  function _update(address from, address to, uint256 amount) internal override {
+    // stake & transfer
+    if (to != address(0)) {
       uint256 balanceOfTo = balanceOf(to);
       _updateCurrentUnclaimedRewards(to, balanceOfTo, true);
-
+    }
+    // redeem & transfer
+    if (from != address(0) && from != to) {
+      uint256 balanceOfFrom = balanceOf(from);
+      // Sender
+      _updateCurrentUnclaimedRewards(from, balanceOfFrom, true);
       CooldownSnapshot memory previousSenderCooldown = stakersCooldowns[from];
       if (previousSenderCooldown.timestamp != 0) {
-        // if cooldown was set and whole balance of sender was transferred - clear cooldown
-        if (balanceOfFrom == amount) {
-          delete stakersCooldowns[from];
-        } else if (balanceOfFrom - amount < previousSenderCooldown.amount) {
-          stakersCooldowns[from].amount = uint216(balanceOfFrom - amount);
+        // update to 0 means redeem
+        // this is based on the assumption that erc20 forbids transfer to 0
+        if (to == address(0)) {
+          if (previousSenderCooldown.amount <= amount) {
+            delete stakersCooldowns[from];
+          } else {
+            stakersCooldowns[from].amount = uint216(previousSenderCooldown.amount - amount);
+          }
+        } else {
+          uint256 balanceAfter = balanceOfFrom - amount;
+          if (balanceAfter == 0) {
+            delete stakersCooldowns[from];
+          } else if (balanceAfter < previousSenderCooldown.amount) {
+            stakersCooldowns[from].amount = uint216(balanceAfter);
+          }
         }
       }
     }
 
-    super._transfer(from, to, amount);
-  }
-
-  function _afterTokenTransfer(
-    address from,
-    address to,
-    uint256 fromBalanceBefore,
-    uint256 toBalanceBefore,
-    uint256 amount
-  ) internal virtual override {
-    _delegationChangeOnTransfer(from, to, fromBalanceBefore, toBalanceBefore, amount);
-  }
-
-  function _getDelegationState(
-    address user
-  ) internal view override returns (DelegationState memory) {
-    DelegationAwareBalance memory userState = _balances[user];
-    return
-      DelegationState({
-        delegatedPropositionBalance: userState.delegatedPropositionBalance,
-        delegatedVotingBalance: userState.delegatedVotingBalance,
-        delegationMode: userState.delegationMode
-      });
-  }
-
-  function _getBalance(address user) internal view override returns (uint256) {
-    return balanceOf(user);
-  }
-
-  function getPowerCurrent(
-    address user,
-    GovernancePowerType delegationType
-  ) public view override returns (uint256) {
-    return (super.getPowerCurrent(user, delegationType) * EXCHANGE_RATE_UNIT) / getExchangeRate();
-  }
-
-  function _setDelegationState(
-    address user,
-    DelegationState memory delegationState
-  ) internal override {
-    DelegationAwareBalance storage userState = _balances[user];
-    userState.delegatedPropositionBalance = delegationState.delegatedPropositionBalance;
-    userState.delegatedVotingBalance = delegationState.delegatedVotingBalance;
-    userState.delegationMode = delegationState.delegationMode;
-  }
-
-  function _incrementNonces(address user) internal override returns (uint256) {
-    unchecked {
-      // Does not make sense to check because it's not realistic to reach uint256.max in nonce
-      return _nonces[user]++;
-    }
-  }
-
-  function _getDomainSeparator() internal view override returns (bytes32) {
-    return DOMAIN_SEPARATOR();
+    super._update(from, to, amount);
   }
 }
```
