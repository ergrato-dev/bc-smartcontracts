// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {GovToken} from "./GovToken.sol";
import {DaoGovernor} from "./DaoGovernor.sol";
import {Treasury} from "./Treasury.sol";

// ¿Qué? Monta la DAO en una sola transacción: el timelock, el Governor y la tesorería, con los
//   roles de cada uno.
// ¿Para qué? Que no quede ningún momento en el que una cuenta tenga más poder del que debe: al
//   acabar el constructor, este contrato ya no puede nada, y la DAO lo puede todo.
// ¿Impacto? Un rol de más o una renuncia de menos y alguien manda sin votar. Los tests lo miran.
contract DaoDeployer {
    /// @notice El plazo mínimo entre aprobar y ejecutar.
    uint256 public constant MIN_DELAY = 2 days;

    TimelockController public immutable timelock;
    DaoGovernor public immutable governor;
    Treasury public immutable treasury;

    /// @param token El token de los votos.
    /// @param guardian Quien puede cancelar una operación en cola, sin votar.
    constructor(GovToken token, address guardian) {
        address[] memory none = new address[](0);
        // PASO 1: el timelock espera dos días, y cualquiera ejecuta lo que ya esperó. Este
        // contrato es su administrador mientras dura el constructor.
        // Borra la línea que acaba en `// <- Paso 1` y descomenta las de debajo.
        timelock = new TimelockController(0, none, none, address(this)); // <- Paso 1
        //> address[] memory anyone = new address[](1);
        //> timelock = new TimelockController(MIN_DELAY, none, anyone, address(this));
        governor = new DaoGovernor(token, timelock);
        treasury = new Treasury(address(this));

        // PASO 2: el Governor es el único que pone operaciones en cola, y puede cancelarlas.
        // Descomenta las dos líneas de debajo.
        //> timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        //> timelock.grantRole(timelock.CANCELLER_ROLE(), address(governor));

        // PASO 3: el guardián también cancela, sin votar.
        // Descomenta la línea de debajo.
        //> timelock.grantRole(timelock.CANCELLER_ROLE(), guardian);

        // PASO 4: la tesorería es del timelock: solo lo aprobado y esperado la mueve.
        // Descomenta la línea de debajo.
        //> treasury.transferOwnership(address(timelock));

        // PASO 5: este contrato renuncia a administrar el timelock. Desde aquí, solo el timelock
        // se administra a sí mismo: los roles los cambia una propuesta.
        // Descomenta la línea de debajo.
        //> timelock.renounceRole(timelock.DEFAULT_ADMIN_ROLE(), address(this));
    }
}
