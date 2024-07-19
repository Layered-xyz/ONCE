/* global ethers */
/* eslint prefer-const: "off" */

import { OnceFactory__factory } from "../typechain";
import { ContractList, getDeployedContracts } from "../utils/helpers";
import hre from 'hardhat';

enum UpdateActionType {
    add, replace, remove
}

async function deployOnce() {
    console.log("Deploying New Once on network", hre.network.name);

    const [deployer] = await hre.ethers.getSigners();
    const deployedContracts: ContractList = getDeployedContracts();

    const OnceFactoryInstanceAddress = deployedContracts[hre.network.name]["OnceFactoryInstance"]

    const OnceFactoryInstance = OnceFactory__factory.connect(
        OnceFactoryInstanceAddress,
        deployer
    )

    /* 
    Prepare initial update instructions here

    Get plugin addresses and corresponding function selectors using the IOncePlugin functions
    Then populate the update instructions below.

    Remember that update instructions affect the salt used for the create2 deployment

    */

    const deployTx = await OnceFactoryInstance.deployOnce(
        hre.ethers.utils.id("layered.test.443e20e5"), // Replace with your own salt, WAGMI!
        [{  
            roleToCreate: hre.ethers.utils.id("LAYERED_ONCE_UPDATE_ROLE"), // Role for updating plugins
            membersToAdd: [deployer.address],
            roleAdmin: hre.ethers.constants.HashZero
        },
        {  
            roleToCreate: hre.ethers.constants.HashZero, // Default admin role
            membersToAdd: [deployer.address],
            roleAdmin: hre.ethers.constants.HashZero
        }], // Add any additional roles here
        {
            initialUpdateInstructions: [],
            pluginInitializer: hre.ethers.constants.AddressZero,
            pluginInitializerCallData: hre.ethers.constants.HashZero
        },
        hre.ethers.constants.AddressZero,
    )
    console.log("deploy tx: ", deployTx);

    const deployReceipt = await deployTx.wait();

    console.log("deploy receipt", deployReceipt);

    const onceDeploymentEvent = deployReceipt.events?.find((event) => event.event === 'onceDeployment');
        
    const newOnceAddress = onceDeploymentEvent?.args?.once

    console.log("deployed new Once at ", newOnceAddress);

    // Perform any operations on the new once here ie. updating access controls. This can also be done via a callback contract supplied to the factory during deployment

}

deployOnce().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});