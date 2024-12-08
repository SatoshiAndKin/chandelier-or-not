// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ChandelierOrNot} from "../src/ChandelierOrNot.sol";

contract PostAndVoteScript is Script {
    ChandelierOrNot public nft;

    function setUp() public {}

    // this is used by the post-to-chandelier-or-not.sh script.
    // you probably don't want to call it directly.
    function run() public {
        nft = ChandelierOrNot(vm.envAddress("CNOT_ADDRESS"));

        string memory image_uri = vm.envString("IMAGE_URI");

        bool voteYes = vm.envBool("VOTE_YES");

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        (uint256 postId, uint256 tokenId, uint256 amount) = nft.postAndVote(image_uri, voteYes);

        console.log("New Post:", postId, tokenId, amount);

        // TODO: vote here? i think i'll focus on having that in the frame instead

        vm.stopBroadcast();

        // TODO: test our balance
    }
}
