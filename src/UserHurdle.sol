// SPDX-License-Identifier: MIT
// TODO: I don't love this name
pragma solidity ^0.8.28;

import {OwnableRoles} from "@solady/auth/OwnableRoles.sol";
import {INeynarVerificationsReader} from "./INeynarVerificationsReader.sol";
import {IUserHurdle} from "./IUserHurdle.sol";

contract UserHurdle is OwnableRoles, IUserHurdle {
    uint256 public constant POSTER_ROLE = _ROLE_0;

    INeynarVerificationsReader public immutable verifications;

    constructor(address _owner, INeynarVerificationsReader _verifications) {
        verifications = _verifications;

        _initializeOwner(_owner);
    }

    // @notice if this user can post a new image
    // TODO: eventually this will be opened up to anyone with a verified account
    function postAllowed(address who) public view returns (bool) {
        return who == owner() || hasAnyRole(who, POSTER_ROLE);
    }

    // @notice if this user receives tokens when they vote
    function voteTokenAllowed(address who) public returns (bool) {
        // TODO: what else can we block on?
        // TODO: simple token balance isn't great. needs to be staked for time or count the average balance over the last month or something
        return verifications.getFidWithEvent(who) != 0 || who == owner() || hasAnyRole(who, POSTER_ROLE);
    }
}
