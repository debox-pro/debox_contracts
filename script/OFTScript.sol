// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./BaseScript.sol";
import { DeBoxTokenOFT, DeBoxTokenOFTAdapter } from "../src/DeBoxTokenOFT.sol";

import "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import { OptionsBuilder } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OFTScript is BaseScript {
  using OptionsBuilder for bytes;

  mapping(string => EndpointInfo) public lzEndpoints;

  struct EndpointInfo {
    uint32 eid;
    address endpoint;
  }

  function setUp() public {
    lzEndpoints["ethereum-mannet"] = EndpointInfo({ eid: 30101, endpoint: 0x1a44076050125825900e736c501f859c50fE728c });
    lzEndpoints["mantle-mannet"] = EndpointInfo({ eid: 30181, endpoint: 0x1a44076050125825900e736c501f859c50fE728c });

    lzEndpoints["mantle-sepolia"] = EndpointInfo({ eid: 40246, endpoint: 0x6EDCE65403992e310A62460808c4b910D972f10f });
    lzEndpoints["ethereum-sepolia"] = EndpointInfo({ eid: 40161, endpoint: 0x6EDCE65403992e310A62460808c4b910D972f10f });
  }

  function deployAdapterOnSepolia() public {
    address box = 0xecB310bf36f969aA8F9BEE2b6C43910f4bB60F78;
    address admin = 0x3CE1F9BfcF48Ea8EE299E48aD8d62517584Af24E;
    deployAdapter("ethereum-sepolia", box, admin);
  }

  function deployAdapter(string memory chainName, address boxToken, address admin) private {
    address endpoint = lzEndpoints[chainName].endpoint;

    require(boxToken != address(0), "boxToken address is required");
    require(admin != address(0), "admin address is required");
    require(endpoint != address(0), "endpoint address is required");

    // retry call endpoint
    require(ILayerZeroEndpointV2(endpoint).eid() > 0, "endpoint is not valid");

    vm.startBroadcast();
    DeBoxTokenOFTAdapter adapter = new DeBoxTokenOFTAdapter(admin, boxToken, endpoint);
    console.log("BoxAdapter address: ", address(adapter));
    vm.stopBroadcast();

    //check
    vm.assertEq(adapter.owner(), admin, "owner should be admin");
    vm.assertEq(adapter.token(), boxToken, "token should be boxToken");
    vm.assertEq(address(adapter.endpoint()), endpoint, "endpoint should be lzEndpoint");
  }

  function deployOnMantleSepolia() public {
    deployOFT("mantle-sepolia", devAdmin);
  }

  function deployOFT(string memory chainName, address admin) public {
    address endpoint = lzEndpoints[chainName].endpoint;

    require(endpoint != address(0), "boxToken address is required");
    require(admin != address(0), "admin address is required");

    // retry call endpoint
    require(ILayerZeroEndpointV2(endpoint).eid() > 0, "endpoint is not valid");

    vm.startBroadcast();

    DeBoxTokenOFT boxB = new DeBoxTokenOFT(admin, endpoint);
    console.log("boxB address: ", address(boxB));
    vm.stopBroadcast();

    //check
    vm.assertEq(boxB.owner(), admin, "owner should be admin");
    vm.assertEq(boxB.token(), address(boxB), "token should be boxToken");
    vm.assertEq(address(boxB.endpoint()), endpoint, "endpoint should be lzEndpoint");
  }

  function setPeer(address oft, uint32 eid, address peer) public {
    require(eid != 0, "eid is required");
    DeBoxTokenOFT oftCA = DeBoxTokenOFT(oft);
    bytes32 oldPeer = oftCA.peers(eid);
    console.logBytes32(oldPeer);

    bytes32 newPeer = addressToBytes32(peer);
    if (oldPeer != newPeer) {
      vm.broadcast();
      oftCA.setPeer(eid, newPeer);
    } else {
      console.log("peer is already set,skip");
    }
  }

  function bridge1000BoxToMantleSepolia() public {
    bridge(IOFT(0x228AffE9D8f9C86a104Dd2Ae7B7feE416fa00955), 40246, 1000 * 1e18);
  }

  function bridge1000BoxToEthereumSepolia() public {
    bridge(IOFT(0x33f3fC607c3592DCF0103C5577b872D9124e1AaA), 40161, 800 * 1e18);
  }

  function bridge(IOFT oft, uint32 targetEid, uint256 tokensToSend) public {
    address user = msg.sender;

    console.log("current user: ", user);

    bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);
    SendParam memory sendParam =
      SendParam(targetEid, addressToBytes32(user), tokensToSend, tokensToSend, options, "", "");
    MessagingFee memory fee = oft.quoteSend(sendParam, false);

    address token = oft.token();
    if (IERC20(token).allowance(user, address(oft)) < tokensToSend) {
      vm.broadcast(user);
      IERC20(token).approve(address(oft), type(uint256).max);
    }

    console.log("fee: ", fee.nativeFee);

    vm.broadcast(user);
    oft.send{ value: fee.nativeFee }(sendParam, fee, payable(address(user)));
  }
}
