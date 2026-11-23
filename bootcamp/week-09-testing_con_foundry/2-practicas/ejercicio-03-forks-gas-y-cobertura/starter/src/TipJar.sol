// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Un bote de propinas: cualquiera deja ETH con un mensaje y el dueño lo retira.
// ¿Para qué? Es el contrato que vas a medir (cobertura y gas) y a probar sobre una copia de
//   una red en marcha (fork). Ya está terminado: en este ejercicio solo escribes tests.
// ¿Impacto? Que los tests pasen no dice qué líneas ejecutaron ni cuánto gas cuestan; eso
//   lo dicen `forge coverage` y los informes de gas.
contract TipJar {
    address public immutable OWNER;
    uint256 public totalTips;
    mapping(address => uint256) public tipsOf;

    event Tipped(address indexed from, uint256 amount, string message);
    event Withdrawn(address indexed to, uint256 amount);

    error ZeroTip();
    error NotOwner(address caller);
    error NothingToWithdraw();
    error TransferFailed();

    constructor() {
        OWNER = msg.sender;
    }

    /// @notice Deja una propina con un mensaje.
    /// @param message Texto que acompaña a la propina.
    function tip(string calldata message) external payable {
        if (msg.value == 0) revert ZeroTip();
        totalTips += msg.value;
        tipsOf[msg.sender] += msg.value;
        emit Tipped(msg.sender, msg.value, message);
    }

    /// @notice Envía todo el bote al dueño. Solo el dueño.
    function withdraw() external {
        if (msg.sender != OWNER) revert NotOwner(msg.sender);
        uint256 amount = address(this).balance;
        if (amount == 0) revert NothingToWithdraw();
        emit Withdrawn(OWNER, amount);
        (bool ok,) = OWNER.call{value: amount}("");
        if (!ok) revert TransferFailed();
    }
}
