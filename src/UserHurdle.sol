// SPDX-License-Identifier: MIT
// TODO: I don't love this name
pragma solidity ^0.8.28;

import {AccessControl} from "@openzeppelin/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {INeynarVerificationsReader} from "./INeynarVerificationsReader.sol";
import {IUserHurdle} from "./IUserHurdle.sol";

contract UserHurdle is AccessControl, IUserHurdle {
    bytes32 public constant POSTER_ROLE = keccak256("POSTER_ROLE");

    INeynarVerificationsReader public immutable verifications;

    constructor(INeynarVerificationsReader _verifications) {
        verifications = _verifications;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(POSTER_ROLE, msg.sender);
    }

    // @notice if this user can post a new image
    function postAllowed(address who) public returns (bool) {
        return hasRole(POSTER_ROLE, who) || verifications.getFidWithEvent(who) != 0;
    }

    // @notice if this user receives tokens when they vote
    function voteTokenAllowed(address who) public returns (bool) {
        // TODO: what else can we block on?
        // TODO: simple token balance isn't great. needs to be staked for time or count the average balance over the last month or something
        return verifications.getFidWithEvent(who) != 0;
    }
}
