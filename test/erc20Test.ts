import { ethers, deployments, getNamedAccounts } from "hardhat";

import { ContractReceipt, providers, utils } from "ethers";
import { assert, expect } from "chai";

import { Once, OnceFactory, PluginManager, IPluginManager, PluginViewer, IPluginViewer, OnceInit, OnceFactoryInit, AccessControl, Once__factory, ERC20, SafeProxy, SafeProxyInit, SafeL2, Safe, StorageSetter, Reverter, ERC20Init, ERC20AccessControlMint, ERC20Burnable } from "../typechain";
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

// Deploys a 1:1 Safe on Once for testing
const createERC20 = deployments.createFixture(
    async ({deployments, getNamedAccounts, ethers}, options) => {
        await deployments.fixture(["Once", "OnceFactory", "OnceFactoryInstance", "ERC20"]);
        const {deployer} = await getNamedAccounts();
        const signers = await ethers.getSigners();

        const pluginViewer = await deployments.get("PluginViewer");
        const pluginManager = await deployments.get("PluginManager");
        const accessControl = await deployments.get("AccessControl");
        const erc20Singleton = await deployments.get("ERC20");
        const erc20Init = await deployments.get("ERC20Init");
        

        const once = await ethers.getContractFactory("Once");

        const pluginViewerContract = await ethers.getContractAt("PluginViewer", pluginViewer.address) as PluginViewer;
        const pluginManagerContract = await ethers.getContractAt("PluginManager", pluginManager.address) as PluginManager;
        const accessControlContract = await ethers.getContractAt("AccessControl", accessControl.address) as AccessControl;
        const erc20SingletonContract = await ethers.getContractAt("ERC20", erc20Singleton.address) as ERC20;
        const erc20InitContract = await ethers.getContractAt("ERC20Init", erc20Init.address) as ERC20Init;

        const erc20Once = await once.deploy(ethers.constants.AddressZero, pluginManager.address, pluginViewer.address, accessControl.address);
        await erc20Once.deployed();

        const erc20PluginManager = await ethers.getContractAt("PluginManager", erc20Once.address) as PluginManager;
        const erc20PluginViewer = await ethers.getContractAt("PluginViewer", erc20Once.address) as PluginViewer;
        const erc20AccessControl = await ethers.getContractAt("AccessControl", erc20Once.address) as AccessControl;
        const erc20 = await ethers.getContractAt("ERC20", erc20Once.address) as ERC20;

        const erc20Selectors = await erc20SingletonContract.getFunctionSelectors();
        const erc20SingletonAddress = await erc20SingletonContract.getSingletonAddress();

        let erc20InstallationTx = await erc20PluginManager.update(
            [{
                pluginAddress: erc20SingletonAddress,
                action: UpdateActionType.add,
                functionSelectors: erc20Selectors
            }],
            erc20Init.address,
            erc20InitContract.interface.encodeFunctionData('init', [
                "TestToken", 
                "TTKN", 
                18, 
                [], 
                []
            ])
        )


        let erc20InstallationReceipt = await erc20InstallationTx.wait();

        if(erc20InstallationReceipt.status != 1) {
            throw("Error with erc20 installation")
        }

        return {
            erc20: erc20,
            erc20PluginManager: erc20PluginManager,
            erc20PluginViewer: erc20PluginViewer,
            erc20AccessControl: erc20AccessControl,
            pluginViewerContract: pluginViewerContract,
            pluginManagerContract: pluginManagerContract,
            accessControlContract: accessControlContract
        }
    }
      
)

describe("Core ERC20 Once Plugin", async function () {

    it('Successfully stores and returns name, symbol, and decimals', async () => {
        const {erc20, erc20PluginManager, erc20PluginViewer, pluginManagerContract, pluginViewerContract} = await createERC20();

        let nameResult: string = await erc20.name();
        let symbolResult: string = await erc20.symbol();
        let decimalsResult: Number = await erc20.decimals();

        assert.equal(nameResult, "TestToken", "Name does not match");
        assert.equal(symbolResult, "TTKN", "Symbol does not match");
        assert.equal(decimalsResult, 18, "Decimals does not match");
    })
    
    it('Can install and use access control mint functionality', async () => {
        const {erc20, erc20PluginManager, erc20AccessControl, erc20PluginViewer, pluginManagerContract, pluginViewerContract} = await createERC20();
        const signers = await ethers.getSigners();

        const erc20AccessControlMint = await deployments.get("ERC20AccessControlMint");
        const erc20AccessControlMintContract = await ethers.getContractAt("ERC20AccessControlMint", erc20AccessControlMint.address) as ERC20AccessControlMint

        const erc20AccessControlMintFunctionSelectors = await erc20AccessControlMintContract.getFunctionSelectors();
        const erc20AccessControlMintSingletonAddress = await erc20AccessControlMintContract.getSingletonAddress();

        const erc20Burnable = await deployments.get("ERC20Burnable");
        const erc20BurnableContract = await ethers.getContractAt("ERC20Burnable", erc20Burnable.address) as ERC20Burnable;


        let erc20AccessControlMintInstallationTx = await erc20PluginManager.update(
            [{
                pluginAddress: erc20AccessControlMintSingletonAddress,
                action: UpdateActionType.add,
                functionSelectors: erc20AccessControlMintFunctionSelectors
            }],
            ethers.constants.AddressZero,
            ethers.constants.HashZero
        )

        let erc20AccessControlMintInstallationReceipt = await erc20AccessControlMintInstallationTx.wait();

        let erc20ACM = await ethers.getContractAt("ERC20AccessControlMint", erc20.address) as ERC20AccessControlMint;

        assert.equal(erc20AccessControlMintInstallationReceipt.status, 1, "ERC20AccessControlMint installation unsuccessful");

        await erc20AccessControl.connect(signers[0]).grantRole(ethers.utils.id('LAYERED_ONCE_ERC20_MINTER_ROLE'), signers[1].address)
        expect(await erc20AccessControl.hasRole(ethers.utils.id('LAYERED_ONCE_ERC20_MINTER_ROLE'), signers[1].address)).to.be.true
        expect(await erc20AccessControl.hasRole(ethers.constants.HashZero, signers[1].address)).to.be.false
        expect(await erc20AccessControl.hasRole(ethers.constants.HashZero, signers[0].address)).to.be.true // DEFAULT_ADMIN_ROLE

        await expect(erc20ACM.connect(signers[1]).mint(signers[2].address, 10)).to.not.be.reverted;
        expect(await erc20.balanceOf(signers[2].address)).to.equal(10)
        
        await expect(erc20ACM.connect(signers[2]).mint(signers[2].address, 10)).to.be.reverted;
        await expect(erc20ACM.connect(signers[0]).mint(signers[2].address, 10)).to.be.reverted;
        await expect(erc20ACM.connect(signers[0]).mint(signers[1].address, 10)).to.be.reverted;
    })

    it('Can install and use burnable functionality', async () => {
        
    })

    it('Can install and use capped functionality', async () => {
        
    })

    it('Can install and use non-transferable functionality', async () => {
        
    })

    it('Can install and use pausable functionality', async () => {
        
    })
    

});