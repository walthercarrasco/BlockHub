// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "contracts/Repository.sol";

contract RepositoryFactory is ERC721Enumerable {
    
    constructor() ERC721("RepositoryFactory", "REPO") {}

    mapping (uint256 => Repository) private repositories;

    // Create Repository
    function createRepository(string memory _repoName, string memory _repoCID) public {
        uint256 tokenId = totalSupply() + 1; // token IDs start at 1
        _safeMint(msg.sender, tokenId);

        repositories[tokenId] = new Repository(_repoName, _repoCID, msg.sender);
        emit createdSuccessfully(tokenId, msg.sender, _repoCID);
    }

    //Deposit ETH into repository
    function depositToRepo(uint256 _tokenId) external payable {
        Repository repo = repositories[_tokenId];
        require(msg.value > 0, "Must send ETH");

        // Forward ETH to the repository contract
        (bool success, ) = address(repo).call{value: msg.value}("");
        require(success, "ETH deposit failed");
        emit depositedETH(_tokenId, msg.sender, msg.value);
    }
    
    //Get all repositories of Owner
    function getAllReposByOwner() external view returns (string[] memory folderCIDs, uint256[] memory tokens) {
        uint256 count = balanceOf(msg.sender); // number of NFTs owned
        folderCIDs = new string[](count);
        tokens = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i); // ERC721Enumerable
            folderCIDs[i] = repositories[tokenId].getRepoFolderCID();
            tokens[i] = tokenId;
        }
    }

    //Add to list of pending commits
    function processNewCommit(
        uint256 _tokenId, 
        string memory message, 
        string memory commitCID) public 
    {
        Repository repo = repositories[_tokenId];
        repo.addPendingCommit(message, payable (msg.sender), commitCID);
        emit processedCommit(_tokenId, repo.getRepoOwner(), msg.sender, repo.getRepoFolderCID());
    }
    
    //Approve pending commit
    function approveCommit(
        uint256 _tokenId, 
        uint256 commitIndex,
        uint256 reward) public payable
    {
        Repository repo = repositories[_tokenId];
        repo.acceptCommit(commitIndex, reward, msg.sender);
        emit approvedCommit(_tokenId, repo.getRepoOwner(), repo.getRepoFolderCID());
    }

    //Reject pending commit
    function rejectCommit(
        uint256 _tokenId,
        uint256 commitIndex) public
    {
        Repository repo = repositories[_tokenId];
        address commiter = repo.rejectCommit(commitIndex, msg.sender);
        emit rejectedCommit(commiter, repo.getRepoOwner(), repo.getRepoFolderCID());
    }

    //Get all repository commits (use for history)
    function retrieveCommits(uint256 _tokenId) public view returns(
        string[] memory messages, 
        uint256[] memory timestamps, 
        address[] memory committers, 
        uint256[] memory status)
    {
        Repository repo = repositories[_tokenId];
        return repo.getCommits();
    }

    function getBalance(uint256 _tokenId) public view returns(uint256){
        return repositories[_tokenId].getBalance();
    }

    event createdSuccessfully(
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

    event approvedCommit(
        uint256 indexed tokenId,       // ID of the NFT minted
        address indexed owner,        // Name of the repository
        string repoCID  
    );

    event rejectedCommit(
        address indexed committer,
        address indexed rejectedBy,
        string repoCID
    );

    event depositedETH(
        uint256 indexed tokenId,       // ID of the NFT minted
        address indexed owner,        // Name of the repository
        uint256 amount
    );
}