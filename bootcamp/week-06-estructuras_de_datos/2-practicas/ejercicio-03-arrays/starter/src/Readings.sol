// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Una lista de lecturas de un sensor (array dinámico) y un podio de tres (array fijo).
// ¿Para qué? Practicar push, pop, length, borrar con swap-and-pop, recorrer con un límite,
//   arrays de tamaño fijo en calldata y arrays nuevos en memory.
// ¿Impacto? Un array que crece sin límite hace que recorrerlo cueste cada vez más gas,
//   hasta que ya no cabe en un bloque.
contract Readings {
    uint256 public constant MAX_LENGTH = 10;

    uint256[] public values;
    uint256[3] public podium;

    error ListFull(uint256 max);
    error EmptyList();
    error IndexOutOfBounds(uint256 index, uint256 length);

    // Devuelve el array entero, copiado a memory. Ya está escrita: la usan los tests.
    function getAll() external view returns (uint256[] memory) {
        return values;
    }

    // PASO 1: añadir una lectura al final; ListFull si ya hay MAX_LENGTH.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function add(uint256 value) external {
        revert("TODO: Paso 1");
        //> if (values.length >= MAX_LENGTH) revert ListFull(MAX_LENGTH);
        //> values.push(value);
    }

    // PASO 2: quitar la última lectura; EmptyList si no hay ninguna.
    function removeLast() external {
        revert("TODO: Paso 2");
        //> if (values.length == 0) revert EmptyList();
        //> values.pop();
    }

    // PASO 3: quitar la lectura de la posición `index` sin dejar huecos: la última ocupa
    //   su lugar y se hace pop (swap-and-pop). El orden cambia.
    function removeAt(uint256 index) external {
        revert("TODO: Paso 3");
        //> uint256 length = values.length;
        //> if (index >= length) revert IndexOutOfBounds(index, length);
        //> values[index] = values[length - 1];
        //> values.pop();
    }

    // PASO 4: sumar todas las lecturas. El bucle está acotado por MAX_LENGTH.
    function sum() external view returns (uint256 total) {
        revert("TODO: Paso 4");
        //> uint256 length = values.length;
        //> for (uint256 i = 0; i < length; i++) {
        //>     total += values[i];
        //> }
    }

    // PASO 5: guardar el podio completo. Un array fijo llega entero en calldata.
    function setPodium(uint256[3] calldata top) external {
        revert("TODO: Paso 5");
        //> podium = top;
    }

    // PASO 6: devolver las `n` primeras lecturas en un array nuevo creado en memory;
    //   IndexOutOfBounds si n pasa de la longitud.
    function firstN(uint256 n) external view returns (uint256[] memory result) {
        revert("TODO: Paso 6");
        //> uint256 length = values.length;
        //> if (n > length) revert IndexOutOfBounds(n, length);
        //> result = new uint256[](n);
        //> for (uint256 i = 0; i < n; i++) {
        //>     result[i] = values[i];
        //> }
    }
}
