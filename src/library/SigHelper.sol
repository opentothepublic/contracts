// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {ERC1271_SUCCESS} from "@~/library/Structs.sol";
import {InvalidSignatureLength} from "@~/library/Errors.sol";

library SignatureVerifier {
    using ECDSA for bytes32;

    function validate_one_signer(bytes32 hash, bytes calldata signature, address signer) public view returns (bool) {
        return verify(hash, signer, signature) == signer;
    }

    function validate_one_of_two_signers(bytes32 hash, bytes calldata signature, address[2] memory signers)
        public
        view
        returns (bool)
    {
        if (total(signature) != 1) revert InvalidSignatureLength();

        address signer0 = verify(hash, signers[0], signature);

        if (signer0 != signers[0]) {
            address signer1 = verify(hash, signers[1], signature);

            return signer1 == signers[1];
        }

        return true;
    }

    function validate_one_of_many_signers(bytes32 hash, bytes calldata signature, address[] memory signers)
        public
        view
        returns (bool)
    {
        if (total(signature) != 1) revert InvalidSignatureLength();

        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == address(0)) continue;
            if (verify(hash, signers[i], signature) == signers[i]) return true;
        }

        return false;
    }

    function total(bytes calldata signatures) internal pure returns (uint256 result) {
        uint256 len = signatures.length;
        assembly {
            switch len
            case 65 { result := 1 }
            case 130 { result := 2 }
        }
    }

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

    function is_contract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
