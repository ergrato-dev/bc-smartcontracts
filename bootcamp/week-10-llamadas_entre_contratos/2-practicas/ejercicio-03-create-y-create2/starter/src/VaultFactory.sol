// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Vault} from "./Vault.sol";

// ¿Qué? Una fábrica de cajas fuertes: cada cuenta despliega las suyas, con CREATE o con
//   CREATE2.
// ¿Para qué? Conocer la dirección de una caja antes de que exista, y que nadie más pueda
//   ocuparla.
// ¿Impacto? Una dirección de CREATE2 depende del salt y del código de creación. Si la
//   predicción y el despliegue no usan exactamente los mismos, no coinciden.
contract VaultFactory {
    error AlreadyDeployed(address vault);

    // PASO 1: desplegar una caja para quien llama, con CREATE.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function create() external returns (Vault) {
        revert("TODO: Paso 1");
        //> return new Vault(msg.sender);
    }

    // PASO 2: el salt real de una cuenta. Mezcla la cuenta con el salt que elige, para que
    //   cada cuenta solo pueda ocupar sus propias direcciones.
    function saltOf(address owner, bytes32 salt) public pure returns (bytes32) {
        revert("TODO: Paso 2");
        //> return keccak256(abi.encode(owner, salt));
    }

    // PASO 3: la dirección que tendrá la caja de `owner` con `salt`, sin desplegarla.
    //   keccak256(0xff ++ esta fábrica ++ salt real ++ keccak256(código de creación)).
    function predict(address owner, bytes32 salt) public view returns (address) {
        revert("TODO: Paso 3");
        //> bytes32 initCodeHash = keccak256(bytes.concat(type(Vault).creationCode, abi.encode(owner)));
        //> bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), saltOf(owner, salt), initCodeHash));
        //> return address(uint160(uint256(hash)));
    }

    // PASO 4: desplegar con CREATE2 en la dirección de `predict`. Si ya está ocupada,
    //   revertir con un error propio antes de que CREATE2 falle sin datos.
    function create2(bytes32 salt) external returns (Vault) {
        revert("TODO: Paso 4");
        //> address predicted = predict(msg.sender, salt);
        //> if (predicted.code.length > 0) revert AlreadyDeployed(predicted);
        //> return new Vault{salt: saltOf(msg.sender, salt)}(msg.sender);
    }
}
