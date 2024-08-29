import { keccak256 } from 'ethers/lib/utils';
import {addDeployedContract} from '../../utils/helpers';
import {DeployFunction} from 'hardhat-deploy/types';
import {HardhatRuntimeEnvironment} from 'hardhat/types';
import { utils } from 'ethers';


const name = 'ERC721';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  console.log(`Deploying ${name} contracts`);

  const {deployments, network, getNamedAccounts} = hre;
  const {deploy} = deployments;
  const {deployer} = await getNamedAccounts();

  // Core ERC721

  const ERC721Lib = await deploy("ERC721Lib", {
    from: deployer,
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "ERC721Lib", ERC721Lib.address);


  const ERC721Init = await deploy("ERC721Init", {
    from: deployer,
    args: [],
    log: true,
    libraries: {
      ERC721Lib: ERC721Lib.address,
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  })

  addDeployedContract(network.name, "ERC721Init", ERC721Init.address);

  const ERC721 = await deploy("ERC721", {
    from: deployer,
    libraries: {
      ERC721Lib: ERC721Lib.address,
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "ERC721", ERC721.address);

  // ERC721BalanceLimit

  const ERC721BalanceLimitStorage = await deploy("ERC721BalanceLimitStorage", {
    from: deployer,
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "ERC721BalanceLimitStorage", ERC721BalanceLimitStorage.address);


  const ERC721BalanceLimitInit = await deploy("ERC721BalanceLimitInit", {
    from: deployer,
    args: [],
    log: true,
    libraries: {
      ERC721Lib: ERC721Lib.address,
      ERC721BalanceLimitStorage: ERC721BalanceLimitStorage.address
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  })

  addDeployedContract(network.name, "ERC721BalanceLimitInit", ERC721BalanceLimitInit.address);

  const ERC721BalanceLimit = await deploy("ERC721BalanceLimit", {
    from: deployer,
    libraries: {
      ERC721Lib: ERC721Lib.address,
      ERC721BalanceLimitStorage: ERC721BalanceLimitStorage.address
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "ERC721BalanceLimit", ERC721BalanceLimit.address);

  
  // ERC721NonTransferable

  const ERC721NonTransferableInit = await deploy("ERC721NonTransferableInit", {
    from: deployer,
    args: [],
    log: true,
    libraries: {
      ERC721Lib: ERC721Lib.address,
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  })

  addDeployedContract(network.name, "ERC721NonTransferableInit", ERC721NonTransferableInit.address);

  const ERC721NonTransferable = await deploy("ERC721NonTransferable", {
    from: deployer,
    libraries: {
      ERC721Lib: ERC721Lib.address,
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "ERC721NonTransferable", ERC721NonTransferable.address);

  // ERC721Mint

  const ERC721MintStorage = await deploy("ERC721MintStorage", {
    from: deployer,
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "ERC721MintStorage", ERC721MintStorage.address);

  const ERC721Mint = await deploy("ERC721Mint", {
    from: deployer,
    libraries: {
      ERC721Lib: ERC721Lib.address,
      ERC721MintStorage: ERC721MintStorage.address
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "ERC721Mint", ERC721Mint.address);

  const ERC721MintInit = await deploy("ERC721MintInit", {
    from: deployer,
    libraries: {
      ERC721Lib: ERC721Lib.address,
      ERC721MintStorage: ERC721MintStorage.address
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "ERC721MintInit", ERC721MintInit.address);

  // ERC721AccessControlMint

  const ERC721AccessControlMintStorage = await deploy("ERC721AccessControlMintStorage", {
    from: deployer,
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "ERC721AccessControlMintStorage", ERC721AccessControlMintStorage.address);

  const ERC721AccessControlMint = await deploy("ERC721AccessControlMint", {
    from: deployer,
    libraries: {
      ERC721Lib: ERC721Lib.address,
      ERC721AccessControlMintStorage: ERC721AccessControlMintStorage.address
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "ERC721AccessControlMint", ERC721AccessControlMint.address);

  const ERC721AccessControlMintInit = await deploy("ERC721AccessControlMintInit", {
    from: deployer,
    libraries: {
      ERC721Lib: ERC721Lib.address,
      ERC721AccessControlMintStorage: ERC721AccessControlMintStorage.address
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "ERC721AccessControlMintInit", ERC721AccessControlMintInit.address);

  // ERC721AutoIncrementAccessControlMint

  const ERC721AutoIncrementAccessControlMintStorage = await deploy("ERC721AutoIncrementAccessControlMintStorage", {
    from: deployer,
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "ERC721AutoIncrementAccessControlMintStorage", ERC721AutoIncrementAccessControlMintStorage.address);

  const ERC721AutoIncrementAccessControlMint = await deploy("ERC721AutoIncrementAccessControlMint", {
    from: deployer,
    libraries: {
      ERC721Lib: ERC721Lib.address,
      ERC721AutoIncrementAccessControlMintStorage: ERC721AutoIncrementAccessControlMintStorage.address
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "ERC721AutoIncrementAccessControlMint", ERC721AutoIncrementAccessControlMint.address);

  const ERC721AutoIncrementAccessControlMintInit = await deploy("ERC721AutoIncrementAccessControlMintInit", {
    from: deployer,
    libraries: {
      ERC721Lib: ERC721Lib.address,
      ERC721AutoIncrementAccessControlMintStorage: ERC721AutoIncrementAccessControlMintStorage.address
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "ERC721AutoIncrementAccessControlMintInit", ERC721AutoIncrementAccessControlMintInit.address);


  // ERC721AutoIncrementMint

  const ERC721AutoIncrementMintStorage = await deploy("ERC721AutoIncrementMintStorage", {
    from: deployer,
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "ERC721AutoIncrementMintStorage", ERC721AutoIncrementMintStorage.address);

  const ERC721AutoIncrementMint = await deploy("ERC721AutoIncrementMint", {
    from: deployer,
    libraries: {
      ERC721Lib: ERC721Lib.address,
      ERC721AutoIncrementMintStorage: ERC721AutoIncrementMintStorage.address
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "ERC721AutoIncrementMint", ERC721AutoIncrementMint.address);

  const ERC721AutoIncrementMintInit = await deploy("ERC721AutoIncrementMintInit", {
    from: deployer,
    libraries: {
      ERC721Lib: ERC721Lib.address,
      ERC721AutoIncrementMintStorage: ERC721AutoIncrementMintStorage.address
    },
    deterministicDeployment: utils.id("layered.once.443e20e5")
  });

  addDeployedContract(network.name, "ERC721AutoIncrementMintInit", ERC721AutoIncrementMintInit.address);

  
  
};

export default func;
func.tags = [name];