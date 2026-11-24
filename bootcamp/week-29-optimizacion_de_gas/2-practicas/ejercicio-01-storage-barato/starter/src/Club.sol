// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Un club de socios: altas, puntos, premios que se reclaman una vez y pagos.
// ¿Para qué? Cada función gasta de más en storage de una forma distinta, y cada paso la arregla
//   sin cambiar lo que hace: los tests de comportamiento siguen en verde y los de gas pasan a verde.
// ¿Impacto? Ninguno fuera del ejercicio: no guarda ETH de nadie, solo cuenta pagos.
contract Club {
    // PASO 1: ordenar los campos para que `account`, `joinedAt` y `active` compartan un slot.
    // Borra las líneas que acaban en `// <- Paso 1` y descomenta las que empiezan con `//> `.
    struct Member {
        bool active; // <- Paso 1
        uint256 points; // <- Paso 1
        address account; // <- Paso 1
        uint64 joinedAt; // <- Paso 1
        //> address account;
        //> uint64 joinedAt;
        //> bool active;
        //> uint256 points;
    }

    // PASO 4: `owner` no cambia nunca después del constructor.
    address public owner; // <- Paso 4
    //> address public immutable OWNER;
    uint256 public totalPoints;
    Member[] private _members;
    mapping(address => uint256) public memberIndex;

    // PASO 3: un bit por premio en vez de un `bool` por premio.
    mapping(uint256 => bool) public claimed; // <- Paso 3
    //> mapping(uint256 => uint256) private _claimedWords;

    // PASO 5: los pagos se guardan solo para leerlos fuera de la cadena.
    uint256[] public payments; // <- Paso 5

    event Paid(address indexed member, uint256 amount);

    error NotOwner(address caller);
    error AlreadyMember(address account);
    error NotMember(address account);
    error AlreadyClaimed(uint256 prize);

    constructor() {
        owner = msg.sender; // <- Paso 4
        //> OWNER = msg.sender;
    }

    /// @notice Da de alta a `msg.sender` como socio activo, con 0 puntos.
    function join() external {
        if (memberIndex[msg.sender] != 0) revert AlreadyMember(msg.sender);
        _members.push(Member({account: msg.sender, joinedAt: uint64(block.timestamp), active: true, points: 0}));
        memberIndex[msg.sender] = _members.length;
    }

    /// @notice Suma `amount` puntos a cada socio. Solo el dueño.
    function rewardAll(uint256 amount) external {
        if (msg.sender != owner) revert NotOwner(msg.sender); // <- Paso 4
        //> if (msg.sender != OWNER) revert NotOwner(msg.sender);
        // PASO 2: leer la longitud una vez y escribir `totalPoints` una vez, al final.
        //> uint256 n = _members.length;
        for (uint256 i = 0; i < _members.length; i++) { // <- Paso 2
        //> for (uint256 i = 0; i < n; i++) {
            _members[i].points += amount;
            totalPoints += amount; // <- Paso 2
        }
        //> totalPoints += amount * n;
    }

    /// @notice Si `account` es el dueño del club.
    function isOwner(address account) external view returns (bool) {
        return account == owner; // <- Paso 4
        //> return account == OWNER;
    }

    /// @notice Los datos del socio `account`. Revierte si no es socio.
    function memberOf(address account) external view returns (Member memory) {
        uint256 index = memberIndex[account];
        if (index == 0) revert NotMember(account);
        return _members[index - 1];
    }

    /// @notice Marca el premio `prize` como reclamado. Cada premio, una sola vez.
    function claim(uint256 prize) external {
        if (isClaimed(prize)) revert AlreadyClaimed(prize);
        claimed[prize] = true; // <- Paso 3
        //> _claimedWords[prize >> 8] |= 1 << (prize & 0xff);
    }

    /// @notice Si el premio `prize` ya se reclamó.
    function isClaimed(uint256 prize) public view returns (bool) {
        return claimed[prize]; // <- Paso 3
        //> return _claimedWords[prize >> 8] & (1 << (prize & 0xff)) != 0;
    }

    /// @notice Registra un pago de `msg.sender`.
    function pay(uint256 amount) external {
        payments.push(amount); // <- Paso 5
        emit Paid(msg.sender, amount);
    }
}
