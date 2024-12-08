// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {ChandelierOrNot, ChandelierOrNotToken} from "../src/ChandelierOrNot.sol";
import {INeynarVerificationsReader} from "../src/INeynarVerificationsReader.sol";
import {IUserHurdle, UserHurdle} from "../src/UserHurdle.sol";

contract ChandelierOrNotTest is Test {
    uint256 baseFork;
    address owner;

    UserHurdle public userHurdle;
    ChandelierOrNot public nft;
    ChandelierOrNotToken public token;
    INeynarVerificationsReader public verifications;

    function setUp() public {
        baseFork = vm.createFork(vm.envString("BASE_RPC_URL"), 23153749);
        vm.selectFork(baseFork);

        verifications = INeynarVerificationsReader(vm.envAddress("NN_VERIFICATIONS_ADDRESS"));

        owner = makeAddr("owner");

        userHurdle = new UserHurdle(owner, verifications);

        nft = new ChandelierOrNot(owner, IUserHurdle(userHurdle));

        token = nft.token();
    }

    function test_TokenMetadata() public view {
        assertEq(token.name(), "ChandelierOrNotToken", "unexpected token name");
        assertEq(token.symbol(), "CNOT", "unexpected token symbol");
        assertEq(token.decimals(), 6, "unexpected token decimals");
    }

    function test_AdminPost() public {
        uint256 postId = nft.post("https://example.com/post0");
        assertEq(postId, 0);
        assertEq(nft.nextPostId(), 1);
    }

    function test_TheNormalFlow() public {
        uint256 postId = nft.post("https://example.com/post0");
        assertEq(postId, 0);
        assertEq(nft.nextPostId(), 1);

        // vote from flashprofits.eth
        address flashprofits = 0x2699C32A793D58691419A054DA69414dF186b181;

        vm.startPrank(flashprofits);
        (uint256 yesTokenId, uint256 yesAmount) = nft.vote(postId, true);

        uint256 noTokenId = nft.getOppositeTokenId(yesTokenId);

        assertEq(yesTokenId, 1, "unexpected yesTokenId");
        assertEq(yesAmount, 1e6, "unexpected yesAmount");
        assertEq(nft.balanceOf(flashprofits, yesTokenId), yesAmount, "unexpected balance of yesTokenId");
        assertEq(nft.balanceOf(flashprofits, noTokenId), 0, "unexpected balance of noTokenId");
        assertEq(token.balanceOf(flashprofits), yesAmount, "unexpected balance of token");

        vm.expectRevert("ChandelierOrNot: already voted");
        nft.vote(postId, false);

        uint256 oppositeTokenId = nft.changeVote(yesTokenId, yesAmount);
        assertEq(oppositeTokenId, noTokenId);

        assertEq(nft.balanceOf(flashprofits, yesTokenId), 0, "unexpected balance of yesTokenId after vote change");
        assertEq(nft.balanceOf(flashprofits, noTokenId), yesAmount, "unexpected balance of noTokenId after vote change");
        assertEq(token.balanceOf(flashprofits), yesAmount, "unexpected balance of token after vote change");
    }

    function test_AnonUserPost() public {
        vm.prank(address(420));

        vm.expectRevert("ChandelierOrNot: low post score");
        nft.post("https://example.com/post1");
    }
}
