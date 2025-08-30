// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Repository is ERC721{
    struct Commit{
        string commitMsg;
        uint256 timestamp;
        address payable committer;
        string commitCID;
        uint256 status;
    }
    string repoName;
    string repoFolderCID;
    address repoOwnerAddr;
    Commit[] private _commits;

    constructor(string memory _repoName, string memory _repoCID, address _creator) ERC721("RepositoryNFT", "REPO"){
        repoName = _repoName;
        repoFolderCID = _repoCID;
        repoOwnerAddr = _creator;
    }

    receive() external payable {}

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

   //Modificador para indicar que solo el dueno puede ejecutar
    modifier onlyRepoOwner(address sender) {
        require(sender == repoOwnerAddr, "No eres el dueno del repositorio");
        _;
    }

    // Get Folder CID
    function getRepoFolderCID() external view returns (string memory) {
        return repoFolderCID;
    } 

    // Get owner
    function getRepoOwner() external view returns (address) {
        return repoOwnerAddr;
    }

    function getCommits() external view returns (
        string[] memory messages, 
        uint256[] memory timestamps, 
        address[] memory committers, 
        uint256 [] memory status) 
        {
        uint256 count = _commits.length;
        messages = new string[](count);
        timestamps = new uint256[](count);
        committers = new address[](count);
        status = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            Commit storage c = _commits[i];
            messages[i] = c.commitMsg;
            timestamps[i] = c.timestamp;
            committers[i] = c.committer;
            status[i] = c.status;
        }
    } 

    // Add a new pending commit
    function addPendingCommit(string memory _commitMsg, address payable _committer, string memory _commitCID) external {
        Commit memory newCommit = Commit({
            commitMsg: _commitMsg,
            timestamp: block.timestamp,  // current block timestamp
            committer: _committer,
            commitCID: _commitCID,
            status: 0
        });
        _commits.push(newCommit);
    }

    //Accept pending commit
    function acceptCommit(uint256 _commitIndex, uint256 rewardAmount, address sender) external payable onlyRepoOwner(sender){
        Commit storage c = _commits[_commitIndex];
        require(c.status == 0, "Commit already processed");
        require(address(this).balance >= rewardAmount, "Not enough ETH in contract");

        // Mark commit as accepted
        c.status = 1;
        repoFolderCID = c.commitCID;

        // Pay committer
        (bool success, ) = c.committer.call{value: rewardAmount}("");
        require(success, "Payment failed");
    }

    // Reject a commit without paying
    function rejectCommit(uint256 _commitIndex, address sender) external onlyRepoOwner(sender) returns (address){
        Commit storage c = _commits[_commitIndex];
        require(c.status == 0, "Commit already processed");
        c.status = 2;
        return c.committer;
    }
}