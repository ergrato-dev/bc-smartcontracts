// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IAccount} from "@account-abstraction/contracts/interfaces/IAccount.sol";
import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {PackedUserOperation} from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title Una cuenta de ERC-4337 con un dueño (la del ejercicio 01, resuelta)
/// @notice El EntryPoint le pregunta si una operación es suya (`validateUserOp`) y, si lo es, la
///         ejecuta (`execute`). El dueño firma; la cuenta paga el gas desde su saldo.
contract SimpleWallet is IAccount {
    // ¿Qué? Los dos valores que el EntryPoint entiende como "firma buena" y "firma mala".
    // ¿Impacto? Una firma mala no revierte: devuelve 1, y el EntryPoint rechaza la operación.
    uint256 internal constant SIG_VALIDATION_SUCCESS = 0;
    uint256 internal constant SIG_VALIDATION_FAILED = 1;

    IEntryPoint public immutable entryPoint;
    address public immutable owner;

    error NotEntryPoint(address caller);
    error NotAllowed(address caller);

    constructor(IEntryPoint entryPoint_, address owner_) {
        entryPoint = entryPoint_;
        owner = owner_;
    }

    /// @notice La cuenta recibe ETH para pagar su gas.
    receive() external payable {}

    /// @inheritdoc IAccount
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        returns (uint256 validationData)
    {
        if (msg.sender != address(entryPoint)) revert NotEntryPoint(msg.sender);
        validationData = _validateSignature(userOp.signature, userOpHash);
        _payPrefund(missingAccountFunds);
    }

    /// @notice Hace una llamada en nombre de la cuenta.
    function execute(address target, uint256 value, bytes calldata data) external {
        if (msg.sender != address(entryPoint) && msg.sender != owner) revert NotAllowed(msg.sender);
        (bool ok, bytes memory result) = target.call{value: value}(data);
        if (!ok) {
            // ¿Qué? Devuelve el error de la llamada tal cual, para que el test vea el original.
            assembly ("memory-safe") {
                revert(add(result, 0x20), mload(result))
            }
        }
    }

    // ¿Qué? 0 si `signature` es del dueño sobre `userOpHash`; 1 en cualquier otro caso.
    // ¿Para qué? El EntryPoint distingue "firma mala" (la operación no vale) de "la cuenta falló".
    function _validateSignature(bytes calldata signature, bytes32 userOpHash) internal view returns (uint256) {
        (address signer, ECDSA.RecoverError err,) = ECDSA.tryRecover(userOpHash, signature);
        if (err != ECDSA.RecoverError.NoError || signer != owner) return SIG_VALIDATION_FAILED;
        return SIG_VALIDATION_SUCCESS;
    }

    // ¿Qué? Manda al EntryPoint lo que le falta para cubrir el gas máximo de la operación.
    // ¿Impacto? Si no paga, el EntryPoint rechaza la operación con "AA21 didn't pay prefund".
    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds > 0) {
            (bool ok,) = payable(msg.sender).call{value: missingAccountFunds}("");
            (ok); // si falla, el EntryPoint lo detecta: el depósito no llega
        }
    }
}
