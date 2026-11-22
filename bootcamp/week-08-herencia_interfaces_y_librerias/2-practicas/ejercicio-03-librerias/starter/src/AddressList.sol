// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Funciones para un array de direcciones sin repetidos, guardado en el storage de
//   quien usa la librería.
// ¿Para qué? Saber si una cuenta está y quitarla sin dejar huecos.
// ¿Impacto? `contains` y `remove` recorren el array: su gas crece con el número de
//   cuentas. Para listas largas, un mapping de posiciones (semana 06).
library AddressList {
    // PASO 2: `true` si `account` está en la lista.
    function contains(address[] storage self, address account) internal view returns (bool) {
        revert("TODO: Paso 2");
        //> for (uint256 i = 0; i < self.length; i++) {
        //>     if (self[i] == account) return true;
        //> }
        //> return false;
    }

    // PASO 3: quitar `account` cambiándola por la última y haciendo `pop`. Devuelve si
    //   estaba.
    function remove(address[] storage self, address account) internal returns (bool) {
        revert("TODO: Paso 3");
        //> for (uint256 i = 0; i < self.length; i++) {
        //>     if (self[i] == account) {
        //>         self[i] = self[self.length - 1];
        //>         self.pop();
        //>         return true;
        //>     }
        //> }
        //> return false;
    }
}
