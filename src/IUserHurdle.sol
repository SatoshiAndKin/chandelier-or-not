// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IUserHurdle {
    function postAllowed(address who) external returns (bool);
    function voteTokenAllowed(address who) external returns (bool);
}
