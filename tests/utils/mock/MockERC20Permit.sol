// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ERC20} from 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import {ERC20Permit} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol';

contract MockERC20Permit is ERC20, ERC20Permit {
  constructor(
    string memory name_,
    string memory symbol_
  ) ERC20(name_, symbol_) ERC20Permit(name_) {}

  function mint(address to, uint value) external {
    _mint(to, value);
  }

  function burn(address from, uint value) external {
    _burn(from, value);
  }
}
