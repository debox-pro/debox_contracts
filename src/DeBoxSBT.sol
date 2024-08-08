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

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract DeBoxSBT is ERC1155Supply, Ownable {
  using Strings for uint256;

  string public constant name = "DeBox Soulbound Token";
  string public constant symbol = "DeBoxSBT";

  string private _baseURI;

  constructor(string memory uri_) ERC1155("") Ownable(msg.sender) {
    _baseURI = uri_;
  }

  function uri(uint256 id) public view override returns (string memory) {
    require(exists(id), "DeBoxSBT: token not exist");
    return bytes(_baseURI).length > 0 ? string.concat(_baseURI, id.toString()) : "";
  }

  function mint(uint256 tokenId, address[] calldata recipients) external onlyOwner {
    for (uint256 i = 0; i < recipients.length; i++) {
      _mint(recipients[i], tokenId, 1, "");
    }
  }

  function burn(uint256 tokenId, uint256 value) external {
    _burn(msg.sender, tokenId, value);
  }

  function setURI(string calldata baseURI) external onlyOwner {
    _baseURI = baseURI; //ignore event
  }

  function setApprovalForAll(address, bool) public pure override(ERC1155) {
    revert("disabled");
  }

  function _update(address from, address to, uint256[] memory ids, uint256[] memory values) internal override {
    // only allow minting or burning, not transfers
    require(from == address(0) || (from != address(0) && to == address(0)), "transfers not allowed");
    super._update(from, to, ids, values);
  }
}
