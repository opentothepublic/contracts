// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {ERC1271_SUCCESS} from "@~/library/Structs.sol";
import {InvalidSignatureLength} from "@~/library/Errors.sol";

/**
 * @title SignatureVerifier
 * @dev Library for verifying signatures using ECDSA for EOAs and Smart Contract Accounts.
 */
library SignatureVerifier {
    using ECDSA for bytes32;

    /**
     * @dev Validates a signature against a single signer.
     * @param hash The hash of the signed data.
     * @param signature The signature to validate.
     * @param signer The address of the signer.
     * @return True if the signature is valid, false otherwise.
     */
    function validate_one_signer(bytes32 hash, bytes calldata signature, address signer) public view returns (bool) {
        return verify(hash, signer, signature) == signer;
    }

    /**
     * @dev Validates a signature against one of two possible signers.
     * @param hash The hash of the signed data.
     * @param signature The signature to validate.
     * @param signers The addresses of the possible signers.
     * @return True if the signature is valid and matches one of the signers, false otherwise.
     */
    function validate_one_of_two_signers(bytes32 hash, bytes calldata signature, address[2] memory signers)
        public
        view
        returns (bool)
    {
        require(total(signature) == 1, InvalidSignatureLength());

        address signer0 = verify(hash, signers[0], signature);

        if (signer0 != signers[0]) {
            address signer1 = verify(hash, signers[1], signature);

            return signer1 == signers[1];
        }

        return true;
    }

    /**
     * @dev Validates a signature against one of many possible signers.
     * @param hash The hash of the signed data.
     * @param signature The signature to validate.
     * @param signers The addresses of the possible signers.
     * @return True if the signature is valid and matches one of the signers, false otherwise.
     */
    function validate_one_of_many_signers(bytes32 hash, bytes calldata signature, address[] memory signers)
        public
        view
        returns (bool)
    {
        require(total(signature) == 1, InvalidSignatureLength());

        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == address(0)) continue;
            if (verify(hash, signers[i], signature) == signers[i]) return true;
        }

        return false;
    }

    /**
     * @dev Returns the number of signatures.
     * @param signatures The signatures to count.
     * @return result - The number of signatures.
     */
    function total(bytes calldata signatures) internal pure returns (uint256 result) {
        uint256 len = signatures.length;
        assembly {
            switch len
            case 65 { result := 1 }
            case 130 { result := 2 }
        }
    }

    /**
     * @dev Verifies a signature.
     * @param hash The hash of the signed data.
     * @param signer The address of the signer.
     * @param signature The signature to verify.
     * @return The address that signed the hash or address(0) if verification failed.
     */
    function verify(bytes32 hash, address signer, bytes memory signature) public view returns (address) {
        if (is_contract(signer)) {
            (bool success, bytes memory ret) =
                signer.staticcall(abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature));
            if (success && abi.decode(ret, (bytes4)) == ERC1271_SUCCESS) {
                return signer;
            }
            return address(0);
        }

        return hash.recover(signature);
    }

    /**
     * @dev Checks if an address is a contract.
     * @param account The address to check.
     * @return True if the address is a contract, false otherwise.
     */
    function is_contract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
