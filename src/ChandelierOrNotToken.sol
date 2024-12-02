// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Burnable} from "@openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20, ERC20Permit} from "@openzeppelin/token/ERC20/extensions/ERC20Permit.sol";

/** I could bundle this inside the ChandelierOrNot contract, but a lot of exchanges only support ERC20 and not ERC1155.
    So this is simplest
 */
contract ChandelierOrNotToken is ERC20Burnable, ERC20Permit, Ownable {
    constructor() ERC20("ChandelierOrNotToken", "CNOT") ERC20Permit("ChandelierOrNotToken") Ownable(msg.sender) {}

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    // @notice this is only called by the ChandelierOrNot contract when a user votes
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
