// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title Vales de puntos firmados
/// @notice `issuer` firma vales EIP-712; quien recibe uno lo canjea una vez y suma sus puntos.
/// @dev ¿Qué? El mismo contrato se despliega en L1 y en una L2, en la misma dirección.
///   ¿Para qué? Que el emisor firme un vale para una cadena concreta.
///   ¿Impacto? Si el dominio no distingue la cadena, cada vale se cobra una vez en cada una.
contract Vouchers {
    bytes32 private constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant NAME_HASH = keccak256("Vouchers");
    bytes32 private constant VERSION_HASH = keccak256("1");

    /// @notice El tipo del mensaje que firma el emisor.
    bytes32 public constant VOUCHER_TYPEHASH = keccak256("Voucher(address to,uint256 points,uint256 nonce)");

    /// @notice Quien firma los vales.
    address public immutable issuer;

    /// @notice Los puntos de cada cuenta.
    mapping(address account => uint256) public points;
    /// @notice Los vales ya canjeados, por su nonce.
    mapping(uint256 nonce => bool) public redeemed;

    event Redeemed(address indexed to, uint256 points, uint256 nonce);

    error AlreadyRedeemed(uint256 nonce);
    error InvalidSignature();

    // ¿Qué? La cadena en la que se desplegó, guardada al desplegar.
    uint256 private immutable DEPLOY_CHAIN = block.chainid; // <- Paso 1

    constructor(address issuer_) {
        issuer = issuer_;
    }

    // PASO 1: el dominio lleva la cadena en la que se canjea, no la del despliegue.
    /// @notice El separador de dominio EIP-712 de este contrato en esta cadena.
    function domainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_TYPEHASH, NAME_HASH, VERSION_HASH, DEPLOY_CHAIN, address(this))); // <- Paso 1
        //> return keccak256(abi.encode(DOMAIN_TYPEHASH, NAME_HASH, VERSION_HASH, block.chainid, address(this)));
    }

    /// @notice Canjea un vale firmado por `issuer`.
    /// @param to Quien recibe los puntos.
    /// @param amount Los puntos del vale.
    /// @param nonce El número del vale: cada uno se canjea una vez.
    /// @param signature La firma del emisor sobre el vale.
    function redeem(address to, uint256 amount, uint256 nonce, bytes calldata signature) external {
        if (redeemed[nonce]) revert AlreadyRedeemed(nonce);
        bytes32 structHash = keccak256(abi.encode(VOUCHER_TYPEHASH, to, amount, nonce));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator(), structHash));
        if (ECDSA.recover(digest, signature) != issuer) revert InvalidSignature();
        redeemed[nonce] = true;
        points[to] += amount;
        emit Redeemed(to, amount, nonce);
    }
}
