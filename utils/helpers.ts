import {ContractFactory, ContractTransaction} from 'ethers';
import {
  Interface,
  LogDescription,
  defaultAbiCoder,
  keccak256,
} from 'ethers/lib/utils';
import {existsSync, statSync, readFileSync, writeFileSync} from 'fs';

const deployedContractsFilePath = 'deployed_contracts.json';

export type NetworkNameMapping = {[index: string]: string};
export type ContractList = {[index: string]: {[index: string]: string}};

export const networkNameMapping: NetworkNameMapping = {
  arbitrumOne: 'ERROR: Not available yet.',
  arbitrumGoerli: 'ERROR: Not available yet.',
  mainnet: 'mainnet',
  goerli: 'goerli',
  polygon: 'polygon',
  polygonMumbai: 'mumbai',
  devnet: 'mumbai',
};

export const ERRORS = {
  ALREADY_INITIALIZED: 'Initializable: contract is already initialized',
};

export function getDeployedContracts(): ContractList {
  return JSON.parse(readFileSync(deployedContractsFilePath, 'utf-8'));
}

export function addDeployedContract(
  networkName: string,
  contractName: string,
  contractAddr: string
) {
  let deployedContracts: ContractList;

  // Check if the file exists and is not empty
  if (
    existsSync(deployedContractsFilePath) &&
    statSync(deployedContractsFilePath).size !== 0
  ) {
    deployedContracts = JSON.parse(
      readFileSync(deployedContractsFilePath, 'utf-8')
    );
  } else {
    deployedContracts = {};
  }

  if (!deployedContracts[networkName]) {
    deployedContracts[networkName] = {};
  }

  deployedContracts[networkName][contractName] = contractAddr;

  writeFileSync(
    'deployed_contracts.json',
    JSON.stringify(deployedContracts, null, 2) + '\n'
  );
}