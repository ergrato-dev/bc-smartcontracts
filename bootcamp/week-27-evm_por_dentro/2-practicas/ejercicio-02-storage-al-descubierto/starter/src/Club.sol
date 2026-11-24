// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Un club con cuotas: socios con puntos, saldos, nonces usados y un historial de pagos.
// ¿Para qué? Tener en un solo contrato cada forma de guardar datos en storage: variables
//   empaquetadas, mappings, mappings anidados, un array dinámico, un string y structs.
// ¿Impacto? `secret` es `private`, pero eso solo quita el getter: el valor está en un slot que
//   cualquiera lee con `cast storage`. Nada secreto va nunca en storage.
contract Club {
    struct Member {
        address account;
        uint96 points;
        uint256 since;
    }

    uint128 public totalPaid;
    uint64 public lastPayment;
    bool public open;
    address public owner;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(uint256 => bool)) public usedNonce;
    uint256[] public payments;
    string public name;
    mapping(uint256 => Member) public members;
    bytes32 private secret;

    error Closed();

    constructor(string memory clubName, bytes32 clubSecret) {
        owner = msg.sender;
        open = true;
        name = clubName;
        secret = clubSecret;
    }

    /// @notice Paga una cuota. `nonce` no se puede repetir.
    function pay(uint256 nonce) external payable {
        if (!open || usedNonce[msg.sender][nonce]) revert Closed();
        usedNonce[msg.sender][nonce] = true;
        balanceOf[msg.sender] += msg.value;
        totalPaid += uint128(msg.value);
        lastPayment = uint64(block.timestamp);
        payments.push(msg.value);
    }

    /// @notice Da de alta al socio `id` con sus puntos.
    function join(uint256 id, uint96 points) external {
        members[id] = Member({account: msg.sender, points: points, since: block.timestamp});
    }

    /// @notice Cambia el nombre del club.
    function rename(string calldata newName) external {
        name = newName;
    }
}
