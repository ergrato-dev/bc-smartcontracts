// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Un acertijo que paga 1 ETH a quien envíe la palabra cuyo keccak256 es ANSWER_HASH.
// ¿Para qué? Ser el blanco del front-running. **No lo arregles**: los tests lo necesitan roto.
// ¿Impacto? La respuesta viaja en claro en la transacción: quien la ve en la mempool la copia
//   con más propina y cobra antes.
contract VulnerablePuzzle {
    uint256 public constant REWARD = 1 ether;
    bytes32 public constant ANSWER_HASH = keccak256("rollup");
    bool public solved;

    error WrongAnswer();
    error AlreadySolved();
    error TransferFailed();

    constructor() payable {}

    /// @notice Paga REWARD a quien llama si `answer` es la respuesta.
    function solve(string calldata answer) external {
        if (solved) revert AlreadySolved();
        if (keccak256(bytes(answer)) != ANSWER_HASH) revert WrongAnswer();
        solved = true;
        (bool ok,) = msg.sender.call{value: REWARD}("");
        if (!ok) revert TransferFailed();
    }
}
