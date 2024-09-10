/* global ethers */
/* eslint prefer-const: "off" */

import { OnceFactory__factory, AccessControl__factory, SafeProxyInit__factory, SafeProxy__factory, PluginManager__factory, ERC721Init__factory, ERC721__factory, ERC721AutoIncrementMintInit__factory, ERC721AutoIncrementMint__factory } from "../typechain";
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

const onceAddress = "0x6BA83ff46de9b7F5edD6140c97373201A187d9De" // Your ONCE address here
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

    const erc721AutoIncrementMintInit = ERC721AutoIncrementMintInit__factory.connect(
        deployedContracts[hre.network.name]["ERC721AutoIncrementMintInit"],
        deployer
    )

    const erc721AutoIncrementMint = ERC721AutoIncrementMint__factory.connect(
        deployedContracts[hre.network.name]["ERC721AutoIncrementMint"],
        deployer
    )

    const erc721Selectors = await erc721AutoIncrementMint.getFunctionSelectors();
    const erc721SingletonAddress = await erc721AutoIncrementMint.getSingletonAddress();

    const encodedUpdateFunctionData = await oncePluginManager.interface.encodeFunctionData("update", [
        [{
            pluginAddress: erc721SingletonAddress,
            action: UpdateActionType.add,
            functionSelectors: erc721Selectors
        }],
        erc721AutoIncrementMintInit.address,
        erc721AutoIncrementMintInit.interface.encodeFunctionData('init', [
            hre.ethers.utils.parseEther("0"),
            BigInt(0),
            "ipfs://your-token-metadata"
        ])
    ])
    

    console.log("--------------- Encoded Function Data ---------------")
    console.log(encodedUpdateFunctionData);

}

generateEncodedDeployOnceFunctionData().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});