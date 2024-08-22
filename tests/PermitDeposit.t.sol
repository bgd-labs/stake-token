// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ERC4626Upgradeable} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol';

import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {IERC20Permit} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol';
import {IERC20Errors} from 'openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol';

import {IERC4626StakeToken} from 'src/contracts/interfaces/IERC4626StakeToken.sol';

import {StakeTestBase} from './utils/StakeTestBase.sol';

contract PermitDepositTests is StakeTestBase {
  bytes32 private constant PERMIT_TYPEHASH =
    keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');

  bytes32 private constant TYPE_HASH =
    keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');

  bytes32 _hashedName = keccak256(bytes('MockToken'));
  bytes32 _hashedVersion = keccak256(bytes('1'));

  function test_permitAndDepositSeparate(uint192 amountToStake) public {
    vm.assume(amountToStake > 0);

    vm.startPrank(user);

    uint256 deadline = block.timestamp + 1e6;
    _dealUnderlying(amountToStake, user);

    bytes32 digest = keccak256(
      abi.encode(PERMIT_TYPEHASH, user, address(stakeToken), amountToStake, 0, deadline)
    );

    bytes32 hash = toTypedDataHash(_domainSeparator(), digest);

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, hash);

    IERC20Permit(address(underlying)).permit(
      user,
      address(stakeToken),
      amountToStake,
      deadline,
      v,
      r,
      s
    );

    stakeToken.deposit(amountToStake, user);

    uint256 shares = stakeToken.previewDeposit(amountToStake);

    assertEq(stakeToken.totalAssets(), amountToStake);
    assertEq(stakeToken.totalAssets(), underlying.balanceOf(address(stakeToken)));

    assertEq(stakeToken.totalSupply(), shares);
    assertEq(stakeToken.balanceOf(user), shares);
  }

  function test_permitDeposit(uint192 amountToStake) public {
    vm.assume(amountToStake > 0);

    vm.startPrank(user);

    uint256 deadline = block.timestamp + 1e6;
    _dealUnderlying(amountToStake, user);

    bytes32 digest = keccak256(
      abi.encode(PERMIT_TYPEHASH, user, address(stakeToken), amountToStake, 0, deadline)
    );

    bytes32 hash = toTypedDataHash(_domainSeparator(), digest);

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, hash);

    IStakeToken.SignatureParams memory sig = IStakeToken.SignatureParams(v, r, s);

    stakeToken.depositWithPermit(amountToStake, user, deadline, sig);

    uint256 shares = stakeToken.previewDeposit(amountToStake);

    assertEq(stakeToken.totalAssets(), amountToStake);
    assertEq(stakeToken.totalAssets(), underlying.balanceOf(address(stakeToken)));

    assertEq(stakeToken.totalSupply(), shares);
    assertEq(stakeToken.balanceOf(user), shares);
  }

  function test_permitDepositInvalidSignature(uint192 amountToStake) public {
    vm.assume(amountToStake > 1);

    vm.startPrank(user);

    uint256 deadline = block.timestamp + 1e6;
    _dealUnderlying(amountToStake, user);

    bytes32 digest = keccak256(
      abi.encode(PERMIT_TYPEHASH, user, address(stakeToken), 1, 0, deadline)
    );

    bytes32 hash = toTypedDataHash(_domainSeparator(), digest);

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, hash);

    IStakeToken.SignatureParams memory sig = IStakeToken.SignatureParams(v, r, s);

    vm.expectRevert(
      abi.encodeWithSelector(
        IERC20Errors.ERC20InsufficientAllowance.selector,
        address(stakeToken),
        0,
        amountToStake
      )
    );
    stakeToken.depositWithPermit(amountToStake, user, deadline, sig);
  }

  // copy from OZ
  function _domainSeparator() private view returns (bytes32) {
    return
      keccak256(
        abi.encode(TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(underlying))
      );
  }

  function toTypedDataHash(
    bytes32 domainSeparator,
    bytes32 structHash
  ) private pure returns (bytes32 digest) {
    /// @solidity memory-safe-assembly
    assembly {
      let ptr := mload(0x40)
      mstore(ptr, hex'19_01')
      mstore(add(ptr, 0x02), domainSeparator)
      mstore(add(ptr, 0x22), structHash)
      digest := keccak256(ptr, 0x42)
    }
  }
}
