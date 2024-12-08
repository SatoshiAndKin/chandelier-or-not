// SPDX-License-Identifier: MIT
// TODO: i don't love the name. finish renaming game token to staked token
pragma solidity ^0.8.28;

// TODO: move most of the NFT logic here
// TODO: give tokens based on deposits. make sure someone depositing can't reduce someone else's withdraw
// TODO: factory contract to deploy our tokens for any vault tokens

import {ERC20} from "@solady/tokens/ERC20.sol";
import {ERC4626} from "@solady/tokens/ERC4626.sol";
import {SafeCastLib} from "@solady/utils/SafeCastLib.sol";
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";
import {TwabController} from "@pooltogether-v5-twab-controller/TwabController.sol";
import {StakedToken} from "./StakedToken.sol";

/// @notice transform any ERC4626 vault token into a gamified tokens where the interest is sent to a contract that earns points
contract StakedTokenFactory {
    event StakedTokenCreated(address indexed asset, address indexed earnings, address stakedToken, address vault);

    // fixed twab controller to avoid shenanigans
    TwabController public immutable twabController;

    constructor(TwabController _twabController) {
        twabController = _twabController;
    }

    // TODO: should earnings be a list? maybe with a list for shares too? that seems like a common need
    function createStakedToken(ERC4626 vault, address earnings, uint256 depositFee) public returns (StakedToken stakedToken) {
        ERC20 asset = ERC20(vault.asset());

        // TODO: use LibClone for StakedToken. the token uses immutables though so we need to figure out clones with immutables
        // TODO: i don't think we want to allow a customizeable salt
        // create2 is important so addresses are predictable
        stakedToken = new StakedToken{salt: bytes32(0)}(asset, earnings, twabController, vault, depositFee);

        emit StakedTokenCreated(address(asset), earnings, address(stakedToken), address(vault));
    }
}
