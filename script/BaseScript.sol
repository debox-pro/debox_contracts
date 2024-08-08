// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Script, console } from "forge-std/Script.sol";

contract BaseScript is Script {
  string constant FILE = "./deployed.json";

  address public devAdmin = 0x3CE1F9BfcF48Ea8EE299E48aD8d62517584Af24E;
  address public prodAdmin = 0x82eb6481aB69dF6f8B43b9883cA611B8EA630095;

  function writeAddr(string memory key, address addr) public {
    // get chain id
    uint256 chainId;
    assembly {
      chainId := chainid()
    }

    key = string.concat(".", vm.toString(chainId), key);

    vm.writeJson(vm.toString(addr), FILE, key);
  }

  function getAddr(string memory key) private view returns (address) {
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    key = string.concat(".", vm.toString(chainId), key);
    string memory data = vm.readFile(FILE);
    return vm.parseJsonAddress(data, key);
  }

  function addressToBytes32(address _addr) internal pure returns (bytes32) {
    return bytes32(uint256(uint160(_addr)));
  }
}
