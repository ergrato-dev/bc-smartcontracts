// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

/// @title Crowdfund
/// @notice ¿Qué? Campañas de financiación con meta y plazo. Si al acabar el plazo la campaña llegó
///   a su meta, el creador cobra lo recaudado menos la comisión de la plataforma; si no llegó,
///   cualquiera llama a `refundAll` y cada aportante recupera lo suyo.
/// @dev ¿Para qué? Es el contrato que auditas en el ejercicio 02. Tiene fallos a propósito.
///   **No lo corrijas**: el trabajo del auditor es encontrarlos, probarlos y explicarlos.
contract Crowdfund {
    struct Campaign {
        address creator;
        uint256 goal;
        uint256 raised;
        uint64 deadline;
        bool closed;
    }

    /// @notice Comisión de la plataforma, en puntos básicos: 250 = 2,5 %.
    uint256 public constant FEE_BPS = 250;
    address public immutable PLATFORM;
    uint256 public nextId;
    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public contributions;
    mapping(uint256 => address[]) internal contributors;

    event Created(uint256 indexed id, address indexed creator, uint256 goal, uint64 deadline);
    event Contributed(uint256 indexed id, address indexed from, uint256 amount);
    event Claimed(uint256 indexed id, uint256 amount, uint256 fee);
    event Refunded(uint256 indexed id);

    error InvalidCampaign();
    error NotCreator();
    error Ended();
    error NotEnded();
    error GoalNotReached();
    error GoalReached();
    error Closed();
    error TransferFailed();

    constructor(address platform) {
        PLATFORM = platform;
    }

    /// @notice Crea una campaña con meta `goal` (en wei) que acepta aportes hasta `deadline`.
    function create(uint256 goal, uint64 deadline) external returns (uint256 id) {
        if (goal == 0 || deadline <= block.timestamp) revert InvalidCampaign();
        id = nextId++;
        campaigns[id] = Campaign(msg.sender, goal, 0, deadline, false);
        emit Created(id, msg.sender, goal, deadline);
    }

    /// @notice Aporta el ETH enviado a la campaña `id`, hasta su plazo incluido.
    function contribute(uint256 id) external payable {
        Campaign storage c = campaigns[id];
        if (c.creator == address(0) || msg.value == 0) revert InvalidCampaign();
        if (block.timestamp > c.deadline) revert Ended();
        if (contributions[id][msg.sender] == 0) contributors[id].push(msg.sender);
        contributions[id][msg.sender] += msg.value;
        c.raised += msg.value;
        emit Contributed(id, msg.sender, msg.value);
    }

    /// @notice El creador cobra una campaña que llegó a su meta, desde el final del plazo.
    function claim(uint256 id) external {
        Campaign storage c = campaigns[id];
        if (msg.sender != c.creator) revert NotCreator();
        if (block.timestamp < c.deadline) revert NotEnded();
        if (c.closed) revert Closed();
        if (address(this).balance < c.goal) revert GoalNotReached();
        c.closed = true;
        uint256 fee = c.raised / 10_000 * FEE_BPS;
        uint256 amount = c.raised - fee;
        (bool ok,) = PLATFORM.call{value: fee}("");
        if (!ok) revert TransferFailed();
        (ok,) = c.creator.call{value: amount}("");
        if (!ok) revert TransferFailed();
        emit Claimed(id, amount, fee);
    }

    /// @notice Devuelve a cada aportante lo suyo si la campaña no llegó a su meta.
    function refundAll(uint256 id) external {
        Campaign storage c = campaigns[id];
        if (block.timestamp <= c.deadline) revert NotEnded();
        if (c.raised >= c.goal) revert GoalReached();
        if (c.closed) revert Closed();
        c.closed = true;
        address[] storage list = contributors[id];
        for (uint256 i = 0; i < list.length; i++) {
            uint256 amount = contributions[id][list[i]];
            contributions[id][list[i]] = 0;
            (bool ok,) = list[i].call{value: amount}("");
            if (!ok) revert TransferFailed();
        }
        emit Refunded(id);
    }
}
