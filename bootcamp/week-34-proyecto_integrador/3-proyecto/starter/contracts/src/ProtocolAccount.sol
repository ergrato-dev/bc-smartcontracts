// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Account} from "@openzeppelin/contracts/account/Account.sol";
import {ERC7821} from "@openzeppelin/contracts/account/extensions/draft-ERC7821.sol";
import {SignerEIP7702} from "@openzeppelin/contracts/utils/cryptography/signers/SignerEIP7702.sol";
import {IEntryPoint} from "@openzeppelin/contracts/interfaces/IERC4337.sol";

/// @title El código de las cuentas del protocolo (EIP-7702)
/// @notice Una EOA delega en este contrato y pasa a ser una cuenta de ERC-4337: el EntryPoint
///         valida sus operaciones con la firma de la propia EOA y las ejecuta en lote (ERC-7821).
/// @dev Se ejecuta en la EOA: no tiene storage propio ni dueño; el dueño es la clave de la EOA.
contract ProtocolAccount is Account, SignerEIP7702, ERC7821 {
    // ¿Qué? El EntryPoint que acepta, fijo en el código.
    // ¿Para qué? OpenZeppelin 5.7 usa por defecto el de la v0.9; el protocolo usa la v0.8.0, la
    //   de la imagen. Como es `immutable`, va en el código: cada EOA que delega lo hereda.
    IEntryPoint private immutable _entryPoint;

    constructor(IEntryPoint entryPoint_) {
        _entryPoint = entryPoint_;
    }

    /// @inheritdoc Account
    function entryPoint() public view override returns (IEntryPoint) {
        return _entryPoint;
    }

    // ¿Qué? Quién puede llamar a `execute`: la propia EOA (por defecto en ERC7821) y el EntryPoint,
    //   que solo llama después de validar la firma.
    function _erc7821AuthorizedExecutor(address caller, bytes32 mode, bytes calldata executionData)
        internal
        view
        override
        returns (bool)
    {
        return caller == address(entryPoint()) || super._erc7821AuthorizedExecutor(caller, mode, executionData);
    }
}
