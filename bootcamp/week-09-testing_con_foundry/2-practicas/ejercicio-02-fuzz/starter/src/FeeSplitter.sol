// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Reparte un importe entre una comisión, en puntos básicos (1 bp = 0,01 %), y el resto.
//   También cobra pagos en ETH y le reserva la comisión al dueño.
// ¿Para qué? Es el contrato que vas a probar con fuzzing. Ya está terminado: en este
//   ejercicio solo escribes tests.
// ¿Impacto? Sus reglas valen para cualquier importe y cualquier porcentaje. Tres ejemplos a
//   mano no las cubren; cientos de entradas aleatorias, mucho mejor.
contract FeeSplitter {
    uint256 public constant MAX_BPS = 10_000;

    address public immutable OWNER;
    uint256 public immutable FEE_BPS;
    uint256 public ownerFees;

    error InvalidBps(uint256 bps);
    error ZeroAmount();

    /// @param feeBps Comisión en puntos básicos. Como mucho MAX_BPS (100 %).
    constructor(uint256 feeBps) {
        if (feeBps > MAX_BPS) revert InvalidBps(feeBps);
        OWNER = msg.sender;
        FEE_BPS = feeBps;
    }

    /// @notice Parte `amount` en comisión y resto. La comisión se redondea hacia abajo.
    /// @param amount Importe a repartir.
    /// @param bps Comisión en puntos básicos.
    function split(uint256 amount, uint256 bps) public pure returns (uint256 fee, uint256 rest) {
        if (bps > MAX_BPS) revert InvalidBps(bps);
        fee = amount * bps / MAX_BPS;
        rest = amount - fee;
    }

    /// @notice Cobra un pago: reserva la comisión al dueño y devuelve el resto a quien paga.
    function pay() external payable returns (uint256 rest) {
        if (msg.value == 0) revert ZeroAmount();
        uint256 fee;
        (fee, rest) = split(msg.value, FEE_BPS);
        ownerFees += fee;
        (bool ok,) = msg.sender.call{value: rest}("");
        require(ok);
    }
}
