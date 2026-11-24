// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

/// @title Escrow con árbitro
/// @notice ¿Qué? Un comprador deposita ETH para un vendedor. Si recibe lo comprado, libera el pago;
///   si el vendedor no entrega, recupera el ETH tras el plazo; si no se ponen de acuerdo, cualquiera
///   de los dos abre una disputa y la decide el árbitro.
/// @dev ¿Para qué? Es el contrato que auditas en el ejercicio 01: pocas funciones, cuatro actores y
///   un solo activo, el ETH depositado.
contract Escrow {
    enum Status {
        None,
        Funded,
        Disputed,
        Closed
    }

    struct Deal {
        address buyer;
        address seller;
        uint256 amount;
        uint64 deadline;
        Status status;
    }

    /// @notice Quien decide las disputas. Se fija al desplegar y no cambia.
    address public immutable ARBITER;
    uint256 public nextId;
    mapping(uint256 => Deal) public deals;

    event Opened(uint256 indexed id, address indexed buyer, address indexed seller, uint256 amount);
    event Disputed(uint256 indexed id);
    event Paid(uint256 indexed id, address indexed to, uint256 amount);

    error InvalidDeal();
    error NotBuyer();
    error NotParty();
    error NotArbiter();
    error WrongStatus();
    error TooEarly();
    error TooLate();
    error TransferFailed();

    constructor(address arbiter) {
        ARBITER = arbiter;
    }

    /// @notice Abre un trato con el ETH enviado, para `seller`, con plazo de entrega `deadline`.
    function open(address seller, uint64 deadline) external payable returns (uint256 id) {
        if (msg.value == 0 || seller == address(0) || seller == msg.sender || deadline <= block.timestamp) {
            revert InvalidDeal();
        }
        id = nextId++;
        deals[id] = Deal(msg.sender, seller, msg.value, deadline, Status.Funded);
        emit Opened(id, msg.sender, seller, msg.value);
    }

    /// @notice El comprador recibió lo comprado: el pago va al vendedor.
    function release(uint256 id) external {
        Deal storage deal = deals[id];
        if (msg.sender != deal.buyer) revert NotBuyer();
        if (deal.status != Status.Funded) revert WrongStatus();
        _pay(deal, id, deal.seller);
    }

    /// @notice El plazo pasó sin disputa: el comprador recupera su ETH.
    function refund(uint256 id) external {
        Deal storage deal = deals[id];
        if (msg.sender != deal.buyer) revert NotBuyer();
        if (deal.status != Status.Funded) revert WrongStatus();
        if (block.timestamp <= deal.deadline) revert TooEarly();
        _pay(deal, id, deal.buyer);
    }

    /// @notice Comprador o vendedor congelan el trato hasta que decida el árbitro. Solo dentro del plazo.
    function dispute(uint256 id) external {
        Deal storage deal = deals[id];
        if (msg.sender != deal.buyer && msg.sender != deal.seller) revert NotParty();
        if (deal.status != Status.Funded) revert WrongStatus();
        if (block.timestamp > deal.deadline) revert TooLate();
        deal.status = Status.Disputed;
        emit Disputed(id);
    }

    /// @notice El árbitro decide una disputa: el ETH va a `to`.
    function resolve(uint256 id, address to) external {
        Deal storage deal = deals[id];
        if (msg.sender != ARBITER) revert NotArbiter();
        if (deal.status != Status.Disputed) revert WrongStatus();
        // PASO 5: el árbitro solo elige entre las dos partes del trato.
        // Descomenta la línea que empieza con `//> `.
        //> if (to != deal.buyer && to != deal.seller) revert NotParty();
        _pay(deal, id, to);
    }

    // ¿Qué? Cierra el trato y envía el ETH.
    // ¿Impacto? Estado y saldo a cero antes de enviar (checks-effects-interactions, semana 21):
    //   quien recibe y vuelve a entrar encuentra el trato cerrado.
    function _pay(Deal storage deal, uint256 id, address to) private {
        uint256 amount = deal.amount;
        deal.status = Status.Closed;
        deal.amount = 0;
        (bool ok,) = to.call{value: amount}("");
        if (!ok) revert TransferFailed();
        emit Paid(id, to, amount);
    }
}
