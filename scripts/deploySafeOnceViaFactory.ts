/* global ethers */
/* eslint prefer-const: "off" */

import { OnceFactory__factory, AccessControl__factory, SafeProxyInit__factory, SafeProxy__factory, PluginManager__factory } from "../typechain";
import { ContractList, getDeployedContracts } from "../utils/helpers";
import hre from 'hardhat';

enum UpdateActionType {
    add, replace, remove
}

async function deployOnceAndInstallSafe() {
    console.log("Deploying New Once with Safe on network", hre.network.name);

    const [deployer] = await hre.ethers.getSigners();
    const deployedContracts: ContractList = getDeployedContracts();

    const OnceFactoryInstanceAddress = deployedContracts[hre.network.name]["OnceFactoryInstance"]

    const OnceFactoryInstance = OnceFactory__factory.connect(
        OnceFactoryInstanceAddress,
        deployer
    )

    const safeInit = SafeProxyInit__factory.connect(
        deployedContracts[hre.network.name]["SafeProxyInit"],
        deployer
    )

    const safeProxy = SafeProxy__factory.connect(
        deployedContracts[hre.network.name]["SafeProxy"],
        deployer
    )

    const safeProxySelectors = await safeProxy.getFunctionSelectors();
    const safeProxySingletonAddress = await safeProxy.getSingletonAddress();

    const deployTx = await OnceFactoryInstance.deployOnce(
        hre.ethers.utils.id("layered.test.443e20e5"), // Replace with your own salt, WAGMI!
        [{  
            roleToCreate: hre.ethers.utils.id("LAYERED_ONCE_UPDATE_ROLE"), 
            membersToAdd: [deployer.address],
            roleAdmin: hre.ethers.constants.HashZero
        },
        {  
            roleToCreate: hre.ethers.constants.HashZero,
            membersToAdd: [deployer.address],
            roleAdmin: hre.ethers.constants.HashZero
        }], // Add any additional roles here
        {
            initialUpdateInstructions: [{
                pluginAddress: safeProxySingletonAddress,
                action: UpdateActionType.add,
                functionSelectors: safeProxySelectors
            }],
            pluginInitializer: safeInit.address,
            pluginInitializerCallData: safeInit.interface.encodeFunctionData('init', [
                safeProxySingletonAddress,
                [deployer.address],
                1,
                hre.ethers.constants.AddressZero,
                hre.ethers.constants.HashZero,
                '0xfd0732Dc9E303f09fCEf3a7388Ad10A83459Ec99', // Compatibility fallback handler for 1.4.1
                hre.ethers.constants.AddressZero,
                0,
                hre.ethers.constants.AddressZero
            ])
        },
        hre.ethers.constants.AddressZero,
    )
    console.log("deploy tx: ", deployTx);

    const deployReceipt = await deployTx.wait();

    console.log("deploy receipt", deployReceipt);

    const onceDeploymentEvent = deployReceipt.events?.find((event) => event.event === 'onceDeployment');
        
    const newOnceAddress = onceDeploymentEvent?.args?.once

    console.log("deployed new Once at ", newOnceAddress);

    const newOnceAccessControl = AccessControl__factory.connect(
        newOnceAddress,
        deployer
    )

    await newOnceAccessControl.grantRole(hre.ethers.utils.id("LAYERED_ONCE_UPDATE_ROLE"), newOnceAddress);
    await newOnceAccessControl.grantRole(hre.ethers.constants.HashZero, newOnceAddress);

    console.log("Access control roles granted to Once. This script did not renounce roles from the deployer, you must renounce roles manually if desired")

    const newOncePluginManager = PluginManager__factory.connect(
        newOnceAddress,
        deployer
    )

    await newOncePluginManager.updateDefaultFallback(safeProxySingletonAddress);

    console.log("Updated default fallback to safe singleton");

}

deployOnceAndInstallSafe().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});