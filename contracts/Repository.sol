// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Repository is ERC721{
    struct Commit{
        string commitMsg;
        uint256 timestamp;
        address committer;
    }
    string repoName;
    string repoFolderCID;
    address repoOwnerAddr;
    Commit[] private _commits; // array to store commit CIDs

    constructor(string memory _repoName, string memory _repoCID, address _creator) ERC721("RepositoryNFT", "REPO"){
        repoName = _repoName;
        repoFolderCID = _repoCID;
        repoOwnerAddr = _creator;

    }

    function getRepoFolderCID() external view returns (string memory) {
        return repoFolderCID;
    }


   //Modificador para indicar que solo el dueno puede ejecutar
    modifier onlyRepoOwner() {
        require(ownerOf(1) == msg.sender, "No eres el dueno del repositorio");
        _;
    }

    //  Simulacion de "aprobar un cambio importante"
    function approveChange(string calldata changeHash, uint256 rewardAmount) external onlyRepoOwner {
        emit ChangeApproved(changeHash, msg.sender, repoOwnerAddr, rewardAmount);
    }

    event ChangeApproved(
        string changeHash,
        address contributor,
        address approvedBy,
        uint256 rewardAmount
    );

    // Add a new commit
    function addCommit(string memory _commitMsg, address _committer) external {
        Commit memory newCommit = Commit({
            commitMsg: _commitMsg,
            timestamp: block.timestamp,  // current block timestamp
            committer: _committer
        });
        _commits.push(newCommit);
    }

  function getAllCommits() external view returns (string[] memory messages, uint256[] memory timestamps, address[] memory committers) {
        uint256 count = _commits.length;
        messages = new string[](count);
        timestamps = new uint256[](count);
        committers = new address[](count);

        for (uint256 i = 0; i < count; i++) {
            Commit storage c = _commits[i];
            messages[i] = c.commitMsg;
            timestamps[i] = c.timestamp;
            committers[i] = c.committer;
        }
    }

    // Get owner
    function getRepoOwner() external view returns (address) {
        return repoOwnerAddr;
    }




    
}