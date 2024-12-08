// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20Burnable} from "@openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20, ERC20Permit} from "@openzeppelin/token/ERC20/extensions/ERC20Permit.sol";

/** I could bundle this inside the ChandelierOrNot contract, but a lot of exchanges only support ERC20 and not ERC1155.
    So this is simplest
 */
contract ChandelierOrNotToken is ERC20Burnable, ERC20Permit {
    error NotMinter();

    address public immutable minter;

    constructor() ERC20("ChandelierOrNotToken", "CNOT") ERC20Permit("ChandelierOrNotToken") {
        minter = msg.sender;
    }

    // @notice this is only called by the ChandelierOrNot contract when a user votes
    function mint(address to, uint256 amount) public {
        require(msg.sender == minter, NotMinter());
        _mint(to, amount);
    }
}
