// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {INeynarVerificationsReader} from "./INeynarVerificationsReader.sol";
import {Ownable, Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract GateKeeper is Ownable2Step {
    INeynarVerificationsReader public verifications;

    constructor(address _owner, INeynarVerificationsReader _verifications) Ownable(_owner) {
        verifications = _verifications;
    }

    function setVerifications(INeynarVerificationsReader _verifications) public onlyOwner {
        verifications = _verifications;
    }

    // TODO: what else can we block on?
    // TODO: simple token balance isn't great. needs to be staked for time or count the average balance over the last month or something
    function allowed(address who) public view returns (bool) {
        return verifications.getFid(who) != 0;
    }
}
