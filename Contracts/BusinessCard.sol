// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BusinessCard is ERC721 {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Modifiers
    modifier onlyOwner() {
        require(owner == msg.sender, "You're not owner.");
        _;
    }

    string public baseURI = "ipfs://";
    address private owner;

    constructor() ERC721("BusinessCard", "BCard") {
        owner = msg.sender;
    }

    function mintBusinessCard() external {
        _tokenIds.increment();
        _mint(msg.sender, _tokenIds.current());
    }

    // set new metadata uri
    function setNewBaseUri(string memory _newBaseUri) external onlyOwner {
        baseURI = _newBaseUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();

        // I show the same nft metadata every 10 instead of NFT generation, Since it's a demo!
        tokenId = tokenId % 10;
        //

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }
}
