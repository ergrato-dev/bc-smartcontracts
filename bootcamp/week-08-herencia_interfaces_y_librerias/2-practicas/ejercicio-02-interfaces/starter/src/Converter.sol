// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IPriceFeed} from "./IPriceFeed.sol";

// ¿Qué? Convierte un importe en wei a dólares con el precio de una fuente.
// ¿Para qué? Ver que un contrato puede usar otro sabiendo solo su dirección y su interfaz.
// ¿Impacto? El conversor se fía del precio que le dan: si la fuente miente, el resultado
//   también. Elegir la fuente es una decisión de seguridad.
contract Converter {
    IPriceFeed public immutable FEED;

    constructor(IPriceFeed feed) {
        FEED = feed;
    }

    // PASO 4: dólares (con los decimales de la fuente) de `weiAmount`. Multiplica antes de
    //   dividir: 1 ether son 10^18 wei.
    function toUsd(uint256 weiAmount) external view returns (uint256) {
        revert("TODO: Paso 4");
        //> return weiAmount * FEED.latestPrice() / 1 ether;
    }
}
