/* global ethers */
/* eslint prefer-const: "off" */

import { OnceFactory__factory, AccessControl__factory, SafeProxyInit__factory, SafeProxy__factory, PluginManager__factory, ERC721Init__factory, ERC721__factory } from "../typechain";
import { ContractList, getDeployedContracts } from "../utils/helpers";
import hre from 'hardhat';


/* Use this script to generate hex-encoded function call data for deploying a new ONCE via the ONCE Factory. 
    This is particularly useful when using a third party UI to execute the deployOnce transaction. 

    The example below shows deploying a ONCE with a standard ERC721 contract pre-installed.

    When calling this script via the command line remember to specify the appropriate network. 
    ie. npx hardhat run scripts/generateEncodedDeployOnceFunctionData.ts --network base
*/
enum UpdateActionType {
    add, replace, remove
}

const initialAdmin = "0x37b7c709D4f5a6cB1B5B595f45Ed20D177666847" // Update with the address you'd like to be granted admin access for the ONCE (this can be thought of as the "Owner")

async function generateEncodedDeployOnceFunctionData() {
    console.log("Generating encoded function data for deploying a new ONCE via ONCE factory");

    const [deployer] = await hre.ethers.getSigners();
    const deployedContracts: ContractList = getDeployedContracts();

    const OnceFactoryInstanceAddress = deployedContracts[hre.network.name]["OnceFactoryInstance"]

    const OnceFactoryInstance = OnceFactory__factory.connect(
        OnceFactoryInstanceAddress,
        deployer
    )

    // Get the relevant init & initial plugins
    // Replace with any initial plugins
    // If installing multiple initial plugins remember to create a custom init contract

    const erc721Init = ERC721Init__factory.connect(
        deployedContracts[hre.network.name]["ERC721Init"],
        deployer
    )

    const erc721 = ERC721__factory.connect(
        deployedContracts[hre.network.name]["ERC721"],
        deployer
    )

    const erc721Selectors = await erc721.getFunctionSelectors();
    const erc721SingletonAddress = await erc721.getSingletonAddress();

    const testingSalt = Date.now();

    const encodedDeployOnceFunctionData = await OnceFactoryInstance.interface.encodeFunctionData('deployOnce', [
        hre.ethers.utils.id(`layered.test.443e20e5${testingSalt}`), // Replace with your own salt, WAGMI!
        [{  
            roleToCreate: hre.ethers.utils.id("LAYERED_ONCE_UPDATE_ROLE"), 
            membersToAdd: [initialAdmin], // Adds the update role to the initialAdmin
            roleAdmin: hre.ethers.constants.HashZero
        },
        {  
            roleToCreate: hre.ethers.constants.HashZero,
            membersToAdd: [initialAdmin], // Adds the default admin role to the initialAdmin
            roleAdmin: hre.ethers.constants.HashZero
        }], // Add any additional roles here
        {
            initialUpdateInstructions: [{
                pluginAddress: erc721SingletonAddress,
                action: UpdateActionType.add,
                functionSelectors: erc721Selectors
            }],
            pluginInitializer: erc721Init.address,
            pluginInitializerCallData: erc721Init.interface.encodeFunctionData('init', [
                "Example",
                "EXT",
                ""
            ])
        },
        hre.ethers.constants.AddressZero, // Add a callback address here if desired
    ])

    console.log("--------------- Encoded Function Data ---------------")
    console.log(encodedDeployOnceFunctionData);

    const newOnceAddress = await OnceFactoryInstance.getOnceAddress(OnceFactoryInstanceAddress,
        hre.ethers.utils.id(`layered.test.443e20e5${testingSalt}`), // Replace with your own salt, WAGMI!
        [{  
            roleToCreate: hre.ethers.utils.id("LAYERED_ONCE_UPDATE_ROLE"), 
            membersToAdd: [initialAdmin], // Adds the update role to the initialAdmin
            roleAdmin: hre.ethers.constants.HashZero
        },
        {  
            roleToCreate: hre.ethers.constants.HashZero,
            membersToAdd: [initialAdmin], // Adds the default admin role to the initialAdmin
            roleAdmin: hre.ethers.constants.HashZero
        }], // Add any additional roles here
        {
            initialUpdateInstructions: [{
                pluginAddress: erc721SingletonAddress,
                action: UpdateActionType.add,
                functionSelectors: erc721Selectors
            }],
            pluginInitializer: erc721Init.address,
            pluginInitializerCallData: erc721Init.interface.encodeFunctionData('init', [
                "Example",
                "EXT",
                ""
            ])
        }, // Add a callback address here if desired
    )

    console.log("--------------- Counterfactual ONCE Address ---------------")
    console.log(newOnceAddress);

}

generateEncodedDeployOnceFunctionData().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});