import { ethers, deployments, getNamedAccounts } from "hardhat";
import { ContractReceipt, providers, utils } from "ethers";
import { assert, expect } from "chai";
import { Once, OnceFactory, PluginManager, IPluginManager, PluginViewer, IPluginViewer, OnceInit, OnceFactoryInit, AccessControl, Once__factory, ERC721, SafeProxy, SafeProxyInit, SafeL2, Safe, StorageSetter, Reverter, ERC721Init, ERC721AccessControlMint, ERC721NonTransferable, ERC721Mint, ERC721NonTransferableInit, ERC721AccessControlMintInit, ERC721AutoIncrementMint, ERC721AutoIncrementMintInit, ERC721BalanceLimit, ERC721BalanceLimitInit } from "../typechain";
import { AbiCoder, EventFragment } from "@ethersproject/abi";
import { keccak256 } from "ethers/lib/utils";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber } from "ethers";

enum UpdateActionType {
    add, replace, remove
}

// Deploys a 1:1 Safe on Once for testing
const createERC721 = deployments.createFixture(
    async ({deployments, getNamedAccounts, ethers}, options) => {
        await deployments.fixture(["Once", "OnceFactory", "OnceFactoryInstance", "ERC721"]);
        const {deployer} = await getNamedAccounts();
        const signers = await ethers.getSigners();

        const pluginViewer = await deployments.get("PluginViewer");
        const pluginManager = await deployments.get("PluginManager");
        const accessControl = await deployments.get("AccessControl");
        const erc721Singleton = await deployments.get("ERC721");
        const erc721Init = await deployments.get("ERC721Init");

        const once = await ethers.getContractFactory("Once");

        const pluginViewerContract = await ethers.getContractAt("PluginViewer", pluginViewer.address) as PluginViewer;
        const pluginManagerContract = await ethers.getContractAt("PluginManager", pluginManager.address) as PluginManager;
        const accessControlContract = await ethers.getContractAt("AccessControl", accessControl.address) as AccessControl;
        const erc721SingletonContract = await ethers.getContractAt("ERC721", erc721Singleton.address) as ERC721;
        const erc721InitContract = await ethers.getContractAt("ERC721Init", erc721Init.address) as ERC721Init;

        const erc721Once = await once.deploy(ethers.constants.AddressZero, pluginManager.address, pluginViewer.address, accessControl.address);
        await erc721Once.deployed();

        const erc721PluginManager = await ethers.getContractAt("PluginManager", erc721Once.address) as PluginManager;
        const erc721PluginViewer = await ethers.getContractAt("PluginViewer", erc721Once.address) as PluginViewer;
        const erc721AccessControl = await ethers.getContractAt("AccessControl", erc721Once.address) as AccessControl;
        const erc721 = await ethers.getContractAt("ERC721", erc721Once.address) as ERC721;

        const erc721Selectors = await erc721SingletonContract.getFunctionSelectors();
        const erc721SingletonAddress = await erc721SingletonContract.getSingletonAddress();

        let erc721InstallationTx = await erc721PluginManager.update(
            [{
                pluginAddress: erc721SingletonAddress,
                action: UpdateActionType.add,
                functionSelectors: erc721Selectors
            }],
            erc721Init.address,
            erc721InitContract.interface.encodeFunctionData('init', [
                "TestNFT", 
                "TNFT",
                ""
            ])
        )

        let erc721InstallationReceipt = await erc721InstallationTx.wait();

        if(erc721InstallationReceipt.status != 1) {
            throw("Error with erc721 installation")
        }

        return {
            erc721: erc721,
            erc721PluginManager: erc721PluginManager,
            erc721PluginViewer: erc721PluginViewer,
            erc721AccessControl: erc721AccessControl,
            pluginViewerContract: pluginViewerContract,
            pluginManagerContract: pluginManagerContract,
            accessControlContract: accessControlContract
        }
    }
)

describe("Core ERC721 Once Plugin", async function () {

    it('Successfully stores and returns name and symbol', async () => {
        const {erc721, erc721PluginManager, erc721PluginViewer, pluginManagerContract, pluginViewerContract} = await createERC721();

        let nameResult: string = await erc721.name();
        let symbolResult: string = await erc721.symbol();

        assert.equal(nameResult, "TestNFT", "Name does not match");
        assert.equal(symbolResult, "TNFT", "Symbol does not match");
    })

    // Add more tests for other ERC721 functionalities
});

