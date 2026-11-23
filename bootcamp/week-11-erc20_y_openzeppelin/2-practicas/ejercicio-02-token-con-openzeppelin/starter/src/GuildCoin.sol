// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Capped} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import {Owned} from "./Owned.sol";

// ¿Qué? La moneda de un gremio: un ERC-20 de OpenZeppelin con tope de suministro, quema y
//   un dueño que emite.
// ¿Para qué? Usar contratos auditados en vez de reescribirlos, y extenderlos por sus puntos
//   de extensión (`_update`) sin tocar su código.
// ¿Impacto? Lo que heredas también es tu responsabilidad: tienes que saber qué hace cada
//   función pública que tu contrato expone sin que la hayas escrito tú.
contract GuildCoin is ERC20, ERC20Burnable, ERC20Capped, Owned {
    uint256 public constant MAX_SUPPLY = 1_000_000 ether;

    error SelfTransfer();

    // PASO 1: el suministro inicial para el dueño. En un constructor no hay `revert("TODO")`:
    //   el contrato no compilaría (Owned tiene un immutable que se asigna al desplegar).
    //   Descomenta la línea que empieza con `//> `.
    constructor(uint256 initialSupply) ERC20("Guild Coin", "GLD") ERC20Capped(MAX_SUPPLY) {
        //> _mint(msg.sender, initialSupply);
    }

    // PASO 2: emitir tokens nuevos. Solo el dueño.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function mint(address to, uint256 amount) external onlyOwner {
        revert("TODO: Paso 2");
        //> _mint(to, amount);
    }

    // ¿Qué? `_update` es el punto por el que pasan mint, burn y transfer. Existe en ERC20 y
    //   en ERC20Capped, así que hay que nombrar los dos en `override` y llamar a `super`,
    //   que recorre la cadena de herencia: ERC20Capped comprueba el tope y ERC20 mueve saldos.
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Capped) {
        // PASO 3: rechazar tokens enviados al propio contrato, que nadie podría sacar.
        //   Descomenta la línea que empieza con `//> `.
        //> if (to == address(this)) revert SelfTransfer();
        super._update(from, to, value);
    }
}
