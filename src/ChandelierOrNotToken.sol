// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20} from "@solady/tokens/ERC20.sol";

/**
 * I could bundle this inside the ChandelierOrNot contract, but a lot of exchanges only support ERC20 and not ERC1155.
 *     So this is simplest
 */
contract ChandelierOrNotToken is ERC20 {
    error NotMinter();

    address public immutable minter;

    constructor() {
        minter = msg.sender;
    }

    function name() public pure override returns (string memory) {
        return "Chandelier or Not Votes";
    }

    function symbol() public pure override returns (string memory) {
        return "CNOT";
    }

    // @notice this is only called by the ChandelierOrNot contract when a user votes
    function mint(address to, uint256 amount) public {
        require(msg.sender == minter, NotMinter());
        _mint(to, amount);
    }
}
