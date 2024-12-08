// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20} from "@solady/tokens/ERC20.sol";
import {ERC4626} from "@solady/tokens/ERC4626.sol";
import {SafeCastLib} from "@solady/utils/SafeCastLib.sol";
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";
import {TwabController} from "@pooltogether-v5-twab-controller/TwabController.sol";

contract PointsToken is ERC20 {
    address public immutable stakedToken;
    ERC20 public immutable asset;

    // TODO: this tracks the balances, but ERC20 also tracks the balance. we should probably improve that
    TwabController public immutable twabController;

    constructor(ERC20 _asset, TwabController _twabController) {
        asset = _asset;
        stakedToken = msg.sender;
        twabController = _twabController;
    }

    /// @dev Hook that is called after any transfer of tokens.
    /// This includes minting and burning.
    /// TODO: Time-weighted average balance controller from pooltogether takes a uint96, not a uint256. this might cause problems
    function _afterTokenTransfer(address from, address to, uint256 amount) internal override {
        twabController.transfer(from, to, SafeCastLib.toUint96(amount));
    }

    /// @dev we don't control the vault and so name might change
    function _constantNameHash() internal view override returns (bytes32 result) {
        return keccak256(bytes(name()));
    }

    /// @dev we don't control the vault and so name might change
    function name() public view override returns (string memory) {
        // we could cache these, but these methods are mostly used off-chain and so this is fine
        return string(abi.encodePacked("Points from ", asset.name()));
    }

    /// @dev we don't control the vault and so symbol might change
    function symbol() public view override returns (string memory) {
        // we could cache this locally, but these methods are mostly used off-chain and so this is fine
        return string(abi.encodePacked("p", asset.symbol()));
    }

    function mint(address to, uint256 amount) public {
        require(msg.sender == stakedToken);

        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function burn(address owner, uint256 amount) public {
        if (owner != msg.sender) {
            _spendAllowance(owner, msg.sender, amount);
        }

        _burn(owner, amount);
    }
}
