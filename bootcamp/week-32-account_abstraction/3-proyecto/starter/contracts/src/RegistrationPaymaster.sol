// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {BasePaymaster} from "@account-abstraction/contracts/core/BasePaymaster.sol";
import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {PackedUserOperation} from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {ERC7821} from "@openzeppelin/contracts/account/extensions/draft-ERC7821.sol";
import {Execution} from "@openzeppelin/contracts/account/utils/draft-ERC7579Utils.sol";
import {Registry} from "./Registry.sol";
import {LoyaltyToken} from "./LoyaltyToken.sol";

/// @title El paymaster de las altas con puntos
/// @notice Paga el gas de una sola operación por cuenta: un `registerWithPermit` en el registro,
///         desde una cuenta que ya tiene los puntos. Quien se registra no necesita ETH.
/// @dev El gas sale de su depósito en el EntryPoint. Su dueño (la DAO, tras el traspaso) es el
///      único que lo retira.
contract RegistrationPaymaster is BasePaymaster {
    /// @notice El gas máximo que acepta pagar en una operación, en wei.
    uint256 public constant MAX_COST = 0.005 ether;
    // ¿Qué? El modo de ERC-7821 de un lote simple: tipo 0x01 (lote), ejecución 0x00 (revierte si
    //   una llamada falla), sin selector ni datos.
    bytes32 internal constant BATCH_MODE = bytes32(uint256(0x01) << 248);

    Registry public immutable registry;
    LoyaltyToken public immutable loyalty;
    // ¿Qué? Los puntos de un alta, copiados del registro al desplegar.
    // ¿Para qué? Que la validación no llame al registro: los bundlers limitan lo que la validación
    //   lee (ERC-7562), y el registro es un proxy con su propio storage.
    uint256 public immutable pointsPrice;

    /// @notice Si la cuenta ya usó su alta patrocinada.
    mapping(address account => bool) public sponsored;

    error NotSponsored();
    error AlreadySponsored(address account);
    error NotEnoughPoints(address account);
    error TooExpensive(uint256 maxCost);

    constructor(IEntryPoint entryPoint_, Registry registry_) BasePaymaster(entryPoint_) {
        registry = registry_;
        loyalty = registry_.loyalty();
        pointsPrice = registry_.POINTS_PRICE();
    }

    // ¿Qué? Las cuatro reglas, en la validación: lo que se llama, lo que cuesta, si la cuenta ya
    //   usó su alta y si tiene los puntos. Revertir es decir que no paga.
    // ¿Impacto? Escribe `sponsored` aquí y no en postOp: si la llamada falla, el alta patrocinada
    //   se gastó igual, porque el gas también se pagó.
    function _validatePaymasterUserOp(PackedUserOperation calldata userOp, bytes32, uint256 maxCost)
        internal
        override
        returns (bytes memory context, uint256 validationData)
    {
        // TODO (semana 32): las cuatro reglas, en este orden: `_checkCall`, el tope `MAX_COST`, el
        //   cupo de una alta por cuenta (`sponsored`) y los puntos (`pointsPrice`). Apunta el cupo
        //   aquí, no en postOp.
        (userOp, maxCost);
        return ("", 0);
    }

    // ¿Qué? Solo `execute(BATCH_MODE, [registry.registerWithPermit(...)])`: una llamada, sin ETH.
    // ¿Para qué? Que el depósito no pague transferencias, swaps ni nada que no sea un alta.
    function _checkCall(bytes calldata callData) internal view {
        // TODO (semana 32): decodifica `execute(mode, executionData)` de ERC-7821 y comprueba que
        //   el modo es BATCH_MODE y que hay una sola llamada: al registro, sin ETH, a registerWithPermit.
        (callData);
    }
}