describe("ERC721 Minting Plugins", async function () {
  it('Can install and use access control mint functionality with default functionality when no init contract is provided', async () => {
    const {erc721, erc721PluginManager, erc721AccessControl, erc721PluginViewer, pluginManagerContract, pluginViewerContract} = await createERC721();
    const signers = await ethers.getSigners();

    const erc721AccessControlMint = await deployments.get("ERC721AccessControlMint");
    const erc721AccessControlMintContract = await ethers.getContractAt("ERC721AccessControlMint", erc721AccessControlMint.address) as ERC721AccessControlMint

    const erc721AccessControlMintFunctionSelectors = await erc721AccessControlMintContract.getFunctionSelectors();
    const erc721AccessControlMintSingletonAddress = await erc721AccessControlMintContract.getSingletonAddress();

    let erc721AccessControlMintInstallationTx = await erc721PluginManager.update(
        [{
            pluginAddress: erc721AccessControlMintSingletonAddress,
            action: UpdateActionType.add,
            functionSelectors: erc721AccessControlMintFunctionSelectors
        }],
        ethers.constants.AddressZero,
        ethers.constants.HashZero
    )

    let erc721AccessControlMintInstallationReceipt = await erc721AccessControlMintInstallationTx.wait();

    let erc721ACM = await ethers.getContractAt("ERC721AccessControlMint", erc721.address) as ERC721AccessControlMint;

    assert.equal(erc721AccessControlMintInstallationReceipt.status, 1, "ERC721AccessControlMint installation unsuccessful");

    await erc721AccessControl.connect(signers[0]).grantRole(ethers.utils.id('LAYERED_ERC721_MINTER_ROLE'), signers[1].address)
    expect(await erc721AccessControl.hasRole(ethers.utils.id('LAYERED_ERC721_MINTER_ROLE'), signers[1].address)).to.be.true
    expect(await erc721AccessControl.hasRole(ethers.constants.HashZero, signers[1].address)).to.be.false
    expect(await erc721AccessControl.hasRole(ethers.constants.HashZero, signers[0].address)).to.be.true // DEFAULT_ADMIN_ROLE

    await expect(erc721ACM.connect(signers[1]).safeMint(signers[2].address, 1)).to.not.be.reverted;
    expect(await erc721.ownerOf(1)).to.equal(signers[2].address)
    
    await expect(erc721ACM.connect(signers[2]).safeMint(signers[2].address, 2)).to.be.reverted;
    await expect(erc721ACM.connect(signers[0]).safeMint(signers[2].address, 2)).to.be.reverted;
    await expect(erc721ACM.connect(signers[0]).safeMint(signers[1].address, 2)).to.be.reverted;

    expect(await erc721.totalSupply()).to.equal(1, "Total supply miscalculated");
    expect(await erc721.tokenOfOwnerByIndex(signers[2].address, 0)).to.equal(1, "Could not retrieve token index");
  })

  it('Can install and use access control mint functionality with a set price', async () => {
    const {erc721, erc721PluginManager, erc721AccessControl, erc721PluginViewer, pluginManagerContract, pluginViewerContract} = await createERC721();
    const signers = await ethers.getSigners();

    const erc721AccessControlMint = await deployments.get("ERC721AccessControlMint");
    const erc721AccessControlMintContract = await ethers.getContractAt("ERC721AccessControlMint", erc721AccessControlMint.address) as ERC721AccessControlMint

    const erc721AccessControlMintInit = await deployments.get("ERC721AccessControlMintInit");
    const erc721AccessControlMintInitContract = await ethers.getContractAt("ERC721AccessControlMintInit", erc721AccessControlMintInit.address) as ERC721AccessControlMintInit

    const erc721AccessControlMintFunctionSelectors = await erc721AccessControlMintContract.getFunctionSelectors();
    const erc721AccessControlMintSingletonAddress = await erc721AccessControlMintContract.getSingletonAddress();

    let erc721AccessControlMintInstallationTx = await erc721PluginManager.update(
        [{
            pluginAddress: erc721AccessControlMintSingletonAddress,
            action: UpdateActionType.add,
            functionSelectors: erc721AccessControlMintFunctionSelectors
        }],
        erc721AccessControlMintInit.address,
        erc721AccessControlMintInitContract.interface.encodeFunctionData('init', [ethers.utils.parseEther(".01"), ""])
    )

    let erc721AccessControlMintInstallationReceipt = await erc721AccessControlMintInstallationTx.wait();

    let erc721ACM = await ethers.getContractAt("ERC721AccessControlMint", erc721.address) as ERC721AccessControlMint;

    assert.equal(erc721AccessControlMintInstallationReceipt.status, 1, "ERC721AccessControlMint installation unsuccessful");

    await erc721AccessControl.connect(signers[0]).grantRole(ethers.utils.id('LAYERED_ERC721_MINTER_ROLE'), signers[1].address)
    expect(await erc721AccessControl.hasRole(ethers.utils.id('LAYERED_ERC721_MINTER_ROLE'), signers[1].address)).to.be.true
    expect(await erc721AccessControl.hasRole(ethers.constants.HashZero, signers[1].address)).to.be.false
    expect(await erc721AccessControl.hasRole(ethers.constants.HashZero, signers[0].address)).to.be.true // DEFAULT_ADMIN_ROLE

    await expect(erc721ACM.connect(signers[1]).safeMint(signers[2].address, 1, {value: ethers.utils.parseEther('.01')})).to.not.be.reverted;
    await expect(erc721ACM.connect(signers[1]).safeMint(signers[2].address, 2, {value: ethers.utils.parseEther('.001')})).to.be.reverted;
    await expect(erc721ACM.connect(signers[1]).safeMint(signers[2].address, 3, {value: ethers.utils.parseEther('0')})).to.be.reverted;
    await expect(erc721ACM.connect(signers[1]).safeMint(signers[2].address, 4, {value: ethers.utils.parseEther('1')})).to.not.be.reverted;

    expect(await erc721.tokenURI(1)).to.equal("");
    expect(await erc721.ownerOf(1)).to.equal(signers[2].address)

    expect(await erc721.totalSupply()).to.equal(2, "Total supply miscalculated");
    expect(await erc721.tokenOfOwnerByIndex(signers[2].address, 1)).to.equal(4, "Could not retrieve token index");
    expect((await erc721.tokenByIndex(0))).to.equal(1);
    expect((await erc721.tokenByIndex(1))).to.equal(4);
    
    await expect(erc721ACM.connect(signers[2]).safeMint(signers[2].address, 2)).to.be.reverted;
    await expect(erc721ACM.connect(signers[0]).safeMint(signers[2].address, 2)).to.be.reverted;
    await expect(erc721ACM.connect(signers[0]).safeMint(signers[1].address, 2)).to.be.reverted;
  })

  it('Can install and use access control mint functionality with a set uniformURI', async () => {
    const {erc721, erc721PluginManager, erc721AccessControl, erc721PluginViewer, pluginManagerContract, pluginViewerContract} = await createERC721();
    const signers = await ethers.getSigners();

    const erc721AccessControlMint = await deployments.get("ERC721AccessControlMint");
    const erc721AccessControlMintContract = await ethers.getContractAt("ERC721AccessControlMint", erc721AccessControlMint.address) as ERC721AccessControlMint

    const erc721AccessControlMintInit = await deployments.get("ERC721AccessControlMintInit");
    const erc721AccessControlMintInitContract = await ethers.getContractAt("ERC721AccessControlMintInit", erc721AccessControlMintInit.address) as ERC721AccessControlMintInit

    const erc721AccessControlMintFunctionSelectors = await erc721AccessControlMintContract.getFunctionSelectors();
    const erc721AccessControlMintSingletonAddress = await erc721AccessControlMintContract.getSingletonAddress();

    let erc721AccessControlMintInstallationTx = await erc721PluginManager.update(
        [{
            pluginAddress: erc721AccessControlMintSingletonAddress,
            action: UpdateActionType.add,
            functionSelectors: erc721AccessControlMintFunctionSelectors
        }],
        erc721AccessControlMintInit.address,
        erc721AccessControlMintInitContract.interface.encodeFunctionData('init', [0, "someURI"])
    )

    let erc721AccessControlMintInstallationReceipt = await erc721AccessControlMintInstallationTx.wait();

    let erc721ACM = await ethers.getContractAt("ERC721AccessControlMint", erc721.address) as ERC721AccessControlMint;

    assert.equal(erc721AccessControlMintInstallationReceipt.status, 1, "ERC721AccessControlMint installation unsuccessful");

    await erc721AccessControl.connect(signers[0]).grantRole(ethers.utils.id('LAYERED_ERC721_MINTER_ROLE'), signers[1].address)
    expect(await erc721AccessControl.hasRole(ethers.utils.id('LAYERED_ERC721_MINTER_ROLE'), signers[1].address)).to.be.true
    expect(await erc721AccessControl.hasRole(ethers.constants.HashZero, signers[1].address)).to.be.false
    expect(await erc721AccessControl.hasRole(ethers.constants.HashZero, signers[0].address)).to.be.true // DEFAULT_ADMIN_ROLE

    await expect(erc721ACM.connect(signers[1]).safeMint(signers[2].address, 1)).to.not.be.reverted;
    await expect(erc721ACM.connect(signers[1]).safeMint(signers[2].address, 2)).to.not.be.reverted;
    expect(await erc721.ownerOf(1)).to.equal(signers[2].address)
    expect(await erc721.ownerOf(2)).to.equal(signers[2].address)
    expect(await erc721.tokenURI(1)).to.equal("someURI");
    expect(await erc721.tokenURI(2)).to.equal("someURI");

    expect(await erc721.totalSupply()).to.equal(2, "Total supply miscalculated");
    expect(await erc721.tokenOfOwnerByIndex(signers[2].address, 1)).to.equal(2, "Could not retrieve token index");
    expect((await erc721.tokenByIndex(0))).to.equal(1);
    expect((await erc721.tokenByIndex(1))).to.equal(2);
  })


  it('Can install and use auto increment mint functionality with defaults when no init contract is provided', async () => {
    const {erc721, erc721PluginManager, erc721AccessControl, erc721PluginViewer, pluginManagerContract, pluginViewerContract} = await createERC721();
    const signers = await ethers.getSigners();

    const erc721AutoIncrementMint = await deployments.get("ERC721AutoIncrementMint");
    const erc721AutoIncrementMintContract = await ethers.getContractAt("ERC721AutoIncrementMint", erc721AutoIncrementMint.address) as ERC721AutoIncrementMint

    const erc721AutoIncrementMintFunctionSelectors = await erc721AutoIncrementMintContract.getFunctionSelectors();
    const erc721AutoIncrementMintSingletonAddress = await erc721AutoIncrementMintContract.getSingletonAddress();

    let erc721AutoIncrementMintInstallationTx = await erc721PluginManager.update(
        [{
            pluginAddress: erc721AutoIncrementMintSingletonAddress,
            action: UpdateActionType.add,
            functionSelectors: erc721AutoIncrementMintFunctionSelectors
        }],
        ethers.constants.AddressZero,
        ethers.constants.HashZero
    )

    let erc721AutoIncrementMintInstallationReceipt = await erc721AutoIncrementMintInstallationTx.wait();

    let erc721ACM = await ethers.getContractAt("ERC721AutoIncrementMint", erc721.address) as ERC721AutoIncrementMint;

    assert.equal(erc721AutoIncrementMintInstallationReceipt.status, 1, "ERC721AutoIncrementMint installation unsuccessful");

    await expect(erc721ACM.connect(signers[1]).safeMint(signers[2].address)).to.not.be.reverted;
    expect(await erc721.ownerOf(1)).to.equal(signers[2].address)
    
    await expect(erc721ACM.connect(signers[2]).safeMint(signers[2].address)).to.not.be.reverted;
    expect(await erc721.ownerOf(2)).to.equal(signers[2].address)
    await expect(erc721ACM.connect(signers[0]).safeMint(signers[2].address)).to.not.be.reverted;
    expect(await erc721.ownerOf(3)).to.equal(signers[2].address)
    await expect(erc721ACM.connect(signers[0]).safeMint(signers[1].address)).to.not.be.reverted;
    expect(await erc721.ownerOf(4)).to.equal(signers[1].address)

    expect(await erc721.totalSupply()).to.equal(4, "Total supply miscalculated");
    expect(await erc721.tokenOfOwnerByIndex(signers[2].address, 2)).to.equal(3, "Could not retrieve token index");
    expect((await erc721.tokenByIndex(3))).to.equal(4);
  })

  it('Can install and use auto increment mint functionality with a set price', async () => {
    const {erc721, erc721PluginManager, erc721PluginViewer, pluginManagerContract, pluginViewerContract} = await createERC721();
    const signers = await ethers.getSigners();

    const erc721AutoIncrementMint = await deployments.get("ERC721AutoIncrementMint");
    const erc721AutoIncrementMintContract = await ethers.getContractAt("ERC721AutoIncrementMint", erc721AutoIncrementMint.address) as ERC721AutoIncrementMint

    const erc721AutoIncrementMintInit = await deployments.get("ERC721AutoIncrementMintInit");
    const erc721AutoIncrementMintInitContract = await ethers.getContractAt("ERC721AutoIncrementMintInit", erc721AutoIncrementMintInit.address) as ERC721AutoIncrementMintInit

    const erc721AutoIncrementMintFunctionSelectors = await erc721AutoIncrementMintContract.getFunctionSelectors();
    const erc721AutoIncrementMintSingletonAddress = await erc721AutoIncrementMintContract.getSingletonAddress();

    let erc721AutoIncrementMintInstallationTx = await erc721PluginManager.update(
        [{
            pluginAddress: erc721AutoIncrementMintSingletonAddress,
            action: UpdateActionType.add,
            functionSelectors: erc721AutoIncrementMintFunctionSelectors
        }],
        erc721AutoIncrementMintInit.address,
        erc721AutoIncrementMintInitContract.interface.encodeFunctionData('init', [ethers.utils.parseEther(".01"), 0, ""])
    )

    let erc721AutoIncrementMintInstallationReceipt = await erc721AutoIncrementMintInstallationTx.wait();

    let erc721ACM = await ethers.getContractAt("ERC721AutoIncrementMint", erc721.address) as ERC721AutoIncrementMint;

    assert.equal(erc721AutoIncrementMintInstallationReceipt.status, 1, "ERC721AutoIncrementMint installation unsuccessful");

    await expect(erc721ACM.connect(signers[1]).safeMint(signers[2].address, {value: ethers.utils.parseEther('.01')})).to.not.be.reverted; // 1
    await expect(erc721ACM.connect(signers[1]).safeMint(signers[2].address, {value: ethers.utils.parseEther('.001')})).to.be.reverted;
    await expect(erc721ACM.connect(signers[1]).safeMint(signers[2].address, {value: ethers.utils.parseEther('0')})).to.be.reverted;
    await expect(erc721ACM.connect(signers[1]).safeMint(signers[2].address, {value: ethers.utils.parseEther('1')})).to.not.be.reverted;

    expect(await erc721.tokenURI(1)).to.equal("");
    expect(await erc721.ownerOf(1)).to.equal(signers[2].address)
    
    await expect(erc721ACM.connect(signers[2]).safeMint(signers[2].address)).to.be.reverted;
    await expect(erc721ACM.connect(signers[0]).safeMint(signers[2].address)).to.be.reverted;
    await expect(erc721ACM.connect(signers[0]).safeMint(signers[1].address)).to.be.reverted;
  })

  it('Can install and use auto increment mint functionality with a set uniformURI', async () => {
    const {erc721, erc721PluginManager, erc721PluginViewer, pluginManagerContract, pluginViewerContract} = await createERC721();
    const signers = await ethers.getSigners();

    const erc721AutoIncrementMint = await deployments.get("ERC721AutoIncrementMint");
    const erc721AutoIncrementMintContract = await ethers.getContractAt("ERC721AutoIncrementMint", erc721AutoIncrementMint.address) as ERC721AutoIncrementMint

    const erc721AutoIncrementMintInit = await deployments.get("ERC721AutoIncrementMintInit");
    const erc721AutoIncrementMintInitContract = await ethers.getContractAt("ERC721AutoIncrementMintInit", erc721AutoIncrementMintInit.address) as ERC721AutoIncrementMintInit

    const erc721AutoIncrementMintFunctionSelectors = await erc721AutoIncrementMintContract.getFunctionSelectors();
    const erc721AutoIncrementMintSingletonAddress = await erc721AutoIncrementMintContract.getSingletonAddress();

    let erc721AutoIncrementMintInstallationTx = await erc721PluginManager.update(
        [{
            pluginAddress: erc721AutoIncrementMintSingletonAddress,
            action: UpdateActionType.add,
            functionSelectors: erc721AutoIncrementMintFunctionSelectors
        }],
        erc721AutoIncrementMintInit.address,
        erc721AutoIncrementMintInitContract.interface.encodeFunctionData('init', [0, 0, "someURI"])
    )

    let erc721AutoIncrementMintInstallationReceipt = await erc721AutoIncrementMintInstallationTx.wait();

    let erc721ACM = await ethers.getContractAt("ERC721AutoIncrementMint", erc721.address) as ERC721AutoIncrementMint;

    assert.equal(erc721AutoIncrementMintInstallationReceipt.status, 1, "ERC721AutoIncrementMint installation unsuccessful");

    await expect(erc721ACM.connect(signers[1]).safeMint(signers[2].address)).to.not.be.reverted;
    await expect(erc721ACM.connect(signers[1]).safeMint(signers[2].address)).to.not.be.reverted;
    expect(await erc721.ownerOf(1)).to.equal(signers[2].address)
    expect(await erc721.ownerOf(2)).to.equal(signers[2].address)
    expect(await erc721.tokenURI(1)).to.equal("someURI");
    expect(await erc721.tokenURI(2)).to.equal("someURI");
  })

  it('Can install and use auto increment mint functionality with a set previousTokenId', async () => {
    const {erc721, erc721PluginManager, erc721PluginViewer, pluginManagerContract, pluginViewerContract} = await createERC721();
    const signers = await ethers.getSigners();

    const erc721AutoIncrementMint = await deployments.get("ERC721AutoIncrementMint");
    const erc721AutoIncrementMintContract = await ethers.getContractAt("ERC721AutoIncrementMint", erc721AutoIncrementMint.address) as ERC721AutoIncrementMint

    const erc721AutoIncrementMintInit = await deployments.get("ERC721AutoIncrementMintInit");
    const erc721AutoIncrementMintInitContract = await ethers.getContractAt("ERC721AutoIncrementMintInit", erc721AutoIncrementMintInit.address) as ERC721AutoIncrementMintInit

    const erc721AutoIncrementMintFunctionSelectors = await erc721AutoIncrementMintContract.getFunctionSelectors();
    const erc721AutoIncrementMintSingletonAddress = await erc721AutoIncrementMintContract.getSingletonAddress();

    let erc721AutoIncrementMintInstallationTx = await erc721PluginManager.update(
        [{
            pluginAddress: erc721AutoIncrementMintSingletonAddress,
            action: UpdateActionType.add,
            functionSelectors: erc721AutoIncrementMintFunctionSelectors
        }],
        erc721AutoIncrementMintInit.address,
        erc721AutoIncrementMintInitContract.interface.encodeFunctionData('init', [0, 3, "someURI"])
    )

    let erc721AutoIncrementMintInstallationReceipt = await erc721AutoIncrementMintInstallationTx.wait();

    let erc721ACM = await ethers.getContractAt("ERC721AutoIncrementMint", erc721.address) as ERC721AutoIncrementMint;

    assert.equal(erc721AutoIncrementMintInstallationReceipt.status, 1, "ERC721AutoIncrementMint installation unsuccessful");

    await expect(erc721ACM.connect(signers[1]).safeMint(signers[2].address)).to.not.be.reverted;
    await expect(erc721ACM.connect(signers[1]).safeMint(signers[2].address)).to.not.be.reverted;
    expect(await erc721.ownerOf(4)).to.equal(signers[2].address)
    expect(await erc721.ownerOf(5)).to.equal(signers[2].address)
    expect(await erc721.tokenURI(4)).to.equal("someURI");
    expect(await erc721.tokenURI(5)).to.equal("someURI");

    expect(await erc721.ownerOf(1)).to.equal(ethers.constants.AddressZero)
    expect(await erc721.ownerOf(2)).to.equal(ethers.constants.AddressZero)
    expect(await erc721.ownerOf(3)).to.equal(ethers.constants.AddressZero)
  })
})

