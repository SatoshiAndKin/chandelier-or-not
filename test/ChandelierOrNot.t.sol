// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {ChandelierOrNot, ChandelierOrNotToken, LibString} from "../src/ChandelierOrNot.sol";
import {INeynarVerificationsReader} from "../src/INeynarVerificationsReader.sol";
import {IUserHurdle, UserHurdle} from "../src/UserHurdle.sol";

contract TestChandelierOrNot is ChandelierOrNot {
    constructor(address _owner, IUserHurdle _userHurdle) ChandelierOrNot(_owner, _userHurdle) {}

    // TODO: whats the best way to test an internal function?
    function packVotedKey(address who, uint96 postId) external pure returns (uint256) {
        return _packVotedKey(who, postId);
    }
}

contract ChandelierOrNotTest is Test {
    using LibString for uint256;

    uint256 baseFork;
    address owner;

    UserHurdle public userHurdle;
    TestChandelierOrNot public nft;
    ChandelierOrNotToken public token;
    INeynarVerificationsReader public verifications;

    function setUp() public {
        baseFork = vm.createFork(vm.envString("BASE_RPC_URL"), 23153749);
        vm.selectFork(baseFork);

        verifications = INeynarVerificationsReader(vm.envAddress("NN_VERIFICATIONS_ADDRESS"));

        owner = makeAddr("owner");

        userHurdle = new UserHurdle(owner, verifications);

        nft = new TestChandelierOrNot(owner, IUserHurdle(userHurdle));

        token = nft.token();
    }

    function test_Verifications() public {
        assertEq(verifications.getFidWithEvent(0x2699C32A793D58691419A054DA69414dF186b181), 3253, "unexpected fid with event");
    }

    function test_NftMetadata() public view {
        assertEq(nft.name(0), "Not a Chandelier #0", "unexpected no nft name");
        assertEq(nft.symbol(0), "CNOT-N0", "unexpected no nft symbol");
        assertEq(nft.decimals(0), 0, "unexpected no nft decimals");

        assertEq(nft.name(1), "Chandelier #0", "unexpected yes nft name");
        assertEq(nft.symbol(1), "CNOT-Y0", "unexpected yes nft symbol");
        assertEq(nft.decimals(1), 0, "unexpected yes nft decimals");
    }

    function test_TokenMetadata() public view {
        assertEq(token.name(), "Chandelier or Not Votes", "unexpected token name");
        assertEq(token.symbol(), "CNOT", "unexpected token symbol");
        assertEq(token.decimals(), 18, "unexpected token decimals");
    }

    function test_AdminPost() public {
        vm.startPrank(owner);
        uint256 postId = nft.post("https://example.com/post0");
        assertEq(postId, 0);
        assertEq(nft.nextPostId(), 1);
    }

    function test_packVotedKey() public view {
        address user = 0x2699C32A793D58691419A054DA69414dF186b181;

        uint256 minVotedKey = nft.packVotedKey(user, 0);
        console.log("minVotedKey:", minVotedKey);
        assertEq(minVotedKey, 0x2699c32a793d58691419a054da69414df186b181000000000000000000000000);

        uint256 maxVotedKey = nft.packVotedKey(user, type(uint96).max);
        console.log("maxVotedKey:", maxVotedKey);
        assertEq(maxVotedKey, 0x2699c32a793d58691419a054da69414df186b181FFFFFFFFFFFFFFFFFFFFFFFF);
    }

    function test_TheNormalFlow() public {
        vm.startPrank(owner);
        uint96 postId = nft.post("https://example.com/post0");
        assertEq(postId, 0);
        assertEq(nft.nextPostId(), 1);

        // vote from flashprofits.eth
        address flashprofits = 0x2699C32A793D58691419A054DA69414dF186b181;

        vm.startPrank(flashprofits);
        (uint256 yesTokenId, uint256 yesAmount) = nft.vote(postId, true);

        uint256 noTokenId = nft.getOppositeTokenId(yesTokenId);

        assertEq(nft.tokenURI(yesTokenId), "https://example.com/post0/yes.json");
        assertEq(nft.tokenURI(noTokenId), "https://example.com/post0/no.json");

        assertEq(yesTokenId, 1, "unexpected yesTokenId");
        assertEq(yesAmount, 1 ether, "unexpected yesAmount");
        assertEq(nft.balanceOf(flashprofits, yesTokenId), 1, "unexpected balance of yesTokenId");
        assertEq(nft.balanceOf(flashprofits, noTokenId), 0, "unexpected balance of noTokenId");
        assertEq(token.balanceOf(flashprofits), yesAmount, "unexpected balance of token");

        assertEq(nft.hasVoted(flashprofits, postId), true, "unexpected hasVoted");

        vm.expectRevert(ChandelierOrNot.AlreadyVoted.selector);
        nft.vote(postId, false);

        uint256 oppositeTokenId = nft.changeVote(yesTokenId, 1);
        assertEq(oppositeTokenId, noTokenId);

        assertEq(nft.balanceOf(flashprofits, yesTokenId), 0, "unexpected balance of yesTokenId after vote change");
        assertEq(nft.balanceOf(flashprofits, noTokenId), 1, "unexpected balance of noTokenId after vote change");
        assertEq(token.balanceOf(flashprofits), yesAmount, "unexpected balance of token after vote change");
    }

    function test_AnonUserPost() public {
        vm.prank(address(420));
        vm.expectRevert("ChandelierOrNot: not allowed to post");
        nft.post("https://example.com/post1");
    }
}
