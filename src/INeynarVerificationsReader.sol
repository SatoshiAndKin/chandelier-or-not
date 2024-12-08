// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface INeynarVerificationsReader {
    function getFid(address verifier) external view returns (uint256 fid);
    function getFidWithEvent(address verifier) external returns (uint256 fid);
    function getFids(address[] calldata verifiers) external view returns (uint256[] memory fid);
}