describe("ERC721 mod plugins", async function () {
  it('Can install and use balance limit functionality with a limit of 1', async () => {
    const {erc721, erc721PluginManager, erc721AccessControl, erc721PluginViewer} = await createERC721();
    const signers = await ethers.getSigners();

    const erc721BalanceLimit = await deployments.get("ERC721BalanceLimit");
    const erc721BalanceLimitContract = await ethers.getContractAt("ERC721BalanceLimit", erc721BalanceLimit.address) as ERC721BalanceLimit;

    const erc721BalanceLimitInit = await deployments.get("ERC721BalanceLimitInit");
    const erc721BalanceLimitInitContract = await ethers.getContractAt("ERC721BalanceLimitInit", erc721BalanceLimitInit.address) as ERC721BalanceLimitInit;

    const erc721BalanceLimitFunctionSelectors = await erc721BalanceLimitContract.getFunctionSelectors();
    const erc721BalanceLimitModSelectors = await erc721BalanceLimitContract.getModSelectors();

    const erc721BalanceLimitSingletonAddress = await erc721BalanceLimitContract.getSingletonAddress();


    let erc721BalanceLimitInstallationTx = await erc721PluginManager.update(
        [{
            pluginAddress: erc721BalanceLimitSingletonAddress,
            action: UpdateActionType.add,
            functionSelectors: erc721BalanceLimitFunctionSelectors
        }],
        erc721BalanceLimitInit.address,
        erc721BalanceLimitInitContract.interface.encodeFunctionData('init', [1, erc721BalanceLimit.address])
    )

    let erc721BalanceLimitInstallationReceipt = await erc721BalanceLimitInstallationTx.wait();

    assert.equal(erc721BalanceLimitInstallationReceipt.status, 1, "ERC721BalanceLimit installation unsuccessful");


    const erc721Mint = await deployments.get("ERC721Mint");
    const erc721MintContract = await ethers.getContractAt("ERC721Mint", erc721Mint.address) as ERC721Mint

    const erc721MintFunctionSelectors = await erc721MintContract.getFunctionSelectors();
    const erc721MintSingletonAddress = await erc721MintContract.getSingletonAddress();

    let erc721MintInstallationTx = await erc721PluginManager.update(
        [{
            pluginAddress: erc721MintSingletonAddress,
            action: UpdateActionType.add,
            functionSelectors: erc721MintFunctionSelectors
        }],
        ethers.constants.AddressZero,
        ethers.constants.HashZero
    )


    let erc721MintInstallationReceipt = await erc721MintInstallationTx.wait();

    let erc721M = await ethers.getContractAt("ERC721Mint", erc721.address) as ERC721Mint;

    await expect(erc721M.safeMint(signers[1].address, 2)).to.not.be.reverted;
    await expect(erc721M.safeMint(signers[1].address, 3)).to.be.revertedWith("Balance limit reached");
    await expect(erc721M.safeMint(signers[2].address, 3)).to.not.be.reverted;
    await expect(erc721.connect(signers[1]).transferFrom(signers[1].address, signers[2].address, 2)).to.be.revertedWith("Balance limit reached");
    await expect(erc721.connect(signers[1]).transferFrom(signers[1].address, signers[3].address, 2)).to.not.be.reverted;
    await expect(erc721M.safeMint(signers[3].address, 4)).to.be.revertedWith("Balance limit reached");

  })

  it('Can install and use balance limit functionality with a limit of 0', async () => {
    const {erc721, erc721PluginManager, erc721AccessControl, erc721PluginViewer} = await createERC721();
    const signers = await ethers.getSigners();

    const erc721BalanceLimit = await deployments.get("ERC721BalanceLimit");
    const erc721BalanceLimitContract = await ethers.getContractAt("ERC721BalanceLimit", erc721BalanceLimit.address) as ERC721BalanceLimit;

    const erc721BalanceLimitInit = await deployments.get("ERC721BalanceLimitInit");
    const erc721BalanceLimitInitContract = await ethers.getContractAt("ERC721BalanceLimitInit", erc721BalanceLimitInit.address) as ERC721BalanceLimitInit;

    const erc721BalanceLimitFunctionSelectors = await erc721BalanceLimitContract.getFunctionSelectors();
    const erc721BalanceLimitModSelectors = await erc721BalanceLimitContract.getModSelectors();

    const erc721BalanceLimitSingletonAddress = await erc721BalanceLimitContract.getSingletonAddress();


    let erc721BalanceLimitInstallationTx = await erc721PluginManager.update(
        [{
            pluginAddress: erc721BalanceLimitSingletonAddress,
            action: UpdateActionType.add,
            functionSelectors: erc721BalanceLimitFunctionSelectors
        }],
        erc721BalanceLimitInit.address,
        erc721BalanceLimitInitContract.interface.encodeFunctionData('init', [0, erc721BalanceLimit.address])
    )

    let erc721BalanceLimitInstallationReceipt = await erc721BalanceLimitInstallationTx.wait();

    assert.equal(erc721BalanceLimitInstallationReceipt.status, 1, "ERC721BalanceLimit installation unsuccessful");


    const erc721Mint = await deployments.get("ERC721Mint");
    const erc721MintContract = await ethers.getContractAt("ERC721Mint", erc721Mint.address) as ERC721Mint

    const erc721MintFunctionSelectors = await erc721MintContract.getFunctionSelectors();
    const erc721MintSingletonAddress = await erc721MintContract.getSingletonAddress();

    let erc721MintInstallationTx = await erc721PluginManager.update(
        [{
            pluginAddress: erc721MintSingletonAddress,
            action: UpdateActionType.add,
            functionSelectors: erc721MintFunctionSelectors
        }],
        ethers.constants.AddressZero,
        ethers.constants.HashZero
    )


    let erc721MintInstallationReceipt = await erc721MintInstallationTx.wait();

    let erc721M = await ethers.getContractAt("ERC721Mint", erc721.address) as ERC721Mint;

    await expect(erc721M.safeMint(signers[1].address, 2)).to.be.revertedWith("Balance limit reached");
    await expect(erc721M.safeMint(signers[1].address, 3)).to.be.revertedWith("Balance limit reached");

  })

  it('Can install and use non-transferable functionality', async () => {
    const {erc721, erc721PluginManager, erc721AccessControl, erc721PluginViewer} = await createERC721();
    const signers = await ethers.getSigners();

    const erc721NonTransferable = await deployments.get("ERC721NonTransferable");
    const erc721NonTransferableContract = await ethers.getContractAt("ERC721NonTransferable", erc721NonTransferable.address) as ERC721NonTransferable;

    const erc721NonTransferableInit = await deployments.get("ERC721NonTransferableInit");
    const erc721NonTransferableInitContract = await ethers.getContractAt("ERC721NonTransferableInit", erc721NonTransferableInit.address) as ERC721NonTransferableInit;

    const erc721NonTransferableFunctionSelectors = await erc721NonTransferableContract.getFunctionSelectors();
    const erc721NonTransferableModSelectors = await erc721NonTransferableContract.getModSelectors();

    const erc721NonTransferableSingletonAddress = await erc721NonTransferableContract.getSingletonAddress();


    let erc721NonTransferableInstallationTx = await erc721PluginManager.update(
        [{
            pluginAddress: erc721NonTransferableSingletonAddress,
            action: UpdateActionType.add,
            functionSelectors: erc721NonTransferableFunctionSelectors
        }],
        erc721NonTransferableInit.address,
        erc721NonTransferableInitContract.interface.encodeFunctionData('init', [erc721NonTransferable.address])
    )

    let erc721NonTransferableInstallationReceipt = await erc721NonTransferableInstallationTx.wait();

    assert.equal(erc721NonTransferableInstallationReceipt.status, 1, "ERC721NonTransferable installation unsuccessful");


    const erc721Mint = await deployments.get("ERC721Mint");
    const erc721MintContract = await ethers.getContractAt("ERC721Mint", erc721Mint.address) as ERC721Mint

    const erc721MintFunctionSelectors = await erc721MintContract.getFunctionSelectors();
    const erc721MintSingletonAddress = await erc721MintContract.getSingletonAddress();

    let erc721MintInstallationTx = await erc721PluginManager.update(
        [{
            pluginAddress: erc721MintSingletonAddress,
            action: UpdateActionType.add,
            functionSelectors: erc721MintFunctionSelectors
        }],
        ethers.constants.AddressZero,
        ethers.constants.HashZero
    )


    let erc721MintInstallationReceipt = await erc721MintInstallationTx.wait();

    let erc721M = await ethers.getContractAt("ERC721Mint", erc721.address) as ERC721Mint;

    // First, mint a token
    await erc721M.safeMint(signers[1].address, 2);
    // Try to transfer the token
    await expect(erc721.connect(signers[1]).transferFrom(signers[1].address, signers[2].address, 2)).to.be.revertedWith("Token is not transferable");
  })

  it('Can install and use both balance limit & non transferable functionality', async () => {
    const {erc721, erc721PluginManager, erc721AccessControl, erc721PluginViewer} = await createERC721();
    const signers = await ethers.getSigners();

    const erc721BalanceLimit = await deployments.get("ERC721BalanceLimit");
    const erc721BalanceLimitContract = await ethers.getContractAt("ERC721BalanceLimit", erc721BalanceLimit.address) as ERC721BalanceLimit;

    const erc721BalanceLimitInit = await deployments.get("ERC721BalanceLimitInit");
    const erc721BalanceLimitInitContract = await ethers.getContractAt("ERC721BalanceLimitInit", erc721BalanceLimitInit.address) as ERC721BalanceLimitInit;

    const erc721BalanceLimitFunctionSelectors = await erc721BalanceLimitContract.getFunctionSelectors();
    const erc721BalanceLimitModSelectors = await erc721BalanceLimitContract.getModSelectors();

    const erc721BalanceLimitSingletonAddress = await erc721BalanceLimitContract.getSingletonAddress();


    let erc721BalanceLimitInstallationTx = await erc721PluginManager.update(
        [{
            pluginAddress: erc721BalanceLimitSingletonAddress,
            action: UpdateActionType.add,
            functionSelectors: erc721BalanceLimitFunctionSelectors
        }],
        erc721BalanceLimitInit.address,
        erc721BalanceLimitInitContract.interface.encodeFunctionData('init', [1, erc721BalanceLimit.address])
    )

    let erc721BalanceLimitInstallationReceipt = await erc721BalanceLimitInstallationTx.wait();

    assert.equal(erc721BalanceLimitInstallationReceipt.status, 1, "ERC721BalanceLimit installation unsuccessful");

    const erc721NonTransferable = await deployments.get("ERC721NonTransferable");
    const erc721NonTransferableContract = await ethers.getContractAt("ERC721NonTransferable", erc721NonTransferable.address) as ERC721NonTransferable;

    const erc721NonTransferableInit = await deployments.get("ERC721NonTransferableInit");
    const erc721NonTransferableInitContract = await ethers.getContractAt("ERC721NonTransferableInit", erc721NonTransferableInit.address) as ERC721NonTransferableInit;

    const erc721NonTransferableFunctionSelectors = await erc721NonTransferableContract.getFunctionSelectors();
    const erc721NonTransferableModSelectors = await erc721NonTransferableContract.getModSelectors();

    const erc721NonTransferableSingletonAddress = await erc721NonTransferableContract.getSingletonAddress();


    let erc721NonTransferableInstallationTx = await erc721PluginManager.update(
        [{
            pluginAddress: erc721NonTransferableSingletonAddress,
            action: UpdateActionType.add,
            functionSelectors: erc721NonTransferableFunctionSelectors
        }],
        erc721NonTransferableInit.address,
        erc721NonTransferableInitContract.interface.encodeFunctionData('init', [erc721NonTransferable.address])
    )

    let erc721NonTransferableInstallationReceipt = await erc721NonTransferableInstallationTx.wait();

    assert.equal(erc721NonTransferableInstallationReceipt.status, 1, "ERC721NonTransferable installation unsuccessful");


    const erc721Mint = await deployments.get("ERC721Mint");
    const erc721MintContract = await ethers.getContractAt("ERC721Mint", erc721Mint.address) as ERC721Mint

    const erc721MintFunctionSelectors = await erc721MintContract.getFunctionSelectors();
    const erc721MintSingletonAddress = await erc721MintContract.getSingletonAddress();

    let erc721MintInstallationTx = await erc721PluginManager.update(
        [{
            pluginAddress: erc721MintSingletonAddress,
            action: UpdateActionType.add,
            functionSelectors: erc721MintFunctionSelectors
        }],
        ethers.constants.AddressZero,
        ethers.constants.HashZero
    )


    let erc721MintInstallationReceipt = await erc721MintInstallationTx.wait();

    let erc721M = await ethers.getContractAt("ERC721Mint", erc721.address) as ERC721Mint;

    await expect(erc721M.safeMint(signers[1].address, 2)).to.not.be.reverted;
    await expect(erc721M.safeMint(signers[1].address, 3)).to.be.revertedWith("Balance limit reached");
    await expect(erc721M.safeMint(signers[2].address, 3)).to.not.be.reverted;
    await expect(erc721.connect(signers[1]).transferFrom(signers[1].address, signers[2].address, 2)).to.be.revertedWith("Balance limit reached");
    await expect(erc721.connect(signers[1]).transferFrom(signers[1].address, signers[3].address, 2)).to.be.revertedWith("Token is not transferable");
    await expect(erc721M.safeMint(signers[3].address, 4)).to.not.be.reverted;

  })

})