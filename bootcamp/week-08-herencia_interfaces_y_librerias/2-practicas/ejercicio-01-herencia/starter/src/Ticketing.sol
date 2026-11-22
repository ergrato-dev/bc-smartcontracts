// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Una taquilla construida con tres piezas heredadas: dueño, pausa y tope de entradas.
// ¿Para qué? Practicar `is`, los modificadores heredados, `override` con `super` y el orden
//   en que Solidity encadena los padres.
// ¿Impacto? Lo que hereda la taquilla entra en ella con sus mismos permisos: un `override`
//   que olvida `super` se salta las comprobaciones del padre.

// ¿Qué? El dueño del contrato. Es `abstract` aunque tiene todo el código: solo tiene
//   sentido dentro de otro contrato.
abstract contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    error NotOwner(address caller);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner(msg.sender);
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function layers() public pure virtual returns (string memory) {
        return "Owned";
    }
}

// ¿Qué? La pausa: el dueño detiene las ventas y las reanuda.
abstract contract Pausable is Owned {
    bool public paused;

    event PausedSet(bool paused);

    error IsPaused();

    modifier whenNotPaused() {
        if (paused) revert IsPaused();
        _;
    }

    // PASO 1: solo el dueño pausa o reanuda, y queda un evento.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function setPaused(bool value) external onlyOwner {
        revert("TODO: Paso 1");
        //> paused = value;
        //> emit PausedSet(value);
    }

    function layers() public pure virtual override returns (string memory) {
        return string.concat("Pausable > ", super.layers());
    }
}

// ¿Qué? El tope: cuántas entradas hay en total.
abstract contract Capped is Owned {
    uint256 public immutable CAP;
    uint256 public sold;

    error SoldOut(uint256 cap);

    constructor(uint256 cap) {
        CAP = cap;
    }

    function _take(uint256 amount) internal {
        if (sold + amount > CAP) revert SoldOut(CAP);
        sold += amount;
    }

    function layers() public pure virtual override returns (string memory) {
        return string.concat("Capped > ", super.layers());
    }
}

contract Ticketing is Pausable, Capped {
    mapping(address => uint256) public ticketsOf;

    event Bought(address indexed buyer, uint256 amount);

    error ZeroAddress();

    constructor(uint256 cap) Capped(cap) {}

    // PASO 2: comprar entradas con lo que heredas: `whenNotPaused` de Pausable y `_take` de
    //   Capped.
    function buy(uint256 amount) external whenNotPaused {
        revert("TODO: Paso 2");
        //> _take(amount);
        //> ticketsOf[msg.sender] += amount;
        //> emit Bought(msg.sender, amount);
    }

    // PASO 3: la regla nueva primero y, para el resto, la versión de Owned con `super`.
    function transferOwnership(address newOwner) public override {
        revert("TODO: Paso 3");
        //> if (newOwner == address(0)) revert ZeroAddress();
        //> super.transferOwnership(newOwner);
    }

    // PASO 4: dos padres con `layers`: la taquilla escribe la suya y nombra a los dos.
    function layers() public pure override(Pausable, Capped) returns (string memory) {
        revert("TODO: Paso 4");
        //> return string.concat("Ticketing > ", super.layers());
    }
}
