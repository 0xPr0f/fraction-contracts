// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title FlashMintReceiver
/// @author 0xPr0f
/// @notice FlashMintReceiver interface for FractionlessWrapper

interface FlashMintReceiver {
    function executeTask(
        address _assets,
        address _to,
        address initiator,
        uint256 amount,
        bytes calldata data
    ) external;
}
