// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IGateKeeper {
    function allowed(address who) external view returns (bool);
}
