// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@~/library/Structs.sol";
import "@~/library/SigHelper.sol";

contract EIP1271 is EIP712 {
  using SignatureVerifier for bytes32;

  constructor() EIP712("OTTP Signature Verifier", "1") {}

  // fnsig -> baca03f5
  function isValidSignature(
    bytes32 _hash,
    PublicKey memory _publickey,
    bytes calldata _signature
  ) external view returns (bytes4 magicValue) {
    if (_publickey.sigVerifier == address(0)) return SIG_VERIFICATION_FAILED;

    if (_publickey.sigVerifier == address(this)) {
      return
        _verify(_hashTypedDataV4(_hash), _publickey, _signature)
          ? MAGICVALUE
          : SIG_VERIFICATION_FAILED;
    }

    return
      _delegateVerify(_hashTypedDataV4(_hash), _publickey, _signature)
        ? MAGICVALUE
        : SIG_VERIFICATION_FAILED;
  }

  // todo: 1 isValidSudoSignature -> singular.
  // with typehash
  //
  // hashTypedData:encode
  // typehash | oid | sudo | nonce | deadline

  // todo: 2 isValidRecoverySignature -> one of two
  // with typehash
  //
  // hashTypedData:encode
  // typehash | oid | recovery1 | recovery2 | to | nonce | deadline

  // todo: 3 isValidSudoOrRecoverySignature -> one of three
  // with typehash
  //
  // hashTypedData:encode
  // typehash | oid | sudo | recovery1 | recovery2 | to | nonce | deadline

  function _verify(
    bytes32 _hash,
    PublicKey memory _publickey,
    bytes calldata _signature
  ) internal view returns (bool) {
    if (_publickey.format == PublicKeyFormat.DEFAULT) {
      address signer = address(bytes20(_publickey.key));
      return _hash.validateOneSignature(_signature, signer);
    } else if (_publickey.format == PublicKeyFormat.SMART_ACCOUNT) {
      return _smartAccountVerify(_hash, _publickey, _signature);
    }
    return false;
  }

  function _smartAccountVerify(
    bytes32 _hash,
    PublicKey memory _publickey,
    bytes calldata _signature
  ) internal view returns (bool) {
    // in case of smart accounts, it is possible to delegate to the account to verify for us.
    // this requires the account to conform to eip1271.
    // why? the owner of an ottp id might be a smart accout, and unlike regular eoa,
    // we may not be able to access the underlying signer.
    (bool success, bytes memory ret) = _publickey.sigVerifier.staticcall(
      abi.encodeWithSelector(IERC1271.isValidSignature.selector, _hash, _signature)
    );
    if (success) {
      return abi.decode(ret, (bytes4)) == 0x1626ba7e;
    }

    return false;
  }

  function _delegateVerify(
    bytes32 _hash,
    PublicKey memory _publickey,
    bytes calldata _signature
  ) internal view returns (bool) {
    (bool success, bytes memory ret) = _publickey.sigVerifier.staticcall(
      abi.encodeWithSelector(
        _publickey.verifyFnSelector,
        abi.encode(_hash, _publickey.key, _signature)
      )
    );

    if (success) {
      return abi.decode(ret, (bytes4)) == _publickey.verifyFnSelector;
    }

    return false;
  }
}
