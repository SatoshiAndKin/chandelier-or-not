// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ChandelierOrNot} from "../src/ChandelierOrNot.sol";
import {UserHurdle, IUserHurdle} from "../src/UserHurdle.sol";
import {INeynarVerificationsReader} from "../src/INeynarVerificationsReader.sol";

contract DeployScript is Script {
    ChandelierOrNot public nft;
    UserHurdle public userHurdle;
    INeynarVerificationsReader public verifications;

    function setUp() public {}

    // this is used by the post-to-chandelier-or-not.sh.
    // you probably don't want to call it directly.
    function run() public {
        verifications = INeynarVerificationsReader(vm.envAddress("NN_VERIFICATIONS_ADDRESS"));

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        userHurdle = new UserHurdle(verifications);

        nft = new ChandelierOrNot(IUserHurdle(userHurdle));

        vm.stopBroadcast();

        console.log("ChandelierOrNot deployed at", address(nft));
    }
}
