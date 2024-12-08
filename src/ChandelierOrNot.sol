// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC6909} from "@solady/tokens/ERC6909.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

import {ChandelierOrNotToken} from "./ChandelierOrNotToken.sol";
import {IUserHurdle} from "./IUserHurdle.sol";

// TODO: make it burnable and have a supply? not sure how to combine them. it complains about multiple _updates
// TODO: bitmap for voted? we need a bitmap inside of a mapping though
// TODO: gate mints on a score OR on having a token balance
// TODO: allow changing your vote. need to use the new score properly

contract ChandelierOrNot is Ownable, ERC6909  {
    using LibString for uint256;

    IUserHurdle public userHurdle;
    uint256 public nextPostId;
    mapping(address who => mapping(uint256 postId => bool)) public voted;
    mapping(uint256 tokenId => uint256) public totalSupply;

    mapping(uint256 postId => string) private _postURIs;

    ChandelierOrNotToken immutable public token;

    event NewPost(address indexed poster, uint256 postId);

    constructor(address _owner, IUserHurdle _userHurdle) ERC6909() {
        userHurdle = _userHurdle;

        _initializeOwner(_owner);

        token = new ChandelierOrNotToken();
    }

    // internal functions

    function _mint(address to, uint256 tokenId, uint256 amount) internal override {
        totalSupply[tokenId] += amount;

        super._mint(to, tokenId, amount);
    }

    // owner-only functions

    function setUserHurdle(IUserHurdle _userHurdle) public onlyOwner {
        userHurdle = _userHurdle;
    }

    // high score-only functions

    // @notice The metadata_uri MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    // @notice <https://eips.ethereum.org/EIPS/eip-1155#metadata>
    // TODO: should the yes and no votes have different uris? 
    function post(string calldata postDirURI) public returns (uint256 postId) {
        if (address(userHurdle) != address(0) && !userHurdle.postAllowed(msg.sender)) {
            revert("ChandelierOrNot: not allowed to post");
        }

        postId = nextPostId++;

        _postURIs[postId] = postDirURI;

        emit NewPost(msg.sender, postId);
    }

    function postAndVote(string calldata postDirURI, bool voteYes) public returns (uint256 postId, uint256 tokenId, uint256 amount) {
        postId = post(postDirURI);
        (tokenId, amount) = vote(postId, voteYes);
    }

    function getPost(uint256 tokenId) public pure returns (uint256 x, bool yesVote) {
        x = tokenId / 2;
        yesVote = tokenId % 2 == 1;
    }

    function getTokenId(uint256 postId, bool yesVote) public pure returns (uint256 x) {
        x = postId * 2 + (yesVote ? 1 : 0);
    }

    function getOppositeTokenId(uint256 tokenId) public pure returns (uint256 x) {
        if (tokenId % 2 == 0) {
            x = tokenId + 1;
        } else {
            x = tokenId - 1;
        }
    }

    // @dev ties go to No
    function winner(uint256 postId) public view returns (bool yesIsWinning, uint256 yesVotes, uint256 noVotes) {
        // this could be gas golfed, but i want readability
        uint256 noTokenId = getTokenId(postId, false);
        uint256 yesTokenId = noTokenId + 1;

        yesVotes = totalSupply[yesTokenId];
        noVotes = totalSupply[noTokenId];

        yesIsWinning = yesVotes > noVotes;
    }

    /** most projects give you one token. Here, you get two!
     * One is connected to the picture and your vote.
     * The other is fully fungible.
     */
    function vote(uint256 postId, bool voteYes) public returns (uint256 tokenId, uint256 mintTokenAmount) {
        // make sure the user hasn't already voted for this post
        require(!voted[msg.sender][postId], "ChandelierOrNot: already voted");
        voted[msg.sender][postId] = true;

        tokenId = getTokenId(postId, voteYes);

        // mint the image token
        _mint(msg.sender, tokenId, 1);

        // maybe mint the fungible token
        // TODO: if user hurdle is not set, should we always mint or never mint?
        if (address(userHurdle) != address(0) || userHurdle.voteTokenAllowed(msg.sender)) {
            mintTokenAmount = 1 ether;
            token.mint(msg.sender, mintTokenAmount);
        }
    }

    // @notice swap `amount` of your vote tokens to the other side
    function changeVote(uint256 tokenId, uint256 amount) public returns (uint256 oppositeTokenId) {
        // this will revert if the sender doesn't have enough tokens
        _burn(msg.sender, tokenId, amount);

        oppositeTokenId = getOppositeTokenId(tokenId);

        _mint(msg.sender, oppositeTokenId, amount);
    }

    // public functions

    /// @dev Returns the name for token `id`.
    function name(uint256 tokenId) public pure override returns (string memory) {
        (uint256 postId, bool votedYes) = getPost(tokenId);

        if (votedYes) {
            return string(abi.encodePacked("Chandelier #", postId.toString()));
        } else {
            return string(abi.encodePacked("Not a Chandelier #", postId.toString()));
        }
    }

    /// @dev Returns the symbol for token `id`.
    function symbol(uint256 tokenId) public pure override returns (string memory) {
        (uint256 postId, bool votedYes) = getPost(tokenId);

        if (votedYes) {
            return string(abi.encodePacked("CNOT-Y#", postId.toString()));
        } else {
            return string(abi.encodePacked("CNOT-N#", postId.toString()));
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        (uint256 postId, bool votedYes) = getPost(tokenId);

        require(postId < nextPostId, "ChandelierOrNot: invalid post id");

        string memory postURI = _postURIs[postId];

        if (votedYes) {
            return string.concat(postURI, "/yes.json");
        } else {
            return string.concat(postURI, "/no.json");
        }
    }
}
