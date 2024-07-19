import { FunctionFragment, keccak256 } from 'ethers/lib/utils';
import {addDeployedContract} from '../../utils/helpers';
import {DeployFunction} from 'hardhat-deploy/types';
import {HardhatRuntimeEnvironment} from 'hardhat/types';
import { utils } from 'ethers';
import singletonInterface from '../../utils/safe';


const name = 'Safe';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  console.log(`Deploying ${name} contracts`);

  const selectors = singletonInterface.fragments.filter((fragment) => fragment.type === 'function').map((func) => {return singletonInterface.getSighash(func)})

  const {deployments, network, getNamedAccounts} = hre;
  const {deploy} = deployments;
  const {deployer} = await getNamedAccounts();



  const SafeProxy = await deploy("SafeProxy", {
    from: deployer,
    args: ["0x29fcB43b46531BcA003ddC8FCB67FFE91900C762", selectors], // 1.4.1
    log: true,
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "SafeProxy", SafeProxy.address);

  const SafeInit = await deploy("SafeProxyInit", {
    from: deployer,
    args: [],
    log: true,
    deterministicDeployment: utils.id("layered.once.443e20e5")
  })

  addDeployedContract(network.name, "SafeProxyInit", SafeInit.address);

};

export default func;
func.tags = [name];