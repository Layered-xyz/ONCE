// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {MessageHashUtils} from "./MessageHashUtils.sol";

/**
 * @title EIP712Lib
 * @dev Library for managing EIP712 domain data and hashing typed data according to EIP712 specifications.
 */
library EIP712Lib {
    /**
     * @dev Represents the EIP712 domain data structure.
     */
    struct EIP712Domain {
        bytes32 cachedDomainSeparator; // Cached domain separator hash
        uint256 cachedChainId; // Cached chain ID
        address cachedThis; // Cached contract address
        bytes32 hashedName; // Hash of the domain name
        bytes32 hashedVersion; // Hash of the domain version
        string name; // Name of the domain
        string version; // Version of the domain
    }

    // Keccak256 hash of the EIP712Domain data structure
    bytes32 private constant TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /**
     * @dev Initializes the EIP712 domain with the provided name and version.
     * @param domain The EIP712 domain data structure to initialize.
     * @param name The name of the domain.
     * @param version The version of the domain.
     * @param verifyingContract The address of the contract using this library.
     */
    function initialize(EIP712Domain storage domain, string memory name, string memory version, address verifyingContract) internal {
        domain.name = name;
        domain.version = version;
        domain.hashedName = keccak256(bytes(name));
        domain.hashedVersion = keccak256(bytes(version));

        domain.cachedChainId = block.chainid;
        domain.cachedDomainSeparator = _buildDomainSeparator(domain, verifyingContract);
        domain.cachedThis = verifyingContract;
    }

    /**
     * @dev Retrieves the cached or recalculated domain separator hash for EIP712 data hashing.
     * @param domain The EIP712 domain data structure.
     * @param verifyingContract The address of the contract using this library.
     * @return The domain separator hash.
     */
    function _domainSeparatorV4(EIP712Domain storage domain, address verifyingContract) internal view returns (bytes32) {
        if (verifyingContract == domain.cachedThis && block.chainid == domain.cachedChainId) {
            return domain.cachedDomainSeparator;
        } else {
            return _buildDomainSeparator(domain, verifyingContract);
        }
    }

    /**
     * @dev Builds the domain separator hash for EIP712 data hashing.
     * @param domain The EIP712 domain data structure.
     * @param verifyingContract The address of the contract using this library.
     * @return The domain separator hash.
     */
    function _buildDomainSeparator(EIP712Domain storage domain, address verifyingContract) private view returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, domain.hashedName, domain.hashedVersion, block.chainid, verifyingContract));
    }

    /**
     * @dev Hashes the provided structured data according to EIP712 specifications.
     * @param domain The EIP712 domain data structure.
     * @param structHash The hash of the structured data.
     * @param verifyingContract The address of the contract using this library.
     * @return The EIP712 typed data hash.
     */
    function _hashTypedDataV4(EIP712Domain storage domain, bytes32 structHash, address verifyingContract) internal view returns (bytes32) {
        return MessageHashUtils.toTypedDataHash(_domainSeparatorV4(domain, verifyingContract), structHash);
    }

    /**
     * @dev Retrieves the EIP712 domain data for use in cryptographic operations.
     * @param domain The EIP712 domain data structure.
     * @param verifyingContract The address of the contract using this library.
     * @return fields The field selector indicating which fields are included in the returned data.
     * @return name The name of the domain.
     * @return version The version of the domain.
     * @return chainId The chain ID.
     * @return verifyingContract_ The address of the verifying contract.
     * @return salt The salt value (always 0 in this implementation).
     * @return extensions The array of extension values (always empty in this implementation).
     */
    function eip712Domain(
        EIP712Domain storage domain,
        address verifyingContract
    )
        internal
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract_,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return (
            hex"0f", // Field selector indicating all fields are present
            domain.name,
            domain.version,
            block.chainid,
            verifyingContract,
            bytes32(0), // Salt value is always 0
            new uint256[](0) // Empty array of extensions
        );
    }
}