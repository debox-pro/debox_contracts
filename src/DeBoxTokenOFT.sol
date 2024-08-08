// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OFT } from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import { OFTAdapter } from "@layerzerolabs/oft-evm/contracts/OFTAdapter.sol";

contract DeBoxTokenOFT is OFT {
  /**
   * @param _owner The owner of the adapter.
   * @param _lzEndpoint The LayerZero [endpoint address](https://docs.layerzero.network/v2/developers/evm/technical-reference/deployed-contracts).
   */
  constructor(address _owner, address _lzEndpoint) OFT("DeBoxToken", "BOX", _lzEndpoint, _owner) Ownable(_owner) { }
}

contract DeBoxTokenOFTAdapter is OFTAdapter {
  /**
   * @param _owner The owner of the adapter.
   * @param _token The address of the ERC-20 token to be adapted.
   * @param _lzEndpoint The LayerZero endpoint address (https://docs.layerzero.network/v2/developers/evm/technical-reference/deployed-contracts)
   */
  constructor(address _owner, address _token, address _lzEndpoint)
    OFTAdapter(_token, _lzEndpoint, _owner)
    Ownable(_owner)
  { }
}
