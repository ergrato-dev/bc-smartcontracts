// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Una hucha con candado de tiempo: cada cuenta deposita ETH y solo puede sacarlo
//   cuando pasan LOCK_PERIOD segundos desde su último depósito.
// ¿Para qué? Es el contrato que vas a probar. Ya está terminado: en este ejercicio solo
//   escribes tests.
// ¿Impacto? Sus reglas dependen de quién llama, de cuánto ETH envía y de la hora del bloque.
//   Para probarlas hace falta controlar las tres cosas desde el test: eso son los cheatcodes.
contract TimeVault {
    uint256 public constant LOCK_PERIOD = 7 days;

    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public unlockAt;

    event Deposited(address indexed account, uint256 amount, uint256 unlockAt);
    event Withdrawn(address indexed account, uint256 amount);

    error ZeroAmount();
    error StillLocked(uint256 unlockAt);
    error NothingToWithdraw();
    error TransferFailed();

    /// @notice Guarda el ETH enviado y vuelve a cerrar el candado de quien deposita.
    function deposit() external payable {
        if (msg.value == 0) revert ZeroAmount();
        balanceOf[msg.sender] += msg.value;
        uint256 until = block.timestamp + LOCK_PERIOD;
        unlockAt[msg.sender] = until;
        emit Deposited(msg.sender, msg.value, until);
    }

    /// @notice Devuelve todo el saldo de quien llama, si su candado ya se abrió.
    function withdraw() external {
        uint256 amount = balanceOf[msg.sender];
        if (amount == 0) revert NothingToWithdraw();
        if (block.timestamp < unlockAt[msg.sender]) revert StillLocked(unlockAt[msg.sender]);
        balanceOf[msg.sender] = 0;
        emit Withdrawn(msg.sender, amount);
        (bool ok,) = msg.sender.call{value: amount}("");
        if (!ok) revert TransferFailed();
    }
}
