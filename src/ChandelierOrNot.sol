// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Base64} from "@solady/utils/Base64.sol";
import {ERC6909} from "@solady/tokens/ERC6909.sol";
import {LibBitmap} from "@solady/utils/LibBitmap.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {SafeCastLib} from "@solady/utils/SafeCastLib.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

import {ChandelierOrNotToken} from "./ChandelierOrNotToken.sol";
import {IUserHurdle} from "./IUserHurdle.sol";

// TODO: bitmap for voted? we need a bitmap inside of a mapping though
contract ChandelierOrNot is Ownable, ERC6909 {
    using LibBitmap for LibBitmap.Bitmap;
    using LibString for uint8;
    using LibString for uint96;
    using SafeCastLib for uint256;

    // public state variables
    IUserHurdle public userHurdle;
    uint96 public nextPostId;
    mapping(uint256 tokenId => uint256) public totalSupply;

    // private state variables
    LibBitmap.Bitmap private _voted;
    mapping(uint256 postId => string) private _imageURIs;

    // our fungible token
    ChandelierOrNotToken public immutable token;

    // events
    event NewPost(address indexed poster, uint256 postId);

    // errors
    error AlreadyVoted();

    constructor(address _owner, IUserHurdle _userHurdle) ERC6909() {
        userHurdle = _userHurdle;

        _initializeOwner(_owner);

        token = new ChandelierOrNotToken();
    }

    // internal functions

    function _burn(address from, uint256 tokenId, uint256 amount) internal override {
        super._burn(from, tokenId, amount);

        totalSupply[tokenId] -= amount;
    }

    function _mint(address to, uint256 tokenId, uint256 amount) internal override {
        totalSupply[tokenId] += amount;

        super._mint(to, tokenId, amount);
    }

    function _packVotedKey(address who, uint96 postId) internal pure returns (uint256 x) {
        x = uint256(uint160(who)) << 96 | uint256(postId);
    }

    // owner-only functions

    function setUserHurdle(IUserHurdle _userHurdle) public onlyOwner {
        userHurdle = _userHurdle;
    }

    // user hurdle functions

    /// @notice The metadata_uri MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    /// @notice <https://eips.ethereum.org/EIPS/eip-1155#metadata>
    /// todo: should the yes and no votes have different images?
    function post(string calldata imageURI) public returns (uint96 postId) {
        if (address(userHurdle) != address(0) && !userHurdle.postAllowed(msg.sender)) {
            revert("ChandelierOrNot: not allowed to post");
        }

        postId = nextPostId++;

        _imageURIs[postId] = imageURI;

        emit NewPost(msg.sender, postId);
    }

    function postAndVote(string calldata postDirURI, bool voteYes)
        public
        returns (uint96 postId, uint256 tokenId, uint256 amount)
    {
        postId = post(postDirURI);
        (tokenId, amount) = vote(postId, voteYes);
    }

    /**
     * most projects give you one token. Here, you get two!
     * One is connected to the picture and your vote.
     * The other is fully fungible.
     */
    function vote(uint96 postId, bool voteYes) public returns (uint256 tokenId, uint256 mintTokenAmount) {
        // make sure the user hasn't already voted for this post
        uint256 votedKey = _packVotedKey(msg.sender, postId);
        require(!_voted.get(votedKey), AlreadyVoted());

        // save that the user has voted
        _voted.set(votedKey);

        tokenId = getTokenId(postId, voteYes);

        // mint the image token
        _mint(msg.sender, tokenId, 1);

        // maybe mint the fungible token
        // TODO: if user hurdle is not set, should we always mint or never mint?
        if (address(userHurdle) == address(0) || userHurdle.voteTokenAllowed(msg.sender)) {
            mintTokenAmount = 1 ether;
            token.mint(msg.sender, mintTokenAmount);
        }
    }

    // public functions

    /// @dev swap `amount` of your vote tokens to the other side.
    function changeVote(uint256 tokenId, uint256 amount) public returns (uint256 oppositeTokenId) {
        // this will revert if the sender doesn't have enough tokens
        _burn(msg.sender, tokenId, amount);

        oppositeTokenId = getOppositeTokenId(tokenId);

        _mint(msg.sender, oppositeTokenId, amount);
    }

    /// @dev Returns the post and vote for a given `tokenId`.
    function getPost(uint256 tokenId) public pure returns (uint96 postId, bool yesVote) {
        postId = (tokenId / 2).toUint96();
        yesVote = tokenId % 2 == 1;
    }

    /// @dev Returns the token `id` for a given post and vote.
    function getTokenId(uint96 postId, bool yesVote) public pure returns (uint256 tokenId) {
        tokenId = postId * 2 + (yesVote ? 1 : 0);
    }

    /// @dev Returns the yes/no tokenId for the no/yes `tokenId`'s post.
    function getOppositeTokenId(uint256 tokenId) public pure returns (uint256 oppositeTokenId) {
        if (tokenId % 2 == 0) {
            oppositeTokenId = tokenId + 1;
        } else {
            oppositeTokenId = tokenId - 1;
        }
    }

    /// @dev This NFT contract does not have any decimals.
    function decimals(uint256 /*tokenId*/ ) public pure override returns (uint8) {
        return 0;
    }

    /// @dev Returns if a user has voted on a post.
    function hasVoted(address who, uint96 postId) public view returns (bool) {
        return _voted.get(_packVotedKey(who, postId));
    }

    /// @dev Returns the name for token `tokenId`.
    function name(uint256 tokenId) public pure override returns (string memory) {
        (uint96 postId, bool votedYes) = getPost(tokenId);

        if (votedYes) {
            return string(abi.encodePacked("Chandelier #", postId.toString()));
        } else {
            return string(abi.encodePacked("Not a Chandelier #", postId.toString()));
        }
    }

    /// @dev Returns the symbol for token `tokenId`.
    function symbol(uint256 tokenId) public pure override returns (string memory) {
        (uint96 postId, bool votedYes) = getPost(tokenId);

        if (votedYes) {
            return string(abi.encodePacked("CNOT-Y", postId.toString()));
        } else {
            return string(abi.encodePacked("CNOT-N", postId.toString()));
        }
    }

    /// @dev Returns the uri for `tokenId`.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        (uint96 postId, bool votedYes) = getPost(tokenId);

        require(postId < nextPostId, "ChandelierOrNot: invalid post id");

        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name":"',
            name(tokenId),
            '",',
            '"symbol":"',
            symbol(tokenId),
            '",',
            '"decimals":"',
            decimals(tokenId).toString(),
            '",',
            '"image":"',
            _imageURIs[postId],
            '",',
            '"votedYes":',
            votedYes ? "true" : "false",
            "}"
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(dataURI)));
    }

    // external functions

    /// @dev Returns if a post has more yes or no votes. Ties go to No.
    /// @dev This is very simple. Smarter things can be done off-chain.
    function winner(uint96 postId) external view returns (bool yesIsWinning, uint256 yesVotes, uint256 noVotes) {
        // this could be gas golfed, but i want readability
        uint256 noTokenId = getTokenId(postId, false);
        uint256 yesTokenId = noTokenId + 1;

        yesVotes = totalSupply[yesTokenId];
        noVotes = totalSupply[noTokenId];

        yesIsWinning = yesVotes > noVotes;
    }
}
