// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface INeynarUserScoresReader {
    function getScore(address verifier) external view returns (uint24 score);
    function getScoreWithEvent(address verifier) external returns (uint24 score);
    function getScores(address[] calldata verifiers) external view returns (uint24[] memory scores);

    function getScore(uint256 fid) external view returns (uint24 score);
    function getScoreWithEvent(uint256 fid) external returns (uint24 score);
    function getScores(uint256[] calldata fids) external view returns (uint24[] memory scores);
}
