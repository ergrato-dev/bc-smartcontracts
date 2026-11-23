// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// ¿Qué? Un club con nombre y miembros, pensado para vivir detrás de un proxy: en vez de
//   constructor tiene `initialize`, que se ejecuta una sola vez sobre el storage del proxy.
// ¿Para qué? Practicar initializers: fijar el dueño y el nombre en el proxy, cerrar la
//   implementación y, en V2, inicializar lo nuevo con `reinitializer(2)`.
// ¿Impacto? Un `initialize` que cualquiera puede llamar dos veces, o una implementación sin
//   cerrar, dejan que otra cuenta se haga dueña.
contract ClubV1 is Initializable, OwnableUpgradeable {
    string public name;
    uint256 public members;
    mapping(address => bool) public isMember;

    event Joined(address indexed member);

    error AlreadyMember(address member);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // PASO 2: cerrar la implementación. Nadie podrá llamar a `initialize` sobre ella.
        //> _disableInitializers();
    }

    /// @notice Fija el dueño y el nombre del club. Se llama una vez, desde el proxy.
    /// @param initialOwner Quien podrá cambiar el nombre.
    /// @param clubName Nombre del club.
    function initialize(address initialOwner, string calldata clubName) external initializer {
        // PASO 1: lo que haría el constructor, sobre el storage del proxy.
        // Descomenta las líneas que empiezan con `//> `.
        //> __Ownable_init(initialOwner);
        //> name = clubName;
    }

    /// @notice Se une quien llama.
    function join() public virtual {
        if (isMember[msg.sender]) revert AlreadyMember(msg.sender);
        isMember[msg.sender] = true;
        members++;
        emit Joined(msg.sender);
    }

    /// @notice Cambia el nombre. Solo el dueño.
    function rename(string calldata newName) external onlyOwner {
        name = newName;
    }
}

// ¿Qué? La versión 2: un máximo de miembros, en una variable nueva al final del storage.
contract ClubV2 is ClubV1 {
    uint256 public maxMembers;

    error ClubFull(uint256 maxMembers);

    /// @notice Inicializa lo que trae V2. Se llama una vez, al actualizar.
    /// @param newMaxMembers Cuántos miembros admite el club.
    function initializeV2(uint256 newMaxMembers) external reinitializer(2) {
        // PASO 3: inicializar la variable nueva.
        //> maxMembers = newMaxMembers;
    }

    function join() public override {
        if (members >= maxMembers) revert ClubFull(maxMembers);
        super.join();
    }
}
