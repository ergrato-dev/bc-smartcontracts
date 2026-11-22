// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IERC165, IPriceFeed} from "./IPriceFeed.sol";

// ¿Qué? La plantilla de toda fuente: comprueba el precio antes de darlo. Cada hija decide
//   de dónde sale con `_readPrice`.
// ¿Para qué? Que ninguna fuente pueda devolver un precio 0, se lea como se lea.
// ¿Impacto? `latestPrice` no es `virtual`: una hija no puede saltarse la comprobación.
abstract contract BaseFeed is IPriceFeed, IERC165 {
    error InvalidPrice();

    function decimals() external pure returns (uint8) {
        return 8;
    }

    // PASO 1: la plantilla. Lee el precio de la hija y rechaza el 0.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function latestPrice() external view returns (uint256) {
        revert("TODO: Paso 1");
        //> uint256 price = _readPrice();
        //> if (price == 0) revert InvalidPrice();
        //> return price;
    }

    // PASO 5: responder `true` para IPriceFeed y para la propia ERC-165, y `false` para el
    //   resto.
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        revert("TODO: Paso 5");
        //> return interfaceId == type(IPriceFeed).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    function _readPrice() internal view virtual returns (uint256);
}

// ¿Qué? Una fuente con un precio fijo desde el despliegue.
contract FixedFeed is BaseFeed {
    uint256 public immutable PRICE;

    constructor(uint256 price) {
        PRICE = price;
    }

    // PASO 2: el hueco de la plantilla, con el precio fijo.
    function _readPrice() internal view override returns (uint256) {
        revert("TODO: Paso 2");
        //> return PRICE;
    }
}

// ¿Qué? Una fuente que actualiza a mano una sola cuenta, la que la despliega.
contract ManualFeed is BaseFeed {
    address public immutable UPDATER;
    uint256 public price;

    event PriceUpdated(uint256 price);

    error NotUpdater(address caller);

    constructor() {
        UPDATER = msg.sender;
    }

    // PASO 3: solo UPDATER cambia el precio. No compruebes aquí el 0: ya lo hace la
    //   plantilla al leerlo.
    function setPrice(uint256 newPrice) external {
        revert("TODO: Paso 3");
        //> if (msg.sender != UPDATER) revert NotUpdater(msg.sender);
        //> price = newPrice;
        //> emit PriceUpdated(newPrice);
    }

    function _readPrice() internal view override returns (uint256) {
        return price;
    }
}
