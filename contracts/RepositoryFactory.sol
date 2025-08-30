// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract repositoryFactory {

    struct ownerRepository {
        address ownerAddress;
        string ownerName;
    }

    function createRepository(string memory _ownerRepository) public {

    }
}