import { keccak256 } from 'ethers/lib/utils';
import {addDeployedContract, ContractList, getDeployedContracts} from '../../utils/helpers';
import {DeployFunction} from 'hardhat-deploy/types';
import {HardhatRuntimeEnvironment} from 'hardhat/types';
import { utils } from 'ethers';
import { OnceFactory__factory, OnceFactoryInit__factory, PluginManager__factory } from '../../typechain';


const name = 'OnceFactoryInstance';

enum UpdateActionType {
  add, replace, remove
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  console.log(`Deploying ${name} contracts`);

  const {deployments, network, getNamedAccounts} = hre;
  const {deploy} = deployments;
  const [deployer] = await hre.ethers.getSigners();
  const deployedContracts: ContractList = getDeployedContracts();

  const OnceFactory = await deploy("Once", {
    from: deployer.address,
    args: [
      deployer.address,
      deployedContracts[network.name]["PluginManager"], 
      deployedContracts[network.name]["PluginViewer"], 
      deployedContracts[network.name]["AccessControl"]
    ],
    log: true,
    libraries: {
      OnceStorage: deployedContracts[network.name]["OnceStorage"]
    },
    deterministicDeployment: utils.id("layered.once.factory.v0.1.443e20e5")
  })

  await deployments.save("OnceFactoryInstance", OnceFactory)

  const onceFactoryPluginManager = PluginManager__factory.connect(
    OnceFactory.address,
    deployer
  )

  const onceFactoryPlugin = OnceFactory__factory.connect(
    deployedContracts[network.name]["OnceFactory"],
    deployer
  )

  const onceFactoryInit = OnceFactoryInit__factory.connect(
    deployedContracts[network.name]["OnceFactoryInit"],
    deployer
  )

  const onceFactoryFunctionSelectors = await onceFactoryPlugin.getFunctionSelectors();
  const onceFactoryCallData = onceFactoryInit.interface.encodeFunctionData("init", [
    deployedContracts[network.name]["PluginManager"], 
    deployedContracts[network.name]["PluginViewer"], 
    deployedContracts[network.name]["AccessControl"]
  ])

  let onceFactoryInstallTx = await onceFactoryPluginManager.update(
    [{
      pluginAddress: onceFactoryPlugin.address,
      action: UpdateActionType.add,
      functionSelectors: onceFactoryFunctionSelectors
    }], 
    onceFactoryInit.address, 
    onceFactoryCallData
  )

  let onceFactoryTxReceipt = await onceFactoryInstallTx.wait();

  if(onceFactoryTxReceipt.status) {
    console.log("Successfully installed OnceFactory");

    addDeployedContract(network.name, "OnceFactoryInstance", OnceFactory.address);
  } else {
    console.log("OnceFactory Installation unsuccessful")
  }
  
};

export default func;
func.tags = [name];