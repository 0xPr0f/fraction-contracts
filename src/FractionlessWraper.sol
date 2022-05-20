// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title FractionlessWrapper
/// @author 0xPr0f
/// @notice contract wrapper and access point for Fractionless

import {ISuperfluid, ISuperToken} from "ethereum-contracts/packages/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
//"@superfluid-finance/ethereum-monorepo/packages/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {IConstantFlowAgreementV1} from "ethereum-contracts/packages/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import {IInstantDistributionAgreementV1} from "ethereum-contracts/packages/ethereum-contracts/contracts/interfaces/agreements/IInstantDistributionAgreementV1.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./Fractionless.sol";
import {FlashMintReceiver} from "./utils/FlashMintReciever.sol";

contract FractionlessWrapper {
    event Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes data
    );
    mapping(address => uint256) public wrappedAssets;
    mapping(address => uint256) public stakedWrappedFLTokens;
    uint256 public power = 10**18;
    Fractionless public immutable fractionless;
    uint256 public contractUpgradedFRACTbalance;
    uint256 public TotalWrappedFLTokens;
    address immutable owner;
    uint256 public TotalStakedFLTokens;
    ISuperfluid public immutable host;
    uint256 public constant WRAP_REWARD = 100_000;
    ISuperToken public immutable streamingtoken;
    error NotApproved(string, address, string);

    constructor(
        address payable _fraction,
        address _host,
        address _supertoken
    ) {
        // fractionless contract when deployed ::: test (0xd2b09bAaE776274D4A0A9b417cF4F2DAAD9342e2)
        // host for mumbai : 0xEB796bdb90fFA0f28255275e16936D25d3418603
        // address of the super token ::: test (0xD5A0f1DCD5503471BF7DbbfB81F6eF1cCe8C392f )
        host = ISuperfluid(_host);
        fractionless = Fractionless(_fraction);
        owner = msg.sender;
        superfluidinit();
        streamingtoken = ISuperToken(_supertoken);
    }

    ////////////////// SUPERFLUID INIT ///////////////////////////
    using CFAv1Library for CFAv1Library.InitData;

    //initialize cfaV1 variable
    CFAv1Library.InitData public cfaV1;

    // host for mumbai : 0xEB796bdb90fFA0f28255275e16936D25d3418603
    function superfluidinit() private {
        //initialize InitData struct, and set equal to cfaV1
        cfaV1 = CFAv1Library.InitData(
            host,
            //here, we are deriving the address of the CFA using the host contract
            IConstantFlowAgreementV1(
                address(
                    host.getAgreementClass(
                        keccak256(
                            "org.superfluid-finance.agreements.ConstantFlowAgreement.v1"
                        )
                    )
                )
            )
        );
    }

    ///////////////// DAI WRAPPING STUFF //////////////////////////

    //------------ wrap having trouble with no errors message --------------------------
    /// @notice wraps stable into ERC1155 ready for interests
    /// @param _amountOfAsset - the amount of stable to wrap
    /// @param assets - the asset (stable) to wrap
    /// @return true - confirming the assets was wrapped
    function wrap(uint256 _amountOfAsset, address assets)
        external
        returns (bool)
    {
        uint256 amount = _amountOfAsset * power;
        // i dont have to get the og value here
        fractionless.mintWrap(msg.sender, _amountOfAsset, assets);
        TotalWrappedFLTokens += _amountOfAsset;
        require(
            IERC20(assets).balanceOf(msg.sender) >= amount,
            "Insufficient balance"
        );

        // make sure the user has been approved
        // make sure the user has been approved
        IERC20(assets).transferFrom(msg.sender, address(this), amount);
        if (wrappedAssets[msg.sender] == 0) {
            _startStream(msg.sender, _amountOfAsset, WRAP_REWARD);
        } else {
            uint256 _updateStreamamount = wrappedAssets[msg.sender] +
                _amountOfAsset;
            _updateStream(msg.sender, _updateStreamamount);
        }
        wrappedAssets[msg.sender] += _amountOfAsset;
        return true;
    }

    function _startStream(
        address receiver,
        uint256 amount,
        uint256 rate
    ) internal {
        int96 flowRate = int96(uint96(amount) * uint96(rate));
        cfaV1.createFlow(receiver, streamingtoken, flowRate);
    }

    /*
    function updateOperatorPermissions() private {
      cfaV1.authorizeFlowOperatorWithFullControl(address(0),streamingtoken);
    }
    */

    function _updateStream(address receiver, uint256 amount) internal {
        int96 flowRate = int96(uint96(amount) * uint96(WRAP_REWARD)) + 20;
        cfaV1.updateFlow(receiver, streamingtoken, flowRate);
    }

    function _deleteStream() internal {
        cfaV1.deleteFlow(address(this), msg.sender, streamingtoken);
    }

    function deleteStream() external {
        cfaV1.deleteFlow(address(this), msg.sender, streamingtoken);
    }

    function unwrap(uint256 _amountOfAssetToBurn, address assets)
        external
        returns (bool)
    {
        /// @notice approve must be called manually from wrapAsset smart contract

        TotalWrappedFLTokens += _amountOfAssetToBurn;
        fractionless.burnWrap(msg.sender, _amountOfAssetToBurn, assets);
        IERC20(assets).transfer(msg.sender, _amountOfAssetToBurn * power);
        uint256 _updateStreamamount = wrappedAssets[msg.sender] -
            _amountOfAssetToBurn;
        if (_updateStreamamount > 0) {
            _updateStream(msg.sender, _updateStreamamount);
        } else {
            _deleteStream();
        }
        wrappedAssets[msg.sender] -= _amountOfAssetToBurn;
        return true;
    }

    function stake(uint256 amount) external {
        ///// Approve contract to spend fractionless token funds //////////
        require(
            fractionless.balanceOf(msg.sender, 1) >= amount,
            "Insufficient balance"
        );
        bytes memory data = "";
        TotalStakedFLTokens += amount;
        fractionless.safeTransferFrom(
            msg.sender,
            address(this),
            1,
            amount,
            data
        );
        stakedWrappedFLTokens[msg.sender] += amount;
        TotalWrappedFLTokens -= amount;
        _updateStream(msg.sender, wrappedAssets[msg.sender] + amount);
        wrappedAssets[msg.sender] -= amount;
    }

    function unstake(uint256 amount) external {
        ///// Approve contract to spend token funds //////////
        require(
            amount <= stakedWrappedFLTokens[msg.sender],
            "Insufficient staked balance"
        );
        bytes memory data = "";
        fractionless.safeTransferFrom(
            address(this),
            msg.sender,
            1,
            amount,
            data
        );
        TotalStakedFLTokens -= amount;
        stakedWrappedFLTokens[msg.sender] -= amount;
        _updateStream(
            msg.sender,
            (stakedWrappedFLTokens[msg.sender] - amount) + 1
        );
        TotalWrappedFLTokens += amount;
        wrappedAssets[msg.sender] += amount;
    }

    /// @dev ISuperToken.upgrade implementation
    function upgradeContractToken(
        address superToken,
        address normalToken_underlyingassets,
        uint256 amount
    ) external {
        require(owner == msg.sender, "Cannot updrage contract tokens");
        IERC20(normalToken_underlyingassets).approve(superToken, amount);
        contractUpgradedFRACTbalance = amount;
        ISuperToken(superToken).upgrade(amount);
    }

    /*
    function upgradeUserToken(address superToken,address normalToken_underlyingassets,uint256 amount) external {
    if (IERC20(normalToken_underlyingassets).allowance(msg.sender,superToken) < amount)
    {
       revert NotApproved("Approve",superToken,"to spend more normal tokens");
    }    
       ISuperToken(superToken).upgrade(amount);
    }
*/
    /// @dev ISuperToken.downgrade implementation
    function downgradeContractToken(uint256 amount, address superToken)
        external
    {
        require(owner == msg.sender, "Cannot updrage contract tokens");
        ISuperToken(superToken).downgrade(amount);
    }

    /*
     function downgradeUserToken(uint256 amount,address superToken) external {
        ISuperToken(superToken).downgrade(amount);
    }
*/
    /*function createFlow2Receiver(address receiver, ISuperToken DAIx, int96 flowRate) external {
        cfaV1.createFlow(receiver, DAIx, flowRate);
      }*/

    ///////////////////// FLASH MINT ///////////////////////////////

    /// @notice flashmint stable wrapper
    /// @param amount - the amount of wrapper
    /// @param data - the data
    ///@notice minting pure 1155, no need to power
    function flashmint(uint256 amount, bytes calldata data) public {
        fractionless.flashMint(msg.sender, amount, data);
        /// @notice callback function
        /// @param mintUsage(address loanedAssets,address initiator ,uint amoutLoaned, bytes calldata data)
        /// @return true
        IFlashMintReceiver(msg.sender).executeTask(
            address(fractionless),
            msg.sender,
            tx.origin,
            amount,
            data
        );

        fractionless.flashBurn(msg.sender, amount);
    }

    //////////////////////////////////////////////////////////////////

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
