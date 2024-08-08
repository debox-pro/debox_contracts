// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { DeBoxToken } from "../src/DeBoxToken.sol";

// OApp imports
import {
  IOAppOptionsType3, EnforcedOptionParam
} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import { OptionsBuilder } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

// OFT imports
import { IOFT, SendParam, OFTReceipt } from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import { MessagingFee, MessagingReceipt } from "@layerzerolabs/oft-evm/contracts/OFTCore.sol";
import { OFTMsgCodec } from "@layerzerolabs/oft-evm/contracts/libs/OFTMsgCodec.sol";
import { OFTComposeMsgCodec } from "@layerzerolabs/oft-evm/contracts/libs/OFTComposeMsgCodec.sol";

// OZ imports
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// Forge imports
import "forge-std/console.sol";

// DevTools imports
import { TestHelperOz5 } from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";

// The unique path location of your OApp
import { DeBoxTokenOFT, DeBoxTokenOFTAdapter } from "../src/DeBoxTokenOFT.sol";

/// @notice Unit test for MyOApp using the TestHelper.
/// @dev Inherits from TestHelper to utilize its setup and utility functions.
contract TestBoxOFT is TestHelperOz5 {
  using OptionsBuilder for bytes;

  DeBoxTokenOFT bOFT;
  DeBoxTokenOFTAdapter boxOFTAdapter;
  DeBoxToken box;

  // Declaration of mock endpoint IDs.
  uint16 aEid = 1;
  uint16 bEid = 2;

  uint256 initialBalance = 1_000_000 * 1e18;

  address admin = makeAddr("admin");
  address alice = makeAddr("alice");
  address bob = makeAddr("bob");
  /// @notice Calls setUp from TestHelper and initializes contract instances for testing.

  function setUp() public virtual override {
    super.setUp();

    // Setup function to initialize 2 Mock Endpoints with Mock MessageLib.
    setUpEndpoints(2, LibraryType.UltraLightNode);

    assertTrue(endpoints[aEid] != address(0), "Endpoint A not initialized");
    assertTrue(endpoints[bEid] != address(0), "Endpoint B not initialized");

    // Deploy the DeBoxToken contract
    vm.startPrank(admin);
    box = new DeBoxToken();
    console.log("box: ", address(box));

    boxOFTAdapter = new DeBoxTokenOFTAdapter(admin, address(box), address(endpoints[aEid]));
    console.log("boxOFTAdapter: ", address(boxOFTAdapter));
    bOFT = new DeBoxTokenOFT(admin, address(endpoints[bEid]));
    box.transfer(alice, initialBalance);

    // config and wire the ofts
    address[] memory ofts = new address[](2);
    ofts[0] = address(boxOFTAdapter);
    ofts[1] = address(bOFT);
    wireOApps(ofts);

    vm.stopPrank();
  }

  function test_constructor() public {
    assertEq(boxOFTAdapter.owner(), admin);
    assertEq(bOFT.owner(), admin);

    assertEq(box.balanceOf(alice), initialBalance);
    assertEq(box.balanceOf(address(boxOFTAdapter)), 0);
    assertEq(bOFT.balanceOf(bob), 0);

    assertEq(boxOFTAdapter.token(), address(box));
    assertEq(bOFT.token(), address(bOFT));
  }

  function test_send_oft_adapter() public {
    address userB = makeAddr("userB");
    address userA = makeAddr("userA");

    uint256 tokensToSend = 1 ether;
    deal(userA, 10 ether);
    deal(address(box), userA, initialBalance);

    bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);
    SendParam memory sendParam = SendParam(bEid, addressToBytes32(userB), tokensToSend, tokensToSend, options, "", "");
    MessagingFee memory fee = boxOFTAdapter.quoteSend(sendParam, false);

    assertEq(box.balanceOf(userA), initialBalance);
    assertEq(box.balanceOf(address(boxOFTAdapter)), 0);
    assertEq(bOFT.balanceOf(userB), 0);

    vm.prank(userA);
    box.approve(address(boxOFTAdapter), tokensToSend);

    vm.prank(userA);
    boxOFTAdapter.send{ value: fee.nativeFee }(sendParam, fee, payable(address(this)));
    verifyPackets(bEid, addressToBytes32(address(bOFT)));

    assertEq(box.balanceOf(userA), initialBalance - tokensToSend);
    assertEq(box.balanceOf(address(boxOFTAdapter)), tokensToSend);
    assertEq(bOFT.balanceOf(userB), tokensToSend);
  }
}
