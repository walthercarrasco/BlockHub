// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "contracts/Repository.sol";

contract RepositoryFactory is ERC721Enumerable {
    
    constructor() ERC721("RepositoryFactory", "REPO") {}

    mapping (uint256 => Repository) private repositories;

    function createRepository(string memory _repoName, string memory _repoCID) public {
        uint256 tokenId = totalSupply() + 1; // token IDs start at 1
        _safeMint(msg.sender, tokenId);

        repositories[tokenId] = new Repository(_repoName, _repoCID, msg.sender);
        emit CreatedSuccessfully(tokenId, msg.sender, _repoCID);
    }

    function getAllCIDsByOwner() external view returns (string[] memory folderCIDs, uint256[] memory tokens) {
        uint256 count = balanceOf(msg.sender); // number of NFTs owned
        folderCIDs = new string[](count);
        tokens = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i); // ERC721Enumerable
            folderCIDs[i] = repositories[tokenId].getRepoFolderCID();
            tokens[i] = tokenId;
        }
    }

    function processCommit(uint256 _tokenId, string memory message) public {
        Repository repo = repositories[_tokenId];
        
        // Add commit to repository
        repo.addCommit(message, msg.sender);


        // Emit event
        emit processedCommit(_tokenId, repo.getRepoOwner(), msg.sender, repo.getRepoFolderCID());
    }

    function retrieveCommits(uint256 _tokenId) public view returns(string[] memory messages, uint256[] memory timestamps, address[] memory committers){
        Repository repo = repositories[_tokenId];
        return repo.getAllCommits();
    }

    event CreatedSuccessfully(
        uint256 indexed tokenId,       // ID of the NFT minted
        address indexed owner,        // Name of the repository
        string repoCID               // IPFS folder CID
    );

    event processedCommit(
        uint256 indexed tokenId,       // ID of the NFT minted
        address indexed owner,        // Name of the repository
        address indexed committer,    // Address of the committer
        string repoCID               // IPFS folder CID
    );
}