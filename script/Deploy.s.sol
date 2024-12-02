// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ChandelierOrNot, INeynarUserScoresReader} from "../src/ChandelierOrNot.sol";

contract DeployScript is Script {
    ChandelierOrNot public nft;
    INeynarUserScoresReader public scores;

    function setUp() public {}

    // this is used by the post-to-chandelier-or-not.sh.
    // you probably don't want to call it directly.
    function run() public {
        uint24 mintScore = type(uint24).max;  // 1e6 is the real max. setting to u24 max means only approved addresses can mint
        
        scores = INeynarUserScoresReader(vm.envAddress("NN_USER_SCORES_ADDRESS"));

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        nft = new ChandelierOrNot(mintScore, scores);

        vm.stopBroadcast();

        console.log("ChandelierOrNot deployed at", address(nft));
    }
}
