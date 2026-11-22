// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? ERC-165: preguntarle a un contrato qué interfaces cumple.
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// ¿Qué? Lo que promete una fuente de precios: el precio de 1 ETH en dólares.
// ¿Para qué? Que un contrato que necesita el precio funcione con cualquier fuente que la
//   cumpla, sin conocer su código.
// ¿Impacto? La interfaz dice qué funciones hay, no si el precio es bueno: quien la usa
//   sigue teniendo que comprobar lo que recibe.
interface IPriceFeed {
    // ¿Qué? Cuántos decimales tiene el precio: con 8, 3000 dólares es 300000000000.
    function decimals() external view returns (uint8);

    function latestPrice() external view returns (uint256);
}
