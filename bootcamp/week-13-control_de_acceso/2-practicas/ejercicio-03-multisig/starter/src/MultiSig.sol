// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Una cuenta compartida: ejecuta una llamada cuando la confirman `THRESHOLD` de sus
//   dueños. Cada confirmación es una transacción.
// ¿Para qué? Que el control de otro contrato (su `owner`, su `DEFAULT_ADMIN_ROLE`) no
//   dependa de una sola clave.
// ¿Impacto? Robar una clave ya no basta: hacen falta `THRESHOLD`. Pero perder demasiadas
//   bloquea la cuenta para siempre: no hay forma de cambiar dueños ni umbral.
contract MultiSig {
    struct Proposal {
        address target;
        uint256 value;
        bytes data;
        uint256 confirmations;
        bool executed;
    }

    uint256 public immutable THRESHOLD;
    address[] public owners;
    mapping(address => bool) public isOwner;
    Proposal[] public proposals;
    mapping(uint256 => mapping(address => bool)) public confirmed;

    event Submitted(uint256 indexed id, address indexed owner, address target, uint256 value, bytes data);
    event Confirmed(uint256 indexed id, address indexed owner);
    event Executed(uint256 indexed id);

    error NotOwner(address caller);
    error InvalidThreshold(uint256 threshold, uint256 owners);
    error InvalidOwner(address owner);
    error ProposalNotFound(uint256 id);
    error AlreadyConfirmed(uint256 id, address owner);
    error AlreadyExecuted(uint256 id);
    error NotEnoughConfirmations(uint256 id, uint256 confirmations, uint256 threshold);
    error CallFailed(uint256 id, bytes reason);

    modifier onlyOwner() {
        if (!isOwner[msg.sender]) revert NotOwner(msg.sender);
        _;
    }

    constructor(address[] memory initialOwners, uint256 threshold) {
        // PASO 1: un umbral entre 1 y el número de dueños, y dueños distintos de
        //   address(0) y sin repetir. Descomenta las líneas que empiezan con `//> `.
        //> if (threshold == 0 || threshold > initialOwners.length) {
        //>     revert InvalidThreshold(threshold, initialOwners.length);
        //> }
        //> for (uint256 i = 0; i < initialOwners.length; i++) {
        //>     address owner = initialOwners[i];
        //>     // Un dueño inválido invalida el despliegue entero, a propósito.
        //>     // forge-lint: disable-next-line(require-revert-in-loop)
        //>     if (owner == address(0) || isOwner[owner]) revert InvalidOwner(owner);
        //>     isOwner[owner] = true;
        //> }
        owners = initialOwners;
        THRESHOLD = threshold;
    }

    // Para recibir ETH y poder enviarlo en una propuesta.
    receive() external payable {}

    // PASO 2: proponer una llamada. El id es su posición en `proposals`.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function submit(address target, uint256 value, bytes calldata data) external onlyOwner returns (uint256 id) {
        revert("TODO: Paso 2");
        //> id = proposals.length;
        //> proposals.push(Proposal({target: target, value: value, data: data, confirmations: 0, executed: false}));
        //> emit Submitted(id, msg.sender, target, value, data);
    }

    // PASO 3: confirmar, una vez por dueño.
    function confirm(uint256 id) external onlyOwner {
        revert("TODO: Paso 3");
        //> Proposal storage proposal = _proposal(id);
        //> if (proposal.executed) revert AlreadyExecuted(id);
        //> if (confirmed[id][msg.sender]) revert AlreadyConfirmed(id, msg.sender);
        //> confirmed[id][msg.sender] = true;
        //> proposal.confirmations++;
        //> emit Confirmed(id, msg.sender);
    }

    // PASO 4: ejecutar con el umbral alcanzado. Se marca antes de llamar (semana 07).
    function execute(uint256 id) external onlyOwner {
        revert("TODO: Paso 4");
        //> Proposal storage proposal = _proposal(id);
        //> if (proposal.executed) revert AlreadyExecuted(id);
        //> if (proposal.confirmations < THRESHOLD) {
        //>     revert NotEnoughConfirmations(id, proposal.confirmations, THRESHOLD);
        //> }
        //> proposal.executed = true;
        //> emit Executed(id);
        // El destino lo eligió un dueño y lo confirmaron THRESHOLD: no es de cualquiera.
        // forge-lint: disable-next-line(arbitrary-send-eth)
        //> (bool ok, bytes memory reason) = proposal.target.call{value: proposal.value}(proposal.data);
        //> if (!ok) revert CallFailed(id, reason);
    }

    // La propuesta `id`, o `ProposalNotFound` si no existe.
    function _proposal(uint256 id) internal view returns (Proposal storage) {
        if (id >= proposals.length) revert ProposalNotFound(id);
        return proposals[id];
    }
}
