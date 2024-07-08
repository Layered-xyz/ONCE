import { keccak256 } from 'ethers/lib/utils';
import {addDeployedContract} from '../../utils/helpers';
import {DeployFunction} from 'hardhat-deploy/types';
import {HardhatRuntimeEnvironment} from 'hardhat/types';
import { utils } from 'ethers';


const name = 'Once';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  console.log(`Deploying ${name} contracts`);

  const {deployments, network, getNamedAccounts} = hre;
  const {deploy} = deployments;
  const {deployer} = await getNamedAccounts();

  const OnceStorage = await deploy("OnceStorage", {
    from: deployer,
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "OnceStorage", OnceStorage.address);


  const OnceInit = await deploy("OnceInit", {
    from: deployer,
    args: [],
    log: true,
    libraries: {
      OnceStorage: OnceStorage.address,
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  })

  addDeployedContract(network.name, "OnceInit", OnceInit.address);

  const PluginManagerStorage = await deploy("PluginManagerStorage", {
    from: deployer,
    libraries: {
      OnceStorage: OnceStorage.address,
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "PluginManagerStorage", PluginManagerStorage.address);

  const PluginManager = await deploy("PluginManager", {
    from: deployer,
    args: [],
    log: true,
    libraries: {
      OnceStorage: OnceStorage.address,
      PluginManagerStorage: PluginManagerStorage.address
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  })

  addDeployedContract(network.name, "PluginManager", PluginManager.address);

  const PluginViewer = await deploy("PluginViewer", {
    from: deployer,
    args: [],
    log: true,
    libraries: {
      OnceStorage: OnceStorage.address
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  })

  addDeployedContract(network.name, "PluginViewer", PluginViewer.address);

  const AccessControl = await deploy("AccessControl", {
    from: deployer,
    args: [],
    log: true,
    libraries: {
      OnceStorage: OnceStorage.address
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  })

  addDeployedContract(network.name, "AccessControl", AccessControl.address);

  
  
};

export default func;
func.tags = [name];