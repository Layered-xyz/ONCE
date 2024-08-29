import { ethers, deployments, getNamedAccounts } from "hardhat";

import { utils } from "ethers";
import { expect } from "chai";

import { Once, OnceFactory, PluginManager, IPluginManager, PluginViewer, IPluginViewer, OnceInit, OnceFactoryInit, AccessControl, Once__factory, SafeProxy, SafeProxyInit, SafeL2, Safe, StorageSetter, Reverter, Metadata } from "../typechain";

enum UpdateActionType {
    add, replace, remove
}

describe("Misc Plugins", async function () {

    let deployedOnceFactory: OnceFactory;
    let deployedOnceFactoryPluginViewer: PluginViewer;
    let deployedOnceFactoryPluginManager: PluginManager;
    let deployedOnceFactoryAccessControl: AccessControl;

    before(async () => {
        await deployments.fixture(["Once", "OnceFactory", "OnceFactoryInstance", "Metadata"]);
        const deployedOnceFactoryInstance = await deployments.get("OnceFactoryInstance");
        let deployedOnceFactoryAddress = deployedOnceFactoryInstance.address
        deployedOnceFactory = await ethers.getContractAt("OnceFactory", deployedOnceFactoryAddress) as OnceFactory;
        deployedOnceFactoryPluginViewer = await ethers.getContractAt("PluginViewer", deployedOnceFactoryAddress) as PluginViewer;
        deployedOnceFactoryPluginManager = await ethers.getContractAt("PluginManager", deployedOnceFactoryAddress) as PluginManager;
        deployedOnceFactoryAccessControl = await ethers.getContractAt("AccessControl", deployedOnceFactoryAddress) as AccessControl;
    })

    
    describe("Metadata", async function() {
        it("Installs Metadata plugin, gets and sets URI", async () => {
            const {deployer} = await getNamedAccounts();
            const signers = await ethers.getSigners();

            const metadataPlugin = await deployments.get("Metadata");
            const metadataPluginContract = await ethers.getContractAt("Metadata", metadataPlugin.address);
            const metadataInit = await deployments.get("MetadataInit");
            const metadataInitContract = await ethers.getContractAt("MetadataInit", metadataInit.address);

            const metadataFunctionSelectors = await metadataPluginContract.getFunctionSelectors();
            const metadataSingletonAddress = await metadataPluginContract.getSingletonAddress();

            const newOnceTx = await deployedOnceFactory.deployOnce(
                utils.id("layered.salt.443e20e5"),
                [{  
                    roleToCreate: utils.id("LAYERED_ONCE_UPDATE_ROLE"),
                    membersToAdd: [signers[0].address],
                    roleAdmin: ethers.constants.HashZero
                },
                {  
                    roleToCreate: ethers.constants.HashZero,
                    membersToAdd: [signers[0].address],
                    roleAdmin: ethers.constants.HashZero
                },
                {  
                    roleToCreate: utils.id("LAYERED_ONCE_METADATA_UPDATE_ROLE"),
                    membersToAdd: [signers[0].address],
                    roleAdmin: ethers.constants.HashZero
                }],
                {
                    initialUpdateInstructions: [{
                        pluginAddress: metadataPlugin.address,
                        action: UpdateActionType.add,
                        functionSelectors: metadataFunctionSelectors
                    }],
                    pluginInitializer: metadataInit.address,
                    pluginInitializerCallData: metadataInitContract.interface.encodeFunctionData('init', [
                        "ipfs://someurl"
                    ])
                },
                ethers.constants.AddressZero
            )
    
            const newOnceReceipt = await newOnceTx.wait();
            expect(newOnceReceipt.status, "New Once deployment should be successful").to.equal(1);
            
            const onceDeploymentEvent = newOnceReceipt.events?.find((event) => event.event === 'onceDeployment');
            expect(onceDeploymentEvent, "Once Factory should emit an event with the new once address").to.not.be.undefined;
    
            const newOnceAddress = onceDeploymentEvent?.args?.once
            expect(newOnceAddress, "Once address should not be undefined").to.not.be.undefined;

            const newOnceAccessControl = await ethers.getContractAt("AccessControl", newOnceAddress) as AccessControl;
            const newOnceMetadata = await ethers.getContractAt("Metadata", newOnceAddress) as Metadata;

            expect(await newOnceAccessControl.hasRole(ethers.utils.id('LAYERED_ONCE_METADATA_UPDATE_ROLE'), signers[0].address), "Deployer should have LAYERED_ONCE_METADATA_UPDATE_ROLE").to.be.true;

            expect(await newOnceMetadata.entityURI()).to.equal('ipfs://someurl');
            await expect(newOnceMetadata.connect(signers[0]).setEntityURI('ipfs://someotherurl')).to.not.be.reverted;
            await expect(newOnceMetadata.connect(signers[1]).setEntityURI('ipfs://someotherurl')).to.be.reverted;
            expect(await newOnceMetadata.entityURI()).to.equal('ipfs://someotherurl');


        })
        
    })

       
});