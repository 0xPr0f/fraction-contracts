> **Warning**
>
> - This contracts were made in a short period of time for a hackathons and was not properly audited.
> - This contracts may serve as templates for other projects.
> - This contracts may contains severe bugs (it actually contains some bugs, but they are features 😝).
> - The contracts of this project will constantly be worked on (updated) and upgraded.

### [Fraction interface](https://github.com/0xPr0f/Fraction-interface/tree/maindev)

# Fraction contracts

This is the contracts that governs all fractions logic, this contracts include the wrapping of erc20(stables) mechanism, the staking of wrapped erc20(stables), Fraction bounded NFTs (soul bounded) to increase rewards earned by verification, The in-built ability to perform flash loan(flash-mint) (havent test lol)

### Deployed on Mumbai : most contracts should be verified to see the code

#### Fraction Token : [FRACT](https://mumbai.polygonscan.com/address/0x953f88014255241332d8841c34921572db112d65)

https://mumbai.polygonscan.com/address/0x953f88014255241332d8841c34921572db112d65

#### Super Fraction Token : [FRACTx](https://console.superfluid.finance/mumbai/supertokens/0xbcC35477b5b360713C8CE874EE936a0FB14b5E3c?tab=streams)

https://console.superfluid.finance/mumbai/supertokens/0xbcC35477b5b360713C8CE874EE936a0FB14b5E3c?tab=streams

#### Fractionless : [FRACTIONLESS](https://mumbai.polygonscan.com/address/0x147Aef142CCebf9902ec57A369D4aB1B6126Fc69)

https://mumbai.polygonscan.com/address/0x147Aef142CCebf9902ec57A369D4aB1B6126Fc69

#### FractionWrapper : [FRACTWRAPPED](https://mumbai.polygonscan.com/address/0xb68dF2721e747a30A611D9279169d36E448C600C)

https://mumbai.polygonscan.com/address/0xb68dF2721e747a30A611D9279169d36E448C600C  
due to reasons, contract could not be verified, but [here is the ABI](https://bafybeigggr4oxyghkgpx5o4gl23rsw4lugqewptuffegvps7uaoh44vqsy.ipfs.infura-ipfs.io/)

#### NFT Registry : [NFTRegistry](https://mumbai.polygonscan.com/address/0x34c93Cf06bADc3c64c18d02DD2dFb5f43a32C472)

https://mumbai.polygonscan.com/address/0x34c93Cf06bADc3c64c18d02DD2dFb5f43a32C472

#### FractionNFT : [FractionNFT](https://mumbai.polygonscan.com/address/0x8b78A188f3941BdF5BcDE61A0c32C68A4044fdbB)

https://mumbai.polygonscan.com/address/0x8b78A188f3941BdF5BcDE61A0c32C68A4044fdbB

# contract

### These contracts were made using foundry

To get the contracts running, clone the repo and then run

```
forge install
```

and then

```
npm install
```

Then you build the contracts and write test and fixs some problems lol

For the flash mint functionality to work, the reciever (if a contract) has to have a onERC1155Receiver function (implementation)
