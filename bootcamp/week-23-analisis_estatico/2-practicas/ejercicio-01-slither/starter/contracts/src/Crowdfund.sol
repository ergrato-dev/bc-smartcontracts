// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// ¿Qué? Una campaña de financiación: se aportan ETH hasta una fecha. Si se llega al objetivo, el
//   dueño se lleva lo recaudado y cada aportante cobra tokens de recompensa; si no, cada uno
//   recupera lo suyo.
// ¿Impacto? Tiene los fallos que Slither encuentra en el ejercicio. Las líneas que acaban en
//   `// <- Paso N` son las que cambias en ese paso.
contract Crowdfund {
    using SafeERC20 for IERC20;

    /// @notice Tokens de recompensa por cada wei aportado.
    uint256 public constant REWARD_PER_WEI = 100;

    IERC20 public immutable REWARD;
    uint256 public immutable GOAL;
    uint256 public immutable DEADLINE;

    address public owner;
    uint256 public raised;
    mapping(address => uint256) public contributed;
    mapping(address => bool) public rewarded;

    event Contributed(address indexed contributor, uint256 amount);
    event Refunded(address indexed contributor, uint256 amount);
    event OwnerChanged(address indexed newOwner);

    error NotOwner();
    error ZeroAddress();
    error CampaignEnded();
    error CampaignNotEnded();
    error GoalNotReached();
    error GoalAlreadyReached();
    error AlreadyRewarded();
    error TransferFailed();

    constructor(IERC20 reward, uint256 goal, uint256 duration) {
        REWARD = reward;
        GOAL = goal;
        DEADLINE = block.timestamp + duration;
        owner = msg.sender;
    }

    /// @notice Aporta ETH a la campaña mientras no haya terminado.
    function contribute() external payable {
        // Paso 6: el aviso de Slither sobre `block.timestamp` (justifícalo y siléncialo aquí).
        //> // slither-disable-next-line timestamp
        if (block.timestamp >= DEADLINE) revert CampaignEnded();
        contributed[msg.sender] += msg.value;
        raised += msg.value;
        emit Contributed(msg.sender, msg.value);
    }

    /// @notice Si la campaña llegó a su objetivo.
    function goalReached() public view returns (bool) {
        return address(this).balance == GOAL; // <- Paso 3
        //> return raised >= GOAL;
    }

    /// @notice El dueño se lleva lo recaudado si se llegó al objetivo.
    function withdraw() external {
        if (msg.sender != owner) revert NotOwner();
        if (!goalReached()) revert GoalNotReached();
        (bool ok,) = owner.call{value: address(this).balance}("");
        if (!ok) revert TransferFailed();
    }

    /// @notice Cada aportante recupera lo suyo si la campaña terminó sin llegar al objetivo.
    function refund() external {
        // Paso 6: el mismo aviso.
        //> // slither-disable-next-line timestamp
        if (block.timestamp < DEADLINE) revert CampaignNotEnded();
        if (goalReached()) revert GoalAlreadyReached();
        uint256 amount = contributed[msg.sender];
        (bool ok,) = msg.sender.call{value: amount}(""); // <- Paso 1
        if (!ok) revert TransferFailed(); // <- Paso 1
        contributed[msg.sender] = 0;
        emit Refunded(msg.sender, amount);
        //> (bool ok,) = msg.sender.call{value: amount}("");
        //> if (!ok) revert TransferFailed();
    }

    /// @notice Cada aportante cobra su recompensa si se llegó al objetivo.
    function claimReward() external {
        if (!goalReached()) revert GoalNotReached();
        if (rewarded[msg.sender]) revert AlreadyRewarded();
        rewarded[msg.sender] = true;
        REWARD.transfer(msg.sender, contributed[msg.sender] * REWARD_PER_WEI); // <- Paso 2
        //> REWARD.safeTransfer(msg.sender, contributed[msg.sender] * REWARD_PER_WEI);
    }

    /// @notice El dueño cede la campaña a otra cuenta.
    function setOwner(address newOwner) external {
        if (tx.origin != owner) revert NotOwner(); // <- Paso 4
        //> if (msg.sender != owner) revert NotOwner();
        // Paso 5: la dirección cero.
        //> if (newOwner == address(0)) revert ZeroAddress();
        owner = newOwner;
        emit OwnerChanged(newOwner);
    }
}
