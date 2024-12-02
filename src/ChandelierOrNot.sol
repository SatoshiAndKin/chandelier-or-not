// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {AccessControl} from "@openzeppelin/access/AccessControl.sol";
import {ERC1155Burnable} from "@openzeppelin/token/ERC1155/extensions/ERC1155Burnable.sol";
import {ERC1155, ERC1155Supply} from "@openzeppelin/token/ERC1155/extensions/ERC1155Supply.sol";

import {ChandelierOrNotToken} from "./ChandelierOrNotToken.sol";
import {INeynarUserScoresReader} from "./INeynarUserScoresReader.sol";

// TODO: make it burnable and have a supply? not sure how to combine them. it complains about multiple _updates
// TODO: bitmap for voted? we need a bitmap inside of a mapping though
// TODO: gate mints on a score OR on having a token balance
// TODO: allow changing your vote. need to use the new score properly

contract ChandelierOrNot is AccessControl, ERC1155Supply  {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant POSTER_ROLE = keccak256("POSTER_ROLE");
    string public constant name = "ChandelierOrNot";

    uint24 public minPostScore;
    uint256 public nextPostId;
    INeynarUserScoresReader public neynarScores;
    mapping(address who => mapping(uint256 postId => bool)) public voted;

    mapping(uint256 postId => string) private _postURIs;

    ChandelierOrNotToken immutable public token;

    event NewPost(address indexed poster, uint256 postId);

    constructor(uint24 _minPostScore, INeynarUserScoresReader _neynarScores) ERC1155("") {
        minPostScore = _minPostScore;
        neynarScores = _neynarScores;

        _grantRole(MANAGER_ROLE, msg.sender);
        _grantRole(POSTER_ROLE, msg.sender);

        token = new ChandelierOrNotToken();
    }

    // manager-only functions

    function setMinPostScore(uint24 _minPostScore) public onlyRole(MANAGER_ROLE) {
        minPostScore = _minPostScore;
    }

    // high score-only functions

    // @notice The metadata_uri MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    // @notice <https://eips.ethereum.org/EIPS/eip-1155#metadata>
    // TODO: should the yes and no votes have different uris? 
    function post(string calldata postDirURI) public returns (uint256 postId) {
        if (hasRole(POSTER_ROLE, msg.sender)) {
            // all good. they have the poster role
        } else {
            uint24 senderScore = neynarScores.getScore(msg.sender);
            if (senderScore >= minPostScore) {
                // all good. they have a high enough score
            } else {
                revert("ChandelierOrNot: low post score");
            }
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

        yesVotes = totalSupply(yesTokenId);
        noVotes = totalSupply(noTokenId);

        yesIsWinning = yesVotes > noVotes;
    }

    /** most projects give you one token. Here, you get two!
     * One is connected to the picture and your vote.
     * The other is fully fungible.
     */
    function vote(uint256 postId, bool voteYes) public returns (uint256 tokenId, uint256 amount) {
        uint24 senderScore = neynarScores.getScore(msg.sender);

        if (senderScore == 0) {
            // give everyone at least one token
            ++senderScore;
        }

        // make sure the user hasn't already voted for this post
        require(!voted[msg.sender][postId], "ChandelierOrNot: already voted");
        voted[msg.sender][postId] = true;

        tokenId = getTokenId(postId, voteYes);

        amount = uint256(senderScore);

        // mint the ERC1155 token
        _mint(msg.sender, tokenId, amount, "");

        // also mint the ERC20 token
        token.mint(msg.sender, amount);
    }

    // @notice swap `amount` of your vote tokens to the other side
    function changeVote(uint256 tokenId, uint256 amount) public returns (uint256 oppositeTokenId) {
        // this will revert if the sender doesn't have enough tokens
        _burn(msg.sender, tokenId, amount);

        oppositeTokenId = getOppositeTokenId(tokenId);

        _mint(msg.sender, oppositeTokenId, amount, "");
    }

    // public functions

    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        override(AccessControl, ERC1155) 
        returns (bool) 
    {
        return ERC1155.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
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
