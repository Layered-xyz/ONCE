import { ethers, deployments, getNamedAccounts } from "hardhat";

import { ContractReceipt, utils } from "ethers";
import { assert, expect } from "chai";

import { Once, OnceFactory, PluginManager, IPluginManager, PluginViewer, IPluginViewer, OnceInit, OnceFactoryInit, AccessControl, Once__factory, SafeProxy, SafeProxyInit, SafeL2, Safe, StorageSetter, Reverter } from "../typechain";
import { AbiCoder, EventFragment } from "@ethersproject/abi";
import { keccak256 } from "ethers/lib/utils";
import singletonInterface from "../utils/safe";
import { SingletonABI } from "../utils/safe";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { chainId } from "../utils/Gnosis/test/encoding";

import {
    safeApproveHash,
    buildSignatureBytes,
    executeContractCallWithSigners,
    buildSafeTransaction,
    executeTx,
    calculateSafeTransactionHash,
    buildContractCall,
} from "../utils/Gnosis/utils/execution";

import { BigNumber } from "ethers";

enum UpdateActionType {
    add, replace, remove
}

const createOnceFactory = deployments.createFixture(
    async ({deployments, getNamedAccounts, ethers}, options) => {
        await deployments.fixture();

        const pluginViewer = await deployments.get("PluginViewer");
        const pluginManager = await deployments.get("PluginManager");
        const accessControl = await deployments.get("AccessControl");
        const onceFactory = await deployments.get("OnceFactory");
        const onceFactoryInit = await deployments.get("OnceFactoryInit");
        const onceInit = await deployments.get("OnceInit");

        const once = await ethers.getContractFactory("Once");

        const pluginViewerContract = await ethers.getContractAt("PluginViewer", pluginViewer.address) as PluginViewer;
        const onceFactoryContract = await ethers.getContractAt("OnceFactory", onceFactory.address) as OnceFactory;
        const onceInitContract = await ethers.getContractAt("OnceInit", onceInit.address) as OnceInit;
        const onceFactoryInitContract = await ethers.getContractAt("OnceFactoryInit", onceFactoryInit.address) as OnceFactoryInit;


        const deployedOnceFactory = await once.deploy(pluginManager.address, pluginViewer.address, accessControl.address);
        await deployedOnceFactory.deployed();

        const deployedOnceFactoryPluginManager = await ethers.getContractAt("PluginManager", deployedOnceFactory.address) as PluginManager;

        const onceFactoryFunctionSelectors = await onceFactoryContract.getFunctionSelectors();
        const onceFactoryCallData = onceFactoryInitContract.interface.encodeFunctionData("init", [pluginManager.address, pluginViewer.address, accessControl.address]);

        let onceFactoryTx = await deployedOnceFactoryPluginManager.update(
            [{
                pluginAddress: onceFactory.address,
                action: UpdateActionType.add,
                functionSelectors: onceFactoryFunctionSelectors
            }], 
            onceFactoryInit.address, 
            onceFactoryCallData
        );

        let onceFactoryTxReceipt = await onceFactoryTx.wait();

        return {
            deployedOnceFactoryAddress: deployedOnceFactory.address,
        };
    }
);

