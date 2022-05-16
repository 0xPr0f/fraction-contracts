// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title FractionToken
/// @author 0xPr0f
/// @notice Token to trade on the FractionLess Protocol
//import {ERC20} from "https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract FractionToken is ERC20 {
    uint256 public power = 10**18;
    mapping(address => uint256) public mintTime;

    mapping(address => bool) public isAdmin;

    constructor() ERC20("Fraction Token", "FRACT", 18) {
        _mint(msg.sender, 100000 * power);
        isAdmin[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender] == true, "Cannot by pass time lol");
        _;
    }

    function addAdmin(address _newadmin) external onlyAdmin {
        isAdmin[_newadmin] = true;
    }

    function removeAdmin(address _newadmin) external onlyAdmin {
        isAdmin[_newadmin] = false;
    }

    function Faucetmint(address _to) external {
        require(
            mintTime[msg.sender] + 8 hours < block.timestamp,
            "comback next 8hrs to mint more tokens"
        );
        _mint(_to, 1000 * power);
    }

    function FaucetmintByPassTime(address _to) external onlyAdmin {
        _mint(_to, 1000 * power);
    }

    fallback() external payable {}

    receive() external payable {}
}
