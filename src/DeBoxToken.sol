//   _____    ______   ____     ____   __   __
//  |  __ \  |  ____| |  _ \   / __ \  \ \ / /
//  | |  | | | |__    | |_) | | |  | |  \ V /
//  | |  | | |  __|   |  _ <  | |  | |   > <
//  | |__| | | |____  | |_) | | |__| |  / . \
//  |_____/  |______| |____/   \____/  /_/ \_\
//
//  Author: https://debox.pro/
//

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/**
 * @title DeBoxToken
 * @author https://debox.pro/
 * @notice DeBoxToken is an ERC20 token with permit. It is the governance token of the DeBox platform.
 */
contract DeBoxToken is ERC20Permit {
  constructor() ERC20Permit("DeBoxToken") ERC20("DeBoxToken", "BOX") {
    _mint(0x2745F97f501087caF8eA740854Cfcac011fb34C3, 5.5e9 ether); // 5.5 billion
    _mint(0x5b1AfdB8C23569484773aF7bD4c98Af9ee7599D9, 0.5e9 ether);
    _mint(msg.sender, 4e9 ether);
    // safety check
    require(totalSupply() == 10_000_000_000 ether, "incorrect total supply"); // 10 billion
  }

  function _update(address from, address to, uint256 value) internal override {
    // disallow transfers to this contract
    if (to == address(this)) revert ERC20InvalidReceiver(to);

    super._update(from, to, value);
  }
}
