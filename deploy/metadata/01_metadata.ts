import { FunctionFragment, keccak256 } from 'ethers/lib/utils';
import {addDeployedContract} from '../../utils/helpers';
import {DeployFunction} from 'hardhat-deploy/types';
import {HardhatRuntimeEnvironment} from 'hardhat/types';
import { utils } from 'ethers';


const name = 'Metadata';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  console.log(`Deploying ${name} contracts`);

  const {deployments, network, getNamedAccounts} = hre;
  const {deploy} = deployments;
  const {deployer} = await getNamedAccounts();

  const MetadataStorage = await deploy("MetadataStorage", {
    from: deployer,
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "MetadataStorage", MetadataStorage.address);

  const Metadata = await deploy("Metadata", {
    from: deployer,
    args: [],
    log: true,
    libraries: {
        MetadataStorage: MetadataStorage.address,
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "Metadata", Metadata.address);

  const MetadataInit = await deploy("MetadataInit", {
    from: deployer,
    args: [],
    log: true,
    libraries: {
        MetadataStorage: MetadataStorage.address,
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  })

  addDeployedContract(network.name, "MetadataInit", MetadataInit.address);

};

export default func;
func.tags = [name];