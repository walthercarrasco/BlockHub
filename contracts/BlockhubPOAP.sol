// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BlockhubPOAP is ERC1155, Ownable {
    using Strings for uint256;

    uint256 public constant FIRST_COMMIT = 0;
    uint256 public constant REPO_CREATOR = 1;
    uint256 public constant CONTRIBUTOR = 2;
    uint256 public constant MAINTAINER = 3;
    uint256 public constant ACTIVE_DEVELOPER = 4;

    struct BadgeInfo {
        string name;
        string description;
        string imageURI;
        bool isActive;
    }

    mapping(uint256 => BadgeInfo) public badgeInfo;
    mapping(address => mapping(uint256 => bool)) public hasBadge;
    mapping(address => uint256) public commitCount;
    mapping(address => uint256) public repoCount;
    mapping(address => uint256) public approvalCount;
    mapping(address => mapping(uint256 => uint256)) public badgeEarnedAt;

    address public repositoryFactory;

    constructor() ERC1155("") Ownable(msg.sender) {
        _initializeBadges();
    }

    function _initializeBadges() private {
        badgeInfo[FIRST_COMMIT] = BadgeInfo({
            name: "First Commit",
            description: "Made your first commit to any repository",
            imageURI: "ipfs://QmFirstCommit.../metadata.json",
            isActive: true
        });

        badgeInfo[REPO_CREATOR] = BadgeInfo({
            name: "Repository Creator",
            description: "Created your first repository",
            imageURI: "ipfs://QmRepoCreator.../metadata.json",
            isActive: true
        });

        badgeInfo[CONTRIBUTOR] = BadgeInfo({
            name: "Contributor",
            description: "Made 5 or more commits across repositories",
            imageURI: "ipfs://QmContributor.../metadata.json",
            isActive: true
        });

        badgeInfo[MAINTAINER] = BadgeInfo({
            name: "Maintainer",
            description: "Approved 10 or more commits as repository owner",
            imageURI: "ipfs://QmMaintainer.../metadata.json",
            isActive: true
        });

        badgeInfo[ACTIVE_DEVELOPER] = BadgeInfo({
            name: "Active Developer",
            description: "Made 30+ commits in the last month",
            imageURI: "ipfs://QmActiveDev.../metadata.json",
            isActive: true
        });
    }

    function setRepositoryFactory(address _factory) external onlyOwner {
        repositoryFactory = _factory;
    }

    modifier onlyFactory() {
        require(msg.sender == repositoryFactory, "Only factory can mint badges");
        _;
    }

    function mintBadge(
        address to,
        uint256 badgeId,
        string memory repoName
    ) external onlyFactory {
        require(badgeInfo[badgeId].isActive, "Badge type not active");
        require(!hasBadge[to][badgeId], "Badge already earned");

        hasBadge[to][badgeId] = true;
        badgeEarnedAt[to][badgeId] = block.timestamp;

        _mint(to, badgeId, 1, "");

        emit BadgeEarned(to, badgeId, repoName, block.timestamp);
    }

    function updateUserStats(
        address user,
        uint256 newCommits,
        uint256 newRepos,
        uint256 newApprovals
    ) external onlyFactory {
        commitCount[user] += newCommits;
        repoCount[user] += newRepos;
        approvalCount[user] += newApprovals;
    }

    function getUserBadges(address user) external view returns (
        uint256[] memory badgeIds,
        string[] memory names,
        uint256[] memory timestamps
    ) {
        uint256 badgeCount = 0;
        for (uint256 i = 0; i <= ACTIVE_DEVELOPER; i++) {
            if (hasBadge[user][i]) {
                badgeCount++;
            }
        }

        badgeIds = new uint256[](badgeCount);
        names = new string[](badgeCount);
        timestamps = new uint256[](badgeCount);

        uint256 index = 0;
        for (uint256 i = 0; i <= ACTIVE_DEVELOPER; i++) {
            if (hasBadge[user][i]) {
                badgeIds[index] = i;
                names[index] = badgeInfo[i].name;
                timestamps[index] = badgeEarnedAt[user][i];
                index++;
            }
        }
    }

    function getBadgeInfo(uint256 badgeId) external view returns (BadgeInfo memory) {
        return badgeInfo[badgeId];
    }

    function userHasBadge(address user, uint256 badgeId) external view returns (bool) {
        return hasBadge[user][badgeId];
    }
    function getUserStats(address user) external view returns (
        uint256 totalCommits,
        uint256 totalRepos,
        uint256 totalApprovals,
        uint256 totalBadges
    ) {
        totalCommits = commitCount[user];
        totalRepos = repoCount[user];
        totalApprovals = approvalCount[user];

        for (uint256 i = 0; i <= ACTIVE_DEVELOPER; i++) {
            if (hasBadge[user][i]) {
                totalBadges++;
            }
        }
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(badgeInfo[tokenId].isActive, "Badge does not exist");
        return badgeInfo[tokenId].imageURI;
    }

    function updateBadgeInfo(
        uint256 badgeId,
        string memory name,
        string memory description,
        string memory imageURI
    ) external onlyOwner {
        badgeInfo[badgeId].name = name;
        badgeInfo[badgeId].description = description;
        badgeInfo[badgeId].imageURI = imageURI;
    }

    function deactivateBadge(uint256 badgeId) external onlyOwner {
        badgeInfo[badgeId].isActive = false;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        revert("Badges are non-transferable");
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override {
        revert("Badges are non-transferable");
    }

    event BadgeEarned(
        address indexed user,
        uint256 indexed badgeId,
        string repoName,
        uint256 timestamp
    );


}