// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// ¿Qué? Un tablón de notas UUPS: el código que actualiza está en la implementación, no en el
//   proxy, y `_authorizeUpgrade` decide quién puede actualizar.
// ¿Para qué? Practicar UUPS y ver qué conserva una actualización: el storage del proxy,
//   slot a slot.
// ¿Impacto? Si `_authorizeUpgrade` no comprueba nada, cualquiera cambia el código del
//   tablón. Si V2 no hereda de UUPSUpgradeable, el tablón no se puede volver a actualizar.
contract NotesV1 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 public count;
    mapping(uint256 => string) public notes;

    event Posted(uint256 indexed id, address indexed author);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) external initializer {
        __Ownable_init(initialOwner);
    }

    /// @notice Publica una nota. Cualquiera puede.
    function post(string calldata text) public virtual returns (uint256 id) {
        id = ++count;
        notes[id] = text;
        emit Posted(id, msg.sender);
    }

    function version() external pure virtual returns (uint256) {
        return 1;
    }

    // `upgradeToAndCall` lo llama antes de cambiar la implementación: si revierte, no se actualiza.
    function _authorizeUpgrade(address) internal view override {
        // PASO 1: solo el dueño actualiza.
        // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
        revert("TODO: Paso 1");
        //> _checkOwner();
    }
}

// ¿Qué? La versión 2: guarda quién publicó cada nota, en una variable nueva al final.
contract NotesV2 is NotesV1 {
    mapping(uint256 => address) public authorOf;

    function post(string calldata text) public override returns (uint256 id) {
        // PASO 2: publicar como V1 y guardar el autor.
        revert("TODO: Paso 2");
        //> id = super.post(text);
        //> authorOf[id] = msg.sender;
    }

    function version() external pure override returns (uint256) {
        return 2;
    }
}

// ¿Qué? Una V2 mal hecha: declara una variable nueva ANTES de las de V1. Ya está completa.
// ¿Impacto? `lastAuthor` ocupa el slot 0, que en el proxy es `count`, y todo lo demás se
//   desplaza un slot. No la despliegues nunca: el test la usa para ver la corrupción.
contract NotesV2Bad is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    address public lastAuthor;
    uint256 public count;
    mapping(uint256 => string) public notes;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function _authorizeUpgrade(address) internal view override onlyOwner {}
}