// Deploys a 1:1 Safe on Once for testing
const createSafe = deployments.createFixture(
    async ({deployments, getNamedAccounts, ethers}, options) => {
        await deployments.fixture();
        const {deployer} = await getNamedAccounts();
        const signers = await ethers.getSigners();

        const pluginViewer = await deployments.get("PluginViewer");
        const pluginManager = await deployments.get("PluginManager");
        const accessControl = await deployments.get("AccessControl");
        const safeProxy = await deployments.get("SafeProxy");
        const safeProxyInit = await deployments.get("SafeProxyInit");

        const once = await ethers.getContractFactory("Once");

        const pluginViewerContract = await ethers.getContractAt("PluginViewer", pluginViewer.address) as PluginViewer;
        const pluginManagerContract = await ethers.getContractAt("PluginManager", pluginManager.address) as PluginManager;
        const accessControlContract = await ethers.getContractAt("AccessControl", accessControl.address) as AccessControl;
        const safeProxyContract = await ethers.getContractAt("SafeProxy", safeProxy.address) as SafeProxy;
        const safeProxyInitContract = await ethers.getContractAt("SafeProxyInit", safeProxyInit.address) as SafeProxyInit;

        const safe = await once.deploy(pluginManager.address, pluginViewer.address, accessControl.address);
        await safe.deployed();

        const safePluginManager = await ethers.getContractAt("PluginManager", safe.address) as PluginManager;
        const safePluginViewer = await ethers.getContractAt("PluginViewer", safe.address) as PluginViewer;
        const safeAccessControl = await ethers.getContractAt("AccessControl", safe.address) as AccessControl;
        const safeL2 = await ethers.getContractAt("SafeL2", safe.address) as SafeL2

        const safeProxySelectors = await safeProxyContract.getFunctionSelectors();
        const safeProxySingletonAddress = await safeProxyContract.getSingletonAddress();

        let safeInstallationTx = await safePluginManager.update(
            [{
                pluginAddress: safeProxySingletonAddress,
                action: UpdateActionType.add,
                functionSelectors: safeProxySelectors
            }],
            safeProxyInit.address,
            safeProxyInitContract.interface.encodeFunctionData('init', [
                [deployer],
                1,
                ethers.constants.AddressZero,
                ethers.constants.HashZero,
                ethers.constants.AddressZero,
                ethers.constants.AddressZero,
                0,
                ethers.constants.AddressZero
            ])
        )

        await safeAccessControl.connect(signers[0]).grantRole(utils.id("LAYERED_ONCE_UPDATE_ROLE"), safe.address);
        await safeAccessControl.connect(signers[0]).grantRole(ethers.constants.HashZero, safe.address);
        await safeAccessControl.connect(signers[0]).renounceRole(utils.id("LAYERED_ONCE_UPDATE_ROLE"));
        await safeAccessControl.connect(signers[0]).renounceRole(ethers.constants.HashZero);


        let safeInstallationReceipt = await safeInstallationTx.wait();

        if(safeInstallationReceipt.status != 1) {
            throw("Error with safe installation")
        }

        return {
            safe: safeL2,
            safePluginManager: safePluginManager,
            safePluginViewer: safePluginViewer,
            safeAccessControl: safeAccessControl,
            pluginViewerContract: pluginViewerContract,
            pluginManagerContract: pluginManagerContract,
            accessControlContract: accessControlContract,
            safeProxyContract: safeProxyContract,
            safeProxyInitContract: safeProxyInitContract
        }
    }
      
)

