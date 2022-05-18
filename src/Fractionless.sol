// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title Fractionless
/// @author 0xPr0f | edited and gotten from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol
/// @notice contract standard for Fractionless

import {FRACTION1155} from "./utils/Fraction1155.sol";
import {IERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Fractionless is FRACTION1155 {
    event Wrapped(
        address indexed tokenwrapped,
        address tokenIn,
        uint256 amountIn,
        uint256 amountOut
    );
    event Unwrapped(
        address indexed tokenwrapped,
        address tokenIn,
        uint256 amountIn,
        uint256 amountOut
    );
    event FlashLoan(
        address indexed loaned,
        address indexed initiator,
        uint256 amount
    );
    event Received(
        address indexed to,
        address from,
        uint256 tokenId,
        uint256 amount,
        bytes data
    );
    event FlashMint(
        address indexed loaned,
        address indexed initiator,
        address indexed receiver,
        uint256 amount,
        uint256 burnable
    );
    event FlashBurn(address indexed initiator, uint256 burnt);
    error NotWrappableAsset();
    mapping(address => bool) public isAdmin;
    mapping(uint256 => uint256) public tokenIdTotalSupply;
    mapping(uint256 => uint256) public tokenIdWrappedSupply;
    mapping(address => uint256) balanceOfWrappedTokens;
    uint256 public tokenId;
    uint256 public AmountForId;
    address[] public currentlyAllowedAsset;
    address public owner;
    uint256 public power = 10**18;

    constructor() FRACTION1155("") {
        tokenId = 1;
        isAdmin[msg.sender] = true;
        owner = msg.sender;
    }

    /////////////// ERC1155 STUFF ////////////////
    modifier onlyAdmin() {
        require(isAdmin[msg.sender] == true, "Not admin");
        _;
    }

    function addWrappableAssets(address asset) external onlyAdmin {
        currentlyAllowedAsset.push(asset);
    }

    function removeWrappableAssets(uint256 assetid) external onlyAdmin {
        currentlyAllowedAsset[assetid] = address(0);
    }

    function stylishRemoveWrappableAssets(uint256 assetid) external onlyAdmin {
        uint256 currentlyAllowedAssetLength = currentlyAllowedAsset.length;
        require(assetid < currentlyAllowedAssetLength);
        currentlyAllowedAsset[assetid] = currentlyAllowedAsset[
            --currentlyAllowedAssetLength
        ];
        currentlyAllowedAsset.pop();
    }

    function viewWrappableAssets() external view returns (address[] memory) {
        return currentlyAllowedAsset;
    }

    function setAmountForId(uint256 amount) public onlyAdmin {
        AmountForId = amount;
    }

    function addAdmin(address newAdmin) public onlyAdmin {
        require(isAdmin[newAdmin] == false, "Already Admin");
        isAdmin[newAdmin] = true;
    }

    function mintWrap(
        address _to,
        uint256 amount,
        address assets
    ) external onlyAdmin returns (bool) {
        uint256 currentlyAllowedAssetLength = currentlyAllowedAsset.length;
        address assetToWrap;
        for (uint256 i; i < currentlyAllowedAssetLength; ++i) {
            if (currentlyAllowedAsset[i] == assets) {
                assetToWrap = assets;
            }
        }
        require(assetToWrap != address(0), "Unsafe Asset");

        tokenId = 1;
        bytes memory data = "";
        tokenIdTotalSupply[tokenId] += amount;
        tokenIdWrappedSupply[tokenId] += amount;
        balanceOfWrappedTokens[_to] += amount;
        _mint(_to, tokenId, amount, data);
        emit Wrapped(assetToWrap, address(this), amount, amount);
        return true;
    }

    function burnWrap(
        address _from,
        uint256 amount,
        address assets
    ) external onlyAdmin returns (bool) {
        require(balanceOf(_from, tokenId) >= amount, "Insufficient balance");
        tokenIdWrappedSupply[tokenId] -= amount;
        /*
Stop superfluid stream
        */
        balanceOfWrappedTokens[_from] -= amount;
        _burn(_from, tokenId, amount);
        emit Unwrapped(address(this), assets, amount, amount);
        return true;
    }

    ////////////// FlashMint Functionality //////////////////////////

    function flashBurn(address _from, uint256 amount)
        external
        onlyAdmin
        returns (bool)
    {
        require(
            balanceOf(msg.sender, tokenId) >= amount,
            "Cannot FlashBurn what you dont have"
        );
        _burn(_from, tokenId, amount);
        balanceOfWrappedTokens[_from] -= amount;
        emit FlashBurn(tx.origin, amount);
        return true;
    }

    function flashMint(
        address _to,
        uint256 amount,
        bytes calldata data
    ) external onlyAdmin returns (bool) {
        _mint(_to, tokenId, amount, data);
        balanceOfWrappedTokens[_to] += amount;
        emit FlashMint(address(this), tx.origin, msg.sender, amount, amount);
        return true;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        emit Received(operator, from, id, value, data);
        return bytes4(IERC1155Receiver.onERC1155Received.selector);
    }

    receive() external payable {}

    fallback() external payable {}

    ////// Transfer overrides ////////////

    /* @notice This could have easily be done with extra internal override function in the NFT standard to add some logic in specific areas in between the tranfer functions
     * But why do that ? lol 😂
     * This contract is NOT gas efficient
     */

    /* @notice This is a big problem when it comes to sending assets, there could be a big issue when the user sends assets and the stream isnt properly updated
     * giving them the ability to game the system
     */

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(
            fromBalance >= amount,
            "ERC1155: insufficient balance for transfer"
        );
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;
        balanceOfWrappedTokens[from] -= amount;
        balanceOfWrappedTokens[to] += amount;
        emit TransferSingle(operator, from, to, id, amount);
        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155: insufficient balance for transfer"
            );
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;

            balanceOfWrappedTokens[from] -= amount;
            balanceOfWrappedTokens[to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    function redrawToken(address tokensInWallet) external {
        IERC20(tokensInWallet).transfer(
            owner,
            IERC20(tokensInWallet).balanceOf(address(this))
        );
    }

    function redrawMain() external {
        payable(owner).transfer(address(this).balance);
    }
}
