import { keccak256 } from 'ethers/lib/utils';
import {addDeployedContract} from '../../utils/helpers';
import {DeployFunction} from 'hardhat-deploy/types';
import {HardhatRuntimeEnvironment} from 'hardhat/types';
import { utils } from 'ethers';


const name = 'ERC20';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  console.log(`Deploying ${name} contracts`);

  const {deployments, network, getNamedAccounts} = hre;
  const {deploy} = deployments;
  const {deployer} = await getNamedAccounts();

  // Core ERC20

  const ERC20Lib = await deploy("ERC20Lib", {
    from: deployer,
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "ERC20Lib", ERC20Lib.address);


  const ERC20Init = await deploy("ERC20Init", {
    from: deployer,
    args: [],
    log: true,
    libraries: {
      ERC20Lib: ERC20Lib.address,
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  })

  addDeployedContract(network.name, "ERC20Init", ERC20Init.address);

  const ERC20 = await deploy("ERC20", {
    from: deployer,
    libraries: {
      ERC20Lib: ERC20Lib.address,
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "ERC20", ERC20.address);

  // ERC20Capped

  const ERC20CappedStorage = await deploy("ERC20CappedStorage", {
    from: deployer,
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "ERC20CappedStorage", ERC20CappedStorage.address);


  const ERC20CappedInit = await deploy("ERC20CappedInit", {
    from: deployer,
    args: [],
    log: true,
    libraries: {
      ERC20Lib: ERC20Lib.address,
      ERC20CappedStorage: ERC20CappedStorage.address
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  })

  addDeployedContract(network.name, "ERC20CappedInit", ERC20CappedInit.address);

  const ERC20Capped = await deploy("ERC20Capped", {
    from: deployer,
    libraries: {
      ERC20Lib: ERC20Lib.address,
      ERC20CappedStorage: ERC20CappedStorage.address
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "ERC20Capped", ERC20Capped.address);

  // ERC20Burnable

  const ERC20Burnable = await deploy("ERC20Burnable", {
    from: deployer,
    libraries: {
      ERC20Lib: ERC20Lib.address,
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "ERC20Burnable", ERC20Burnable.address);

  // ERC20AccessControlMint

  const ERC20AccessControlMint = await deploy("ERC20AccessControlMint", {
    from: deployer,
    libraries: {
      ERC20Lib: ERC20Lib.address,
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "ERC20AccessControlMint", ERC20AccessControlMint.address);

  // ERC20NonTransferable

  const ERC20NonTransferableInit = await deploy("ERC20NonTransferableInit", {
    from: deployer,
    args: [],
    log: true,
    libraries: {
      ERC20Lib: ERC20Lib.address,
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  })

  addDeployedContract(network.name, "ERC20NonTransferableInit", ERC20NonTransferableInit.address);

  const ERC20NonTransferable = await deploy("ERC20NonTransferable", {
    from: deployer,
    libraries: {
      ERC20Lib: ERC20Lib.address,
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "ERC20NonTransferable", ERC20NonTransferable.address);

  // ERC20Pausable

  const ERC20PausableStorage = await deploy("ERC20PausableStorage", {
    from: deployer,
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "ERC20PausableStorage", ERC20PausableStorage.address);


  const ERC20PausableInit = await deploy("ERC20PausableInit", {
    from: deployer,
    args: [],
    log: true,
    libraries: {
      ERC20Lib: ERC20Lib.address,
      ERC20PausableStorage: ERC20PausableStorage.address
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  })

  addDeployedContract(network.name, "ERC20PausableInit", ERC20PausableInit.address);

  const ERC20Pausable = await deploy("ERC20Pausable", {
    from: deployer,
    libraries: {
      ERC20Lib: ERC20Lib.address,
      ERC20PausableStorage: ERC20PausableStorage.address
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "ERC20Pausable", ERC20Pausable.address);

  // ERC20Votes

  const ERC20VotesStorage = await deploy("ERC20VotesStorage", {
    from: deployer,
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "ERC20VotesStorage", ERC20VotesStorage.address);


  const ERC20VotesInit = await deploy("ERC20VotesInit", {
    from: deployer,
    args: [],
    log: true,
    libraries: {
      ERC20Lib: ERC20Lib.address,
      ERC20VotesStorage: ERC20VotesStorage.address
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  })

  addDeployedContract(network.name, "ERC20VotesInit", ERC20VotesInit.address);

  const ERC20Votes = await deploy("ERC20Votes", {
    from: deployer,
    libraries: {
      ERC20Lib: ERC20Lib.address,
      ERC20VotesStorage: ERC20VotesStorage.address
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "ERC20Votes", ERC20Votes.address);
  
};

export default func;
func.tags = [name];