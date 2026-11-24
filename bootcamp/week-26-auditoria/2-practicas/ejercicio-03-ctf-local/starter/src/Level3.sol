// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/// @title Nivel 3 — Vales firmados
/// @notice ¿Qué? Un repartidor de ETH: quien tiene un vale firmado por `SIGNER` cobra lo que dice
///   el vale. El repartidor firma fuera de la cadena y entrega cada vale a su destinatario.
contract Vouchers {
    address public immutable SIGNER;

    error BadSignature();
    error TransferFailed();

    constructor(address signer) payable {
        SIGNER = signer;
    }

    /// @notice Cobra el vale `(to, amount)` firmado con EIP-191.
    function claim(address to, uint256 amount, bytes calldata signature) external {
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(keccak256(abi.encode(to, amount)));
        if (ECDSA.recover(digest, signature) != SIGNER) revert BadSignature();
        (bool ok,) = to.call{value: amount}("");
        if (!ok) revert TransferFailed();
    }
}

/// @notice ¿Qué? Despliega el nivel: un repartidor con 10 ETH.
contract Level3Setup {
    Vouchers public immutable VOUCHERS;

    constructor(address signer) payable {
        VOUCHERS = new Vouchers{value: msg.value}(signer);
    }

    function isSolved() external view returns (bool) {
        return address(VOUCHERS).balance == 0;
    }
}
