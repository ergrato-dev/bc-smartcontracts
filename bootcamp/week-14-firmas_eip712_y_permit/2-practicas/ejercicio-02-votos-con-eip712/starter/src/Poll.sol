// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";

// ¿Qué? Una votación en la que se vota con una firma EIP-712: el votante firma un `Vote` en
//   su wallet, que le muestra cada campo, y otra cuenta (un relayer) lo envía y paga el gas.
// ¿Para qué? Practicar el dominio, el typehash, el hash de un struct con un `string` y los
//   nonces de OpenZeppelin.
// ¿Impacto? Votar no exige tener ETH. A cambio, el contrato comprueba firmante, plazo y
//   nonce, y el votante puede anular un voto firmado que aún no se envió.
contract Poll is EIP712, Nonces {
    uint256 public constant OPTIONS = 3;
    bytes32 public constant VOTE_TYPEHASH =
        keccak256("Vote(address voter,uint256 option,string comment,uint256 nonce,uint256 deadline)");

    mapping(uint256 => uint256) public votesFor;
    mapping(address => bool) public hasVoted;

    event Voted(address indexed voter, uint256 indexed option, string comment);

    error InvalidOption(uint256 option);
    error AlreadyVoted(address voter);
    error ExpiredSignature(uint256 deadline);
    error InvalidSigner(address signer, address voter);

    // ¿Qué? Nombre y versión del dominio EIP-712. La wallet los muestra al firmar.
    // ¿Impacto? Cambiar cualquiera de los dos invalida todas las firmas anteriores.
    constructor() EIP712("Poll", "1") {}

    /// @notice El hash EIP-712 que firma `voter`: dominio de este contrato + struct `Vote`.
    function voteDigest(address voter, uint256 option, string calldata comment, uint256 nonce, uint256 deadline)
        public
        view
        returns (bytes32)
    {
        // PASO 1: el hash del struct y el del mensaje completo. Un `string` entra como su
        //   keccak256, nunca tal cual.
        // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
        revert("TODO: Paso 1");
        //> bytes32 structHash =
        //>     keccak256(abi.encode(VOTE_TYPEHASH, voter, option, keccak256(bytes(comment)), nonce, deadline));
        //> return _hashTypedDataV4(structHash);
    }

    /// @notice Registra el voto firmado por `voter`. Lo envía cualquiera.
    /// @param signature Los 65 bytes `r ‖ s ‖ v` de la firma EIP-712 de `voter`.
    function voteBySig(
        address voter,
        uint256 option,
        string calldata comment,
        uint256 deadline,
        bytes calldata signature
    ) external {
        // PASO 2: plazo, firmante y nonce. `_useNonce` devuelve el nonce actual y lo sube:
        //   la misma firma no vuelve a valer.
        revert("TODO: Paso 2");
        //> if (block.timestamp > deadline) revert ExpiredSignature(deadline);
        //> bytes32 digest = voteDigest(voter, option, comment, _useNonce(voter), deadline);
        //> address signer = ECDSA.recover(digest, signature);
        //> if (signer != voter) revert InvalidSigner(signer, voter);
        //> _vote(voter, option, comment);
    }

    /// @notice Anula la firma pendiente de quien llama, subiendo su nonce.
    function cancelNonce() external {
        // PASO 3: gastar el nonce sin votar.
        revert("TODO: Paso 3");
        //> _useNonce(msg.sender);
    }

    function _vote(address voter, uint256 option, string calldata comment) internal {
        if (option >= OPTIONS) revert InvalidOption(option);
        if (hasVoted[voter]) revert AlreadyVoted(voter);
        hasVoted[voter] = true;
        votesFor[option]++;
        emit Voted(voter, option, comment);
    }
}