describe.only("Once, OnceFactory, and standard plugins", async function () {

    let deployedOnceFactory: OnceFactory;
    let deployedOnceFactoryPluginViewer: PluginViewer;
    let deployedOnceFactoryPluginManager: PluginManager;
    let deployedOnceFactoryAccessControl: AccessControl;
    let safeProxyPlugin: SafeProxy;
    let safeProxyInit: SafeProxyInit;

    before(async () => {
        let { deployedOnceFactoryAddress } = await createOnceFactory();
        deployedOnceFactory = await ethers.getContractAt("OnceFactory", deployedOnceFactoryAddress) as OnceFactory;
        deployedOnceFactoryPluginViewer = await ethers.getContractAt("PluginViewer", deployedOnceFactoryAddress) as PluginViewer;
        deployedOnceFactoryPluginManager = await ethers.getContractAt("PluginManager", deployedOnceFactoryAddress) as PluginManager;
        deployedOnceFactoryAccessControl = await ethers.getContractAt("AccessControl", deployedOnceFactoryAddress) as AccessControl;
        const safeProxyPluginAddress = await deployments.get("SafeProxy");
        safeProxyPlugin = await ethers.getContractAt("SafeProxy", safeProxyPluginAddress.address) as SafeProxy;
        const safeProxyInitAddress = await deployments.get("SafeProxyInit");
        safeProxyInit = await ethers.getContractAt("SafeProxyInit", safeProxyInitAddress.address) as SafeProxyInit;
    })

    describe("OnceFactory", async function () {
        it("Contains installed plugins and corresponding selectors", async () => {
            const allPlugins: IPluginViewer.PluginStruct[] = await deployedOnceFactoryPluginViewer.plugins();
    
            const pluginAddresses = allPlugins.flatMap((plugin) => {
                return plugin.pluginAddress;
            })
    
            const pluginSelectors = allPlugins.flatMap((plugin) => {
                return plugin.functionSelectors;
            })
    
            const pluginViewer = await deployments.get("PluginViewer");
            const pluginManager = await deployments.get("PluginManager");
            const onceFactory = await deployments.get("OnceFactory");
            const accessControl = await deployments.get("AccessControl");
            const pluginViewerContract = await ethers.getContractAt("PluginViewer", pluginViewer.address) as PluginViewer;
            const pluginManagerContract = await ethers.getContractAt("PluginManager", pluginManager.address) as PluginManager;
            const onceFactoryContract = await ethers.getContractAt("OnceFactory", onceFactory.address) as OnceFactory;
            const accessControlContract = await ethers.getContractAt("AccessControl", accessControl.address) as AccessControl;
    
            // addresses
            expect(pluginAddresses).to.include(pluginViewer.address);
            expect(pluginAddresses).to.include(pluginManager.address);
            expect(pluginAddresses).to.include(onceFactory.address);
            expect(pluginAddresses).to.include(accessControl.address);
    
            const pluginViewerSelectors = await pluginViewerContract.getFunctionSelectors();
            const pluginManagerSelectors = await pluginManagerContract.getFunctionSelectors();
            const onceFactorySelectors = await onceFactoryContract.getFunctionSelectors();
            const accessControlSelectors = await accessControlContract.getFunctionSelectors();
    
            expect(pluginSelectors).to.include.members(pluginViewerSelectors);
            expect(pluginSelectors).to.include.members(pluginManagerSelectors);
            expect(pluginSelectors).to.include.members(onceFactorySelectors);
            expect(pluginSelectors).to.include.members(accessControlSelectors);
        })
        it("returns addresses of default plugins", async function() {
            // TODO
        })
        it("allows admin to update default plugin addresses", async function() {
            // TODO
            // NOT IMPLEMENTED IN CONTRACT
        })
    
        describe("Standard Once deployment via OnceFactory", async function() {
            it("Fails to deploy when no Access Control is provided", async () => {
                // TODO
            })
            
            it("Deterministically deploys a Once contract", async () => {
                const {deployer} = await getNamedAccounts();
        
                const precomputedAddress = await deployedOnceFactory.getOnceAddress(
                    deployedOnceFactory.address,
                    utils.id("layered.salt.443e20e5"),
                    [{  
                        roleToCreate: utils.id("LAYERED_ONCE_UPDATE_ROLE"),
                        membersToAdd: [deployer],
                        roleAdmin: ethers.constants.HashZero
                    },
                    {  
                        roleToCreate: ethers.constants.HashZero,
                        membersToAdd: [deployer],
                        roleAdmin: ethers.constants.HashZero
                    }],
                    {
                        initialUpdateInstructions: [],
                        pluginInitializer: ethers.constants.AddressZero,
                        pluginInitializerCallData: ethers.constants.AddressZero
                    }
                )
        
                const newOnceTx = await deployedOnceFactory.deployOnce(
                    utils.id("layered.salt.443e20e5"),
                    [{  
                        roleToCreate: utils.id("LAYERED_ONCE_UPDATE_ROLE"),
                        membersToAdd: [deployer],
                        roleAdmin: ethers.constants.HashZero
                    },
                    {  
                        roleToCreate: ethers.constants.HashZero,
                        membersToAdd: [deployer],
                        roleAdmin: ethers.constants.HashZero
                    }],
                    {
                        initialUpdateInstructions: [],
                        pluginInitializer: ethers.constants.AddressZero,
                        pluginInitializerCallData: ethers.constants.AddressZero
                    },
                    ethers.constants.AddressZero
                )
        
                const newOnceReceipt = await newOnceTx.wait();
                expect(newOnceReceipt.status, "New Once deployment should be successful").to.equal(1);
                
                const onceDeploymentEvent = newOnceReceipt.events?.find((event) => event.event === 'onceDeployment');
                expect(onceDeploymentEvent, "Once Factory should emit an event with the new once address").to.not.be.undefined;
        
                const newOnceAddress = onceDeploymentEvent?.args?.once
                expect(newOnceAddress, "Once address should not be undefined").to.not.be.undefined;
                expect(newOnceAddress, "Once address should match the precomputed address").to.equal(precomputedAddress);
        
                const newOnceAccessControl = await ethers.getContractAt("AccessControl", newOnceAddress) as AccessControl;
        
                expect(await newOnceAccessControl.hasRole(ethers.utils.id('LAYERED_ONCE_UPDATE_ROLE'), deployer), "Deployer should have LAYERED_ONCE_UPDATE_ROLE").to.be.true;
                expect(await newOnceAccessControl.hasRole(ethers.utils.id('LAYERED_ONCE_UPDATE_ROLE'), deployedOnceFactory.address), "Once Factory should no longer have LAYERED_ONCE_UPDATE_ROLE").to.be.false;
                expect(await newOnceAccessControl.hasRole(ethers.constants.HashZero, deployer), "Deployer should be admin").to.be.true;
                expect(await newOnceAccessControl.hasRole(ethers.constants.HashZero, deployedOnceFactory.address), "Once Factory should no longer be admin").to.be.false;
            }) 

            it("Successfully installs initial plugins", async () => {
                // TODO
            })
        
            it("Successfully executes a callback after deploying", async () => {
                // TODO
            })
        })

        describe("Simple Once deployment via OnceFactory", async function() {
            it("Fails to deploy when no Access Control is provided", async () => {
                // TODO
            })

            it("Deterministically deploys a Once contract with a simple salt", async () => {
                // TODO
            })

            it("Successfully installs initial plugins", async () => {
                // TODO
            })
        
            it("Successfully executes a callback after deploying", async () => {
                // TODO
            })
        })
    })
    describe.only("SafeProxy", async function() {
        let signers: SignerWithAddress[];
        let safeProxySelectors: string[];
        let safeProxySingletonAddress: string;
        let safeOnceTx: any;
        let safeOnceReceipt: any;
        let safeOnceAddress: string;

        before(async () => {
            const {deployer} = await getNamedAccounts();
            signers = await ethers.getSigners();

            safeProxySelectors = await safeProxyPlugin.getFunctionSelectors();
            safeProxySingletonAddress = await safeProxyPlugin.getSingletonAddress();
    
            safeOnceTx = await deployedOnceFactory.deployOnce(
                utils.id("layered.salt.443e20e5.safe"),
                [{  
                    roleToCreate: utils.id("LAYERED_ONCE_UPDATE_ROLE"),
                    membersToAdd: [deployer],
                    roleAdmin: ethers.constants.HashZero
                },
                {  
                    roleToCreate: ethers.constants.HashZero,
                    membersToAdd: [deployer],
                    roleAdmin: ethers.constants.HashZero
                }],
                {
                    initialUpdateInstructions: [{
                        pluginAddress: safeProxySingletonAddress,
                        action: UpdateActionType.add,
                        functionSelectors: safeProxySelectors
                    }],
                    pluginInitializer: safeProxyInit.address,
                    pluginInitializerCallData: safeProxyInit.interface.encodeFunctionData('init', [
                        [deployer],
                        1,
                        ethers.constants.AddressZero,
                        ethers.constants.HashZero,
                        ethers.constants.AddressZero,
                        ethers.constants.AddressZero,
                        0,
                        ethers.constants.AddressZero
                    ])
                },
                ethers.constants.AddressZero
            )
            safeOnceReceipt = await safeOnceTx.wait();

            expect(safeOnceReceipt.status, "New Once deployment with safe should be successful").to.equal(1);
            
            const onceDeploymentEvent = safeOnceReceipt.events?.find((event: any) => event.event === 'onceDeployment');
            expect(onceDeploymentEvent, "Once Factory should emit an event with the new once address").to.not.be.undefined;
    
            safeOnceAddress = onceDeploymentEvent?.args?.once
            expect(safeOnceAddress, "Once address should not be undefined").to.not.be.undefined;


        })

        it("Deterministically deployed a Once contract with Safe initialized", async () => {
            const newOnceAccessControl = await ethers.getContractAt("AccessControl", safeOnceAddress) as AccessControl;
            const newOncePluginViewer = await ethers.getContractAt("PluginViewer", safeOnceAddress) as PluginViewer;
            const newOncePluginManager = await ethers.getContractAt("PluginManager", safeOnceAddress) as PluginManager;
            const newOnceSafe = await ethers.getContractAt("SafeL2", safeOnceAddress) as SafeL2;


            const newOncePlugins: IPluginViewer.PluginStruct[] = await newOncePluginViewer.plugins();
    
            const newOncePluginAddresses = newOncePlugins.flatMap((plugin) => {
                return plugin.pluginAddress;
            })
    
            const newOncePluginSelectors = newOncePlugins.flatMap((plugin) => {
                return plugin.functionSelectors;
            })

            expect(newOncePluginAddresses, "New Once should show safe proxy plugin address via plugin viewer").to.include(safeProxySingletonAddress);
            expect(newOncePluginSelectors, "New Once should show safe proxy plugin selectors via plugin viewer").to.include.members(safeProxySelectors);

            // TODO: Check events

            expect((await newOnceSafe.functions.isOwner(signers[0].address))[0]).to.be.true;
            expect((await newOnceSafe.functions.getOwners())[0]).to.have.length(1);
            expect((await newOnceSafe.functions.getThreshold())[0]).to.equal(1);

            await newOnceAccessControl.functions.grantRole(utils.id("LAYERED_ONCE_UPDATE_ROLE"), safeOnceAddress);

            expect(await newOnceAccessControl.hasRole(ethers.utils.id('LAYERED_ONCE_UPDATE_ROLE'), safeOnceAddress), "Safe should have LAYERED_ONCE_UPDATE_ROLE").to.be.true;

        })



        // **** The following tests have been pulled directly from the safe-smart-account repository and have been adapted to test the same functionality on a Safe deployed on ONCE
        describe("Safe-Smart-Account Adapted Tests", () => {
        
            // describe("execTransaction", () => {
                it("should revert if too little gas is provided", async () => {
                    const safe = await ethers.getContractAt("SafeL2", safeOnceAddress) as Safe;
                    const user1 = signers[0];
                    const safeAddress = safeOnceAddress;
                    const tx = buildSafeTransaction({ to: safeAddress, safeTxGas: 1000000, nonce: await safe.nonce() });
                    const signatureBytes = buildSignatureBytes([await safeApproveHash(user1, safe, tx, true)]);
                    await expect(
                        safe.execTransaction(
                            tx.to,
                            tx.value,
                            tx.data,
                            tx.operation,
                            tx.safeTxGas,
                            tx.baseGas,
                            tx.gasPrice,
                            tx.gasToken,
                            tx.refundReceiver,
                            signatureBytes,
                            { gasLimit: 1000000 },
                        ),
                    ).to.be.revertedWith("GS010");
                });
        
                it("should emit event for successful call execution", async () => {
                    const safe = await ethers.getContractAt("SafeL2", safeOnceAddress) as Safe;
                    const storageSetterFactory = await ethers.getContractFactory("StorageSetter");
                    const storageSetter = await storageSetterFactory.deploy() as StorageSetter;

                    const user1 = signers[0];
                    const safeAddress = safe.address;
                    const storageSetterAddress = storageSetter.address;
                    const txHash = calculateSafeTransactionHash(
                        safeAddress,
                        await buildContractCall(storageSetter, "setStorage", ["0xbaddad"], await safe.nonce()),
                        await chainId(),
                    );
                    await expect(executeContractCallWithSigners(safe, storageSetter, "setStorage", ["0xbaddad"], [user1]))
                        .to.emit(safe, "ExecutionSuccess")
                        .withArgs(txHash, 0);
        
                    await expect(
                        await ethers.provider.getStorageAt(safeAddress, "0x4242424242424242424242424242424242424242424242424242424242424242"),
                    ).to.be.eq("0x" + "".padEnd(64, "0"));
        
                    await expect(
                        await ethers.provider.getStorageAt(
                            storageSetterAddress,
                            "0x4242424242424242424242424242424242424242424242424242424242424242",
                        ),
                    ).to.be.eq("0x" + "baddad".padEnd(64, "0"));
                });
        
                it("should emit event for failed call execution if safeTxGas > 0", async () => {
                    const safe = await ethers.getContractAt("SafeL2", safeOnceAddress) as Safe;
                    const reverterFactory = await ethers.getContractFactory("Reverter");
                    const reverter = await reverterFactory.deploy() as Reverter;

                    const user1 = signers[0];
                    await expect(executeContractCallWithSigners(safe, reverter, "revert", [], [user1], false, { safeTxGas: 1 })).to.emit(
                        safe,
                        "ExecutionFailure",
                    );
                });
        
                it("should emit event for failed call execution if gasPrice > 0", async () => {
                    const safe = await ethers.getContractAt("SafeL2", safeOnceAddress) as Safe;
                    const reverterFactory = await ethers.getContractFactory("Reverter");
                    const reverter = await reverterFactory.deploy() as Reverter;

                    const user1 = signers[0];
                    const safeAddress = await safe.address;
                    // Fund refund
                    await user1.sendTransaction({ to: safeAddress, value: 10000000 });
                    await expect(executeContractCallWithSigners(safe, reverter, "revert", [], [user1], false, { gasPrice: 1 })).to.emit(
                        safe,
                        "ExecutionFailure",
                    );
                });
        
                it("should revert for failed call execution if gasPrice == 0 and safeTxGas == 0", async () => {
                    const safe = await ethers.getContractAt("SafeL2", safeOnceAddress) as Safe;
                    const reverterFactory = await ethers.getContractFactory("Reverter");
                    const reverter = await reverterFactory.deploy() as Reverter;

                    const user1 = signers[0];
                    await expect(executeContractCallWithSigners(safe, reverter, "revert", [], [user1])).to.revertedWith("GS013");
                });
        
                it("should emit event for successful delegatecall execution", async () => {
                    const safe = await ethers.getContractAt("SafeL2", safeOnceAddress) as Safe;
                    const storageSetterFactory = await ethers.getContractFactory("StorageSetter");
                    const storageSetter = await storageSetterFactory.deploy() as StorageSetter;

                    const user1 = signers[0];
                    const safeAddress = safe.address;
                    const storageSetterAddress = storageSetter.address;
                    await expect(executeContractCallWithSigners(safe, storageSetter, "setStorage", ["0xbaddad"], [user1], true)).to.emit(
                        safe,
                        "ExecutionSuccess",
                    );
        
                    await expect(
                        await ethers.provider.getStorageAt(safeAddress, "0x4242424242424242424242424242424242424242424242424242424242424242"),
                    ).to.be.eq("0x" + "baddad".padEnd(64, "0"));
        
                    await expect(
                        await ethers.provider.getStorageAt(
                            storageSetterAddress,
                            "0x4242424242424242424242424242424242424242424242424242424242424242",
                        ),
                    ).to.be.eq("0x" + "".padEnd(64, "0"));
                });
        
                it("should emit event for failed delegatecall execution  if safeTxGas > 0", async () => {
                    const safe = await ethers.getContractAt("SafeL2", safeOnceAddress) as Safe;
                    const reverterFactory = await ethers.getContractFactory("Reverter");
                    const reverter = await reverterFactory.deploy() as Reverter;

                    const user1 = signers[0];
                    const safeAddress = await safe.address;
                    const txHash = calculateSafeTransactionHash(
                        safeAddress,
                        await buildContractCall(reverter, "revert", [], await safe.nonce(), true, { safeTxGas: 1 }),
                        await chainId(),
                    );
                    await expect(executeContractCallWithSigners(safe, reverter, "revert", [], [user1], true, { safeTxGas: 1 }))
                        .to.emit(safe, "ExecutionFailure")
                        .withArgs(txHash, 0);
                });
        
                it("should emit event for failed delegatecall execution if gasPrice > 0", async () => {
                    const safe = await ethers.getContractAt("SafeL2", safeOnceAddress) as Safe;
                    const reverterFactory = await ethers.getContractFactory("Reverter");
                    const reverter = await reverterFactory.deploy() as Reverter;

                    const user1 = signers[0];
                    const safeAddress = await safe.address;
                    await user1.sendTransaction({ to: safeAddress, value: 10000000 });
                    await expect(executeContractCallWithSigners(safe, reverter, "revert", [], [user1], true, { gasPrice: 1 })).to.emit(
                        safe,
                        "ExecutionFailure",
                    );
                });
        
                it("should emit event for failed delegatecall execution if gasPrice == 0 and safeTxGas == 0", async () => {
                    const safe = await ethers.getContractAt("SafeL2", safeOnceAddress) as Safe;
                    const reverterFactory = await ethers.getContractFactory("Reverter");
                    const reverter = await reverterFactory.deploy() as Reverter;

                    const user1 = signers[0];
                    await expect(executeContractCallWithSigners(safe, reverter, "revert", [], [user1], true)).to.revertedWith("GS013");
                });
        
                it("should revert on unknown operation", async () => {
                    const safe = await ethers.getContractAt("SafeL2", safeOnceAddress) as Safe;

                    const user1 = signers[0];
                    const safeAddress = await safe.address;
                    const tx = buildSafeTransaction({ to: safeAddress, nonce: await safe.nonce(), operation: 2 });
                    await expect(executeTx(safe, tx, [await safeApproveHash(user1, safe, tx, true)])).to.be.reverted;
                });
        
                it("should emit payment in success event", async () => {
                    const safe = await ethers.getContractAt("SafeL2", safeOnceAddress) as Safe;

                    const user1 = signers[0];
                    const user2 = signers[1];
                    const safeAddress = await safe.address;
                    const tx = buildSafeTransaction({
                        to: user1.address,
                        nonce: await safe.nonce(),
                        operation: 0,
                        gasPrice: 1,
                        safeTxGas: 100000,
                        refundReceiver: user2.address,
                    });
                    const originalSafeBalance = await ethers.provider.getBalance(safeAddress);

                    await user1.sendTransaction({ to: safeAddress, value: ethers.utils.parseEther("1") });
                    const userBalance = await ethers.provider.getBalance(user2.address);
                    expect(await ethers.provider.getBalance(safeAddress)).to.be.eq(BigNumber.from(originalSafeBalance).add(ethers.utils.parseEther("1")));
                    
        
                    let executedTx: any;
                    await expect(
                        executeTx(safe, tx, [await safeApproveHash(user1, safe, tx, true)]).then((tx) => {
                            executedTx = tx;
                            return tx;
                        }),
                    ).to.emit(safe, "ExecutionSuccess");
        
                    const receipt = await ethers.provider.getTransactionReceipt(executedTx!.hash);
                    const receiptLogs = receipt?.logs ?? [];
        
                    const logIndex = receiptLogs.length - 1;
        
                    const successEvent = safe.interface.decodeEventLog(
                        "ExecutionSuccess",
                        receiptLogs[logIndex].data,
                        receiptLogs[logIndex].topics,
                    );
                    expect(successEvent.txHash).to.be.eq(calculateSafeTransactionHash(safeAddress, tx, await chainId()));
                    // Gas costs are around 3000, so even if we specified a safeTxGas from 100000 we should not use more
                    expect(successEvent.payment).to.be.lte(BigInt(5000));
                    expect(await ethers.provider.getBalance(user2.address)).to.eq(BigNumber.from(successEvent.payment).add(userBalance));
                });
        
                it("should emit payment in failure event", async () => {
                    const safe = await ethers.getContractAt("SafeL2", safeOnceAddress) as Safe;
                    const storageSetterFactory = await ethers.getContractFactory("StorageSetter");
                    const storageSetter = await storageSetterFactory.deploy() as StorageSetter;

                    const user1 = signers[0];
                    const user2 = signers[1];
                    const safeAddress = safe.address;
                    const storageSetterAddress = storageSetter.address;
                    const data = storageSetter.interface.encodeFunctionData("setStorage", ["0xbaddad"]);
                    const tx = buildSafeTransaction({
                        to: storageSetterAddress,
                        data,
                        nonce: await safe.nonce(),
                        operation: 0,
                        gasPrice: 1,
                        safeTxGas: 3000,
                        refundReceiver: user2.address,
                    });

                    const originalSafeBalance = await ethers.provider.getBalance(safeAddress);
        
                    await user1.sendTransaction({ to: safeAddress, value: ethers.utils.parseEther("1") });
                    const userBalance = await ethers.provider.getBalance(user2.address);
                    expect(await ethers.provider.getBalance(safeAddress)).to.be.eq(BigNumber.from(originalSafeBalance).add(ethers.utils.parseEther("1")));
        
                    let executedTx: any;
                    await expect(
                        executeTx(safe, tx, [await safeApproveHash(user1, safe, tx, true)]).then((tx) => {
                            executedTx = tx;
                            return tx;
                        }),
                    ).to.emit(safe, "ExecutionFailure");
                    const receipt = await ethers.provider.getTransactionReceipt(executedTx!.hash);
                    const receiptLogs = receipt?.logs ?? [];
                    const logIndex = receiptLogs.length - 1;
                    const successEvent = safe.interface.decodeEventLog(
                        "ExecutionFailure",
                        receiptLogs[logIndex].data,
                        receiptLogs[logIndex].topics,
                    );
                    expect(successEvent.txHash).to.be.eq(calculateSafeTransactionHash(safeAddress, tx, await chainId()));
                    // FIXME: When running out of gas the gas used is slightly higher than the safeTxGas and the user has to overpay
                    expect(successEvent.payment).to.be.lte(BigInt(10000));
                    await expect(await ethers.provider.getBalance(user2.address)).to.eq(BigNumber.from(successEvent.payment).add(userBalance));
                });
        
                it("should be possible to manually increase gas", async () => {
                    const safe = await ethers.getContractAt("SafeL2", safeOnceAddress) as Safe;
                    const user1 = signers[0];
                    const safeAddress = safe.address;
                    const gasUserFactory = await ethers.getContractFactory("GasUser")
                    const gasUser = await gasUserFactory.deploy();
                    const to = gasUser.address;
                    const data = gasUser.interface.encodeFunctionData("useGas", [80]);
                    const safeTxGas = 10000;
                    const tx = buildSafeTransaction({ to, data, safeTxGas, nonce: await safe.nonce() });
                    await expect(
                        executeTx(safe, tx, [await safeApproveHash(user1, safe, tx, true)], { gasLimit: 170000 }),
                        "Safe transaction should fail with low gasLimit",
                    ).to.emit(safe, "ExecutionFailure");
        
                    await expect(
                        executeTx(safe, tx, [await safeApproveHash(user1, safe, tx, true)], { gasLimit: 6000000 }),
                        "Safe transaction should succeed with high gasLimit",
                    ).to.emit(safe, "ExecutionSuccess");
        
                    // This should only work if the gasPrice is 0
                    tx.gasPrice = 1;
                    await user1.sendTransaction({ to: safeAddress, value: ethers.utils.parseEther("1") });
                    await expect(
                        executeTx(safe, tx, [await safeApproveHash(user1, safe, tx, true)], { gasLimit: 6000000 }),
                        "Safe transaction should fail with gasPrice 1 and high gasLimit",
                    ).to.emit(safe, "ExecutionFailure");
                });
        
                // it("should forward all the gas to the native token refund receiver", async () => {
                //     const { safe, nativeTokenReceiver, signers } = await setupTests();
                //     const [user1] = signers;
                //     const safeAddress = await safe.getAddress();
                //     const nativeTokenReceiverAddress = await nativeTokenReceiver.getAddress();
        
                //     const tx = buildSafeTransaction({
                //         to: user1.address,
                //         nonce: await safe.nonce(),
                //         operation: 0,
                //         gasPrice: 1,
                //         safeTxGas: 0,
                //         refundReceiver: nativeTokenReceiverAddress,
                //     });
        
                //     await user1.sendTransaction({ to: safeAddress, value: ethers.parseEther("1") });
                //     await expect(await ethers.provider.getBalance(safeAddress)).to.eq(ethers.parseEther("1"));
        
                //     const executedTx = await executeTx(safe, tx, [await safeApproveHash(user1, safe, tx, true)], { gasLimit: 500000 });
                //     const receipt = await ethers.provider.getTransactionReceipt(executedTx.hash);
                //     const receiptLogs = receipt?.logs ?? [];
                //     const parsedLogs = [];
                //     for (const log of receiptLogs) {
                //         try {
                //             parsedLogs.push(nativeTokenReceiver.interface.decodeEventLog("BreadReceived", log.data, log.topics));
                //         } catch (e) {
                //             continue;
                //         }
                //     }
        
                //     expect(parsedLogs[0].forwardedGas).to.be.gte(400000n);
                // });
            // });
        });

        describe.only("Safe self-management access controls", async function() {
            it("should appropriately call update on itself via Safe Transaction", async () => {

                const {safe, safePluginManager, safePluginViewer, pluginManagerContract, pluginViewerContract} = await createSafe();

                expect(await safePluginViewer.pluginFunctionSelectors(pluginManagerContract.address), "Safe should have selector prior to update").to.contain('0x80438e0d');
                const user1 = signers[0];
                const to = safe.address;
                const data = pluginManagerContract.interface.encodeFunctionData("update", [
                    [{
                        pluginAddress: ethers.constants.AddressZero,
                        action: UpdateActionType.remove,
                        functionSelectors: ['0x80438e0d']
                    }], 
                    ethers.constants.AddressZero, 
                    ethers.constants.HashZero
                ])

                const safeTxGas = 100000;
                const tx = buildSafeTransaction({ to, data, safeTxGas, nonce: await safe.nonce() });

    
                await expect(
                    executeTx(safe, tx, [await safeApproveHash(user1, safe, tx, true)], { gasLimit: 6000000 }),
                    "Safe transaction should succeed",
                ).to.emit(safe, "ExecutionSuccess");

                expect(await safePluginViewer.pluginFunctionSelectors(pluginManagerContract.address), "Safe should not have selector after update").to.not.contain('0x80438e0d');

            });
        })
    })
    

    

    

});