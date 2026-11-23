// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

// ¿Qué? Staking: dejas tokens y cobras ETH en proporción a cuántos dejas y durante cuánto
//   tiempo, un 10 % anual (1 token rinde 0,1 ETH al año). Cualquiera aporta el ETH de las
//   recompensas enviándolo al contrato.
// ¿Impacto? Tiene los fallos del ejercicio. Las líneas que acaban en `// <- Paso N` son las que
//   cambias en ese paso.
contract Staking {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    uint256 public constant RATE_BPS = 1000;
    uint256 public constant BPS = 10_000;
    uint256 public constant YEAR = 365 days;

    /// @notice Lo que tiene cada cuenta en staking, en un solo slot de storage.
    struct Position {
        uint96 amount;
        uint64 since;
    }

    IERC20 public immutable TOKEN;
    mapping(address => Position) public positions;

    error AlreadyStaking();
    error NothingStaked();
    error TransferFailed();

    constructor(IERC20 token) {
        TOKEN = token;
    }

    /// @notice El ETH de las recompensas.
    receive() external payable {}

    /// @notice Deja `amount` tokens en staking. Una posición por cuenta.
    function stake(uint256 amount) external {
        if (positions[msg.sender].amount != 0) revert AlreadyStaking();
        positions[msg.sender] = Position(uint96(amount), uint64(block.timestamp)); // <- Paso 3
        //> positions[msg.sender] = Position(amount.toUint96(), block.timestamp.toUint64());
        TOKEN.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @notice El ETH que ha generado la posición de `account` desde su último cobro.
    function earned(address account) public view returns (uint256) {
        Position memory position = positions[account];
        uint256 elapsed = block.timestamp - position.since;
        return elapsed / YEAR * position.amount * RATE_BPS / BPS; // <- Paso 2
        //> return elapsed * position.amount * RATE_BPS / (YEAR * BPS);
    }

    /// @notice Cobra el ETH generado.
    function claim() external {
        uint256 reward = earned(msg.sender);
        positions[msg.sender].since = uint64(block.timestamp); // <- Paso 3
        //> positions[msg.sender].since = block.timestamp.toUint64();
        _sendReward(reward);
    }

    /// @notice Recupera los tokens y cierra la posición.
    function unstake() external {
        uint256 amount = positions[msg.sender].amount;
        if (amount == 0) revert NothingStaked();
        // Paso 4: lo que ninguna herramienta ve.
        //> uint256 reward = earned(msg.sender);
        delete positions[msg.sender];
        TOKEN.safeTransfer(msg.sender, amount);
        //> _sendReward(reward);
    }

    function _sendReward(uint256 reward) private {
        payable(msg.sender).call{value: reward}(""); // <- Paso 1
        //> (bool ok,) = payable(msg.sender).call{value: reward}("");
        //> if (!ok) revert TransferFailed();
    }
}
