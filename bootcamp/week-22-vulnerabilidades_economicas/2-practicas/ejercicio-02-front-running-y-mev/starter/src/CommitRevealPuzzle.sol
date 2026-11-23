// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? El mismo acertijo en dos fases. Primero envías un compromiso (commit): el hash de tu
//   dirección, tu respuesta y un secreto (salt). En un bloque posterior la revelas (reveal).
// ¿Para qué? Que copiar tu transacción no sirva: el compromiso lleva tu dirección dentro, y
//   cuando la respuesta se ve en la revelación, ya es tarde para comprometerse.
// ¿Impacto? Cuesta dos transacciones y un bloque de espera en vez de una.
contract CommitRevealPuzzle {
    uint256 public constant REWARD = 1 ether;
    bytes32 public constant ANSWER_HASH = keccak256("rollup");
    bool public solved;
    mapping(address => bytes32) public commitmentOf;
    mapping(address => uint256) public committedAt;

    error WrongAnswer();
    error AlreadySolved();
    error TransferFailed();
    error WrongCommitment();
    error RevealTooEarly();

    constructor() payable {}

    /// @notice El compromiso que `solver` debe enviar para revelar `answer` con `salt`.
    function hashCommitment(address solver, string calldata answer, bytes32 salt) public pure returns (bytes32) {
        return keccak256(abi.encode(solver, answer, salt));
    }

    /// @notice Guarda tu compromiso y el bloque en que llega. Puedes cambiarlo antes de revelar.
    // PASO 4: guardar el compromiso.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function commit(bytes32 commitment) external {
        revert("TODO: Paso 4");
        //> commitmentOf[msg.sender] = commitment;
        //> committedAt[msg.sender] = block.number;
    }

    /// @notice Paga REWARD si revelas lo que comprometiste en un bloque anterior y es la respuesta.
    // PASO 5: revelar.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function reveal(string calldata answer, bytes32 salt) external {
        revert("TODO: Paso 5");
        //> if (solved) revert AlreadySolved();
        //> if (commitmentOf[msg.sender] != hashCommitment(msg.sender, answer, salt)) revert WrongCommitment();
        //> if (block.number <= committedAt[msg.sender]) revert RevealTooEarly();
        //> if (keccak256(bytes(answer)) != ANSWER_HASH) revert WrongAnswer();
        //> solved = true;
        //> (bool ok,) = msg.sender.call{value: REWARD}("");
        //> if (!ok) revert TransferFailed();
    }
}
