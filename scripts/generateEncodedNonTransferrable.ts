/* global ethers */
/* eslint prefer-const: "off" */

import { OnceFactory__factory, AccessControl__factory, SafeProxyInit__factory, SafeProxy__factory, PluginManager__factory, ERC721Init__factory, ERC721__factory, ERC721AutoIncrementMintInit__factory, ERC721AutoIncrementMint__factory, ERC721NonTransferable__factory, ERC721NonTransferableInit, ERC721BalanceLimitInit__factory, ERC721NonTransferableInit__factory } from "../typechain";
import { ContractList, getDeployedContracts } from "../utils/helpers";
import hre from 'hardhat';


/* Use this script to generate hex-encoded function call data for updating a ONCE via the plugin manager. 
    This is particularly useful when using a third party UI to execute the update transaction. 

    The example below shows installing ERC721Mint functionality on a ONCE (assumes an ERC721 ONCE was already deployed).

    When calling this script via the command line remember to specify the appropriate network. 
    ie. npx hardhat run scripts/generateEncodedDeployOnceFunctionData.ts --network base
*/
enum UpdateActionType {
    add, replace, remove
}

const onceAddress = "0x43EB186C6623EAcdb4c1657bd33D05Ea162D13f6" // Your ONCE address here
async function generateEncodedDeployOnceFunctionData() {
    console.log("Generating encoded function data for updating a ONCE");

    const [deployer] = await hre.ethers.getSigners();
    const deployedContracts: ContractList = getDeployedContracts();

    const oncePluginManager = PluginManager__factory.connect(
        onceAddress,
        deployer
    )

    // Get the relevant init & plugins
    // Replace with any other plugin you'd like to install
    // If installing multiple plugins in once transaction remember to create a custom init contract

    const erc721NonTransferableInit = ERC721NonTransferableInit__factory.connect(
        deployedContracts[hre.network.name]["ERC721NonTransferableInit"],
        deployer
    )

    const erc721NonTransferable = ERC721NonTransferable__factory.connect(
        deployedContracts[hre.network.name]["ERC721NonTransferable"],
        deployer
    )

    const erc721Selectors = await erc721NonTransferable.getFunctionSelectors();
    const erc721SingletonAddress = await erc721NonTransferable.getSingletonAddress();

    const encodedUpdateFunctionData = await oncePluginManager.interface.encodeFunctionData("update", [
        [{
            pluginAddress: erc721SingletonAddress,
            action: UpdateActionType.add,
            functionSelectors: erc721Selectors
        }],
        erc721NonTransferableInit.address,
        erc721NonTransferableInit.interface.encodeFunctionData('init', [
            erc721NonTransferable.address,
        ])
    ])
    

    console.log("--------------- Encoded Function Data ---------------")
    console.log(encodedUpdateFunctionData);

}

generateEncodedDeployOnceFunctionData().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});