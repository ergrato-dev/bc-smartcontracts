// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Registry} from "../src/Registry.sol";
import {IRegistry} from "../src/IRegistry.sol";
import {IERC165} from "../src/IERC165.sol";

// ¿Qué? Un test sobre una copia (fork) de tu anvil, con el registro que desplegaste.
// ¿Para qué? Probar el contrato desplegado, con el estado que dejaste con `cast`, no uno
//   recién creado en setUp.
// ¿Impacto? Lo que el test registra existe solo en la copia: tu anvil no cambia.
contract RegistryForkTest is Test {
    // TODO: sin la variable de entorno FORK_URL, el test se salta (`vm.envOr` + `vm.skip`).
    //   Con ella, abre el fork, toma el registro de la variable REGISTRY y comprueba que:
    //   responde true a type(IRegistry).interfaceId; ya tiene al menos un recurso (count > 0);
    //   una cuenta nueva (`makeAddr`) registra pagando REGISTRATION_FEE() y recibe el id
    //   count + 1, con ella como registrante.
    function test_Fork_RegistersOnACopy() public {
        revert("TODO: test_Fork_RegistersOnACopy");
    }
}
