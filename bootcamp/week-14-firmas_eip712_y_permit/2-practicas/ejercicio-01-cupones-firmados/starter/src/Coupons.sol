// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

// ¿Qué? Cupones de puntos firmados fuera de la cadena: el emisor firma "da `amount` puntos a
//   `to`" con su clave, y cualquiera presenta el cupón al contrato.
// ¿Para qué? Practicar EIP-191 en Solidity: rehacer el hash firmado, recuperar el firmante
//   con ECDSA y no aceptar dos veces la misma firma.
// ¿Impacto? El emisor no paga gas por cada cupón: firma gratis y quien canjea paga la
//   transacción. A cambio, el contrato tiene que impedir el replay por su cuenta.
contract Coupons {
    address public immutable ISSUER;

    mapping(address => uint256) public points;
    mapping(bytes32 => bool) public used;

    event Redeemed(bytes32 indexed hash, address indexed to, uint256 amount);

    error InvalidSigner(address signer);
    error CouponUsed(bytes32 hash);

    /// @param issuer La cuenta cuya firma vale como cupón.
    constructor(address issuer) {
        ISSUER = issuer;
    }

    /// @notice El hash que firma el emisor para el cupón `id`.
    /// @dev Incluye este contrato y la red: un cupón no sirve en otro despliegue ni en otra red.
    function couponHash(address to, uint256 amount, uint256 id) public view returns (bytes32) {
        // PASO 1: el hash del cupón. `abi.encode` (no `encodePacked`) da a cada campo 32 bytes.
        // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
        revert("TODO: Paso 1");
        //> return keccak256(abi.encode(address(this), block.chainid, to, amount, id));
    }

    /// @notice Canjea un cupón. Lo puede presentar cualquiera: los puntos van a `to`.
    /// @param signature Los 65 bytes `r ‖ s ‖ v` de la firma del emisor.
    function redeem(address to, uint256 amount, uint256 id, bytes calldata signature) external {
        bytes32 hash = couponHash(to, amount, id);
        // PASO 3: un cupón se canjea una sola vez.
        //> if (used[hash]) revert CouponUsed(hash);
        //> used[hash] = true;

        // PASO 2: el emisor firmó con el prefijo EIP-191. Se rehace ese hash, se recupera
        //   quién firmó y se compara con ISSUER.
        revert("TODO: Paso 2");
        //> address signer = ECDSA.recover(MessageHashUtils.toEthSignedMessageHash(hash), signature);
        //> if (signer != ISSUER) revert InvalidSigner(signer);
        //> points[to] += amount;
        //> emit Redeemed(hash, to, amount);
    }
}
