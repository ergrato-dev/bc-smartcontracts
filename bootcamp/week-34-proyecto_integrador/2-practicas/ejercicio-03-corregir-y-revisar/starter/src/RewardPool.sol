// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title Un pool que reparte recompensas entre quienes depositan
/// @notice Escrito por otra aprendiz para su protocolo: depositas `stakingToken` y ganas
///         `rewardToken` cada segundo, a `rewardRate` repartido entre todo lo depositado. El
///         dueño llena el pool de recompensas y fija el ritmo.
/// @dev ¿Qué? El modelo de recompensas acumuladas por unidad depositada (`rewardPerTokenStored`):
///   cada cuenta guarda cuánto valía al tocarla por última vez (`userRewardPerTokenPaid`) y lo
///   ganado hasta entonces (`rewards`).
///   ¿Impacto? Es el código del ejercicio 02 con tus cuatro correcciones: cada una cierra un
///   hallazgo y la prueba su test de regresión.
contract RewardPool is Ownable {
    using SafeERC20 for IERC20;

    /// @notice La escala de `rewardPerTokenStored`: 18 decimales más que el token.
    uint256 public constant PRECISION = 1e18;

    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;

    /// @notice Recompensas por segundo, repartidas entre todo lo depositado.
    uint256 public rewardRate;
    uint256 public lastUpdate;
    uint256 public rewardPerTokenStored;
    uint256 public totalStaked;

    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event Staked(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);
    event Claimed(address indexed account, uint256 reward);
    event RewardRateSet(uint256 rate);

    constructor(IERC20 stakingToken_, IERC20 rewardToken_) Ownable(msg.sender) {
        stakingToken = stakingToken_;
        rewardToken = rewardToken_;
        lastUpdate = block.timestamp;
    }

    /// @notice Las recompensas acumuladas por unidad depositada hasta ahora.
    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) return rewardPerTokenStored;
        // PASO 3: escalar antes de dividir, y deshacer la escala al multiplicar por el saldo.
        // Borra las dos líneas que acaban en `// <- Paso 3` y descomenta las de `//> `.
        return rewardPerTokenStored + rewardRate * (block.timestamp - lastUpdate) / totalStaked; // <- Paso 3
        //> return rewardPerTokenStored + rewardRate * (block.timestamp - lastUpdate) * PRECISION / totalStaked;
    }

    /// @notice Lo que `account` puede cobrar ahora.
    function earned(address account) public view returns (uint256) {
        // PASO 3
        return rewards[account] + balanceOf[account] * (rewardPerToken() - userRewardPerTokenPaid[account]); // <- Paso 3
        //> return rewards[account] + balanceOf[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / PRECISION;
    }

    /// @notice Deposita `amount` de `stakingToken`.
    function stake(uint256 amount) external {
        // PASO 2: apuntar lo ganado hasta ahora antes de cambiar el saldo, como withdraw y claim.
        // Descomenta la línea de `//> `.
        //> _update(msg.sender);
        totalStaked += amount;
        balanceOf[msg.sender] += amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    /// @notice Retira `amount` de lo depositado.
    function withdraw(uint256 amount) external {
        _update(msg.sender);
        totalStaked -= amount;
        balanceOf[msg.sender] -= amount;
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    /// @notice Cobra todo lo ganado.
    function claim() external {
        _update(msg.sender);
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        rewardToken.safeTransfer(msg.sender, reward);
        emit Claimed(msg.sender, reward);
    }

    // PASO 1: solo el dueño. Borra la línea que acaba en `// <- Paso 1` y descomenta la de `//> `.
    /// @notice Fija las recompensas por segundo. Solo el dueño.
    function setRewardRate(uint256 rate) external { // <- Paso 1
    //> function setRewardRate(uint256 rate) external onlyOwner {
        // PASO 4: cerrar lo acumulado hasta ahora al ritmo de antes. Descomenta la línea de `//> `.
        //> _updateGlobal();
        rewardRate = rate;
        emit RewardRateSet(rate);
    }

    function _updateGlobal() internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdate = block.timestamp;
    }

    function _update(address account) internal {
        _updateGlobal();
        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
}
