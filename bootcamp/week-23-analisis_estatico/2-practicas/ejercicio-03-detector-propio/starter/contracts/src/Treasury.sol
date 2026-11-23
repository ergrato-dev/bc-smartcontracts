// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// ¿Qué? El contrato sobre el que se prueba el detector: cada función es un caso.
// ¿Impacto? No se despliega. Los nombres dicen qué debería encontrar el detector.
contract Treasury is ReentrancyGuard {
    address public owner = msg.sender;
    mapping(address => uint256) public balanceOf;

    error NotOwner();
    error TransferFailed();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    /// @notice Envía ETH con el guard: no es un hallazgo.
    function guardedWithdraw() external nonReentrant {
        uint256 amount = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        _send(msg.sender, amount);
    }

    /// @notice Envía ETH con `call` sin el guard: hallazgo.
    function unguardedWithdraw() external {
        uint256 amount = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        (bool ok,) = msg.sender.call{value: amount}("");
        if (!ok) revert TransferFailed();
    }

    /// @notice Envía ETH a través de una función interna, sin el guard: hallazgo.
    function unguardedViaInternal() external {
        uint256 amount = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        _send(msg.sender, amount);
    }

    /// @notice Envía ETH con `send`, sin el guard: hallazgo, aunque solo lo llame el dueño.
    function unguardedSend() external onlyOwner {
        bool ok = payable(owner).send(address(this).balance);
        if (!ok) revert TransferFailed();
    }

    /// @notice Envía ETH con `transfer`, sin el guard pero justificado: no es un hallazgo.
    /// `transfer` reenvía solo 2300 de gas, y la cuenta del dueño no puede reentrar con eso.
    // slither-disable-next-line eth-send-without-guard
    function justifiedSweep() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    /// @notice Hace una llamada sin valor: no es un hallazgo.
    function ping(address target) external {
        (bool ok,) = target.call("");
        if (!ok) revert TransferFailed();
    }

    function _send(address to, uint256 amount) internal {
        (bool ok,) = to.call{value: amount}("");
        if (!ok) revert TransferFailed();
    }
}
