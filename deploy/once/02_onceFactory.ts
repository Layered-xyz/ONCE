import { keccak256 } from 'ethers/lib/utils';
import {addDeployedContract} from '../../utils/helpers';
import {DeployFunction} from 'hardhat-deploy/types';
import {HardhatRuntimeEnvironment} from 'hardhat/types';
import { utils } from 'ethers';


const name = 'OnceFactory';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  console.log(`Deploying ${name} contracts`);

  const {deployments, network, getNamedAccounts} = hre;
  const {deploy} = deployments;
  const {deployer} = await getNamedAccounts();

  const OnceFactoryStorage = await deploy("OnceFactoryStorage", {
    from: deployer,
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "OnceFactoryStorage", OnceFactoryStorage.address);


  const OnceFactoryInit = await deploy("OnceFactoryInit", {
    from: deployer,
    args: [],
    log: true,
    libraries: {
      OnceFactoryStorage: OnceFactoryStorage.address,
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  })

  addDeployedContract(network.name, "OnceFactoryInit", OnceFactoryInit.address);

  const OnceFactory = await deploy("OnceFactory", {
    from: deployer,
    args: [],
    log: true,
    libraries: {
      OnceFactoryStorage: OnceFactoryStorage.address
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  })

  addDeployedContract(network.name, "OnceFactory", OnceFactory.address);
  
  
};

export default func;
func.tags = [name];