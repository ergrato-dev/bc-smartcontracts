// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/// @title Código para una EOA con EIP-7702
/// @notice Una EOA delega en este contrato y gana dos cosas: varias llamadas en una transacción
///         (`execute`) y operaciones firmadas que envía y paga otro (`executeWithSignature`).
/// @dev Se ejecuta en la EOA: `address(this)` es la EOA, y el storage es el de la EOA.
contract BatchDelegate {
    struct Call {
        address target;
        uint256 value;
        bytes data;
    }

    /// @custom:storage-location erc7201:bootcamp.BatchDelegate
    struct DelegateStorage {
        uint256 nonce;
    }

    // PASO 4: el slot de ERC-7201 para "bootcamp.BatchDelegate":
    //   keccak256(abi.encode(uint256(keccak256("bootcamp.BatchDelegate")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant STORAGE_SLOT = 0; // <- Paso 4
    //> bytes32 private constant STORAGE_SLOT = 0xb65fc48599bdae15717ba796c47e752ea9327f57b6be417b75729fa3a8ce2900;

    error Unauthorized(address caller);
    error BadSignature();
    error Expired(uint256 deadline);

    /// @notice Recibir ETH, como cualquier EOA.
    receive() external payable {}

    /// @notice Hace varias llamadas, en orden. Solo la propia EOA, en una transacción suya.
    function execute(Call[] calldata calls) external payable {
        // PASO 2: solo la EOA. Con EIP-7702, `msg.sender == address(this)` es "la EOA se llama a sí misma".
        //> if (msg.sender != address(this)) revert Unauthorized(msg.sender);
        _executeBatch(calls);
    }

    /// @notice Las mismas llamadas, firmadas por la EOA y enviadas por cualquiera (que paga el gas).
    function executeWithSignature(Call[] calldata calls, uint256 deadline, bytes calldata signature) external payable {
        revert("TODO: Paso 3");
        //> if (block.timestamp > deadline) revert Expired(deadline);
        //> DelegateStorage storage $ = _storage();
        //> bytes32 digest = MessageHashUtils.toEthSignedMessageHash(
        //>     keccak256(abi.encode(block.chainid, address(this), $.nonce, deadline, calls))
        //> );
        //> (address signer, ECDSA.RecoverError err,) = ECDSA.tryRecover(digest, signature);
        //> if (err != ECDSA.RecoverError.NoError || signer != address(this)) revert BadSignature();
        //> $.nonce++;
        //> _executeBatch(calls);
    }

    /// @notice El nonce de las operaciones firmadas.
    function nonce() external view returns (uint256) {
        return _storage().nonce;
    }

    // PASO 1: cada llamada con su valor; si una falla, revierte todo con el error original.
    function _executeBatch(Call[] calldata calls) internal {
        revert("TODO: Paso 1");
        //> for (uint256 i; i < calls.length; i++) {
        //>     (bool ok, bytes memory result) = calls[i].target.call{value: calls[i].value}(calls[i].data);
        //>     if (!ok) {
        //>         assembly ("memory-safe") {
        //>             revert(add(result, 0x20), mload(result))
        //>         }
        //>     }
        //> }
    }

    function _storage() private pure returns (DelegateStorage storage $) {
        assembly ("memory-safe") {
            $.slot := STORAGE_SLOT
        }
    }
}
