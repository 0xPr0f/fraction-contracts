pragma solidity ^0.8.12;

// SPDX-License-Identifier: MIT

interface FractionNFT {
    function mint(string calldata metaURI) external payable;
}

contract NFTRegistry {
    address[] public NFT;
    error Taken(string);

    function addNFTWatch(address _nftaddress) external {
        NFT.push(_nftaddress);
    }

    function removeNFTWatch() external {
        NFT.pop();
    }

    struct NFTdetails {
        string name;
        string ensName;
        string udName;
        string TwitterSocial;
        string github;
    }

    mapping(address => NFTdetails) details;

    string[] private chosennames;

    function setName(string calldata _name, string calldata _metadata)
        public
        payable
    {
        uint256 length = chosennames.length;
        for (uint256 i; i < length; ++i) {
            if (
                keccak256(abi.encode(chosennames[i])) ==
                keccak256(abi.encode(_name))
            ) {
                revert Taken("Name already choosen");
            }
            require(bytes(_name).length > 2, "Name too short");
            FractionNFT(NFT[0]).mint{value: msg.value}(_metadata);
            chosennames.push(_name);
            details[msg.sender].name = _name;
        }
    }

    function setEnsName(string calldata _ensname) public {
        require(bytes(_ensname).length > 2, "Name too short");
        string memory name = getName(msg.sender);
        require(bytes(name).length > 2, "Name too short");
        details[msg.sender].ensName = _ensname;
    }

    function setUdName(string calldata _nftname) public {
        require(bytes(_nftname).length > 2, "Name too short");
        string memory name = getName(msg.sender);
        require(bytes(name).length > 2, "Name too short");
        details[msg.sender].udName = _nftname;
    }

    function setTwitterSocial(string calldata _twitter) public {
        require(bytes(_twitter).length > 5, "Name too short");
        string memory name = getName(msg.sender);
        require(bytes(name).length > 2, "Name too short");
        details[msg.sender].TwitterSocial = _twitter;
    }

    function setGithub(string calldata _github) public {
        require(bytes(_github).length > 4, "Name too short");
        string memory name = getName(msg.sender);
        require(bytes(name).length > 2, "Name too short");
        details[msg.sender].github = _github;
    }

    function getName(address _address) public view returns (string memory) {
        string memory tempname = details[_address].name;
        if (bytes(tempname).length > 2) {
            return details[_address].name;
        } else {
            return "";
        }
    }

    function getEnsName(address _address) public view returns (string memory) {
        string memory tempname = details[_address].ensName;
        if (bytes(tempname).length > 2) {
            return details[_address].name;
        } else {
            return "";
        }
    }

    function getUdName(address _address) public view returns (string memory) {
        string memory tempname = details[_address].udName;
        if (bytes(tempname).length > 2) {
            return details[_address].name;
        } else {
            return "";
        }
    }

    function getTwitterSocail(address _address)
        public
        view
        returns (string memory)
    {
        string memory tempname = details[_address].TwitterSocial;
        if (bytes(tempname).length > 2) {
            return details[_address].TwitterSocial;
        } else {
            return "";
        }
    }

    function getGithub(address _address) public view returns (string memory) {
        string memory tempname = details[_address].github;
        if (bytes(tempname).length > 2) {
            return details[_address].github;
        } else {
            return "";
        }
    }
}
