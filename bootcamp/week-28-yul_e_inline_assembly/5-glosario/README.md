# 📖 Glosario — Semana 28

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| `.offset` y `.length` (calldata) | En assembly, dónde empiezan en la calldata los datos de un parámetro dinámico y cuántos elementos o bytes tiene | `calldataload(add(xs.offset, shl(5, i)))` |
| `.slot` y `.offset` (storage) | En assembly, el slot de una variable de estado y el byte donde empieza dentro de él | `other.slot` 0, `other.offset` 8 |
| Bits sucios (*dirty bits*) | Bits altos distintos de cero en una variable de menos de 256 bits, que solo puede dejar el assembly | `r := 0x1ff` en un `uint8` |
| Bloque de assembly (*inline assembly*) | Código Yul dentro de una función de Solidity, en `assembly { ... }` | `assembly { y := mul(x, 3) }` |
| Búfer de returndata | Lo que devolvió la última llamada, aparte de la memoria, hasta la siguiente llamada | `returndatasize()`, `returndatacopy(0, 0, 4)` |
| Código de despliegue (*init code*) | El código que se ejecuta una vez al crear un contrato y devuelve el código runtime | El `code` de fuera de un objeto Yul |
| `datacopy`, `dataoffset`, `datasize` | Funciones de un objeto Yul que copian a memoria un subobjeto y dan su posición y su tamaño en el bytecode | `datasize("runtime")` = 47 |
| `leave` | Sale de la función de Yul en la que está, como `return` | `if iszero(x) { leave }` |
| `memory-safe` | Marca de un bloque de assembly que promete respetar las reglas de memoria de Solidity; nadie la comprueba | `assembly ("memory-safe") { ... }` |
| Mutante equivalente (*equivalent mutant*) | Cambio del código que no altera su comportamiento, así que ninguna prueba puede matarlo | Quitar la máscara del selector antes de `abi.encodePacked` |
| Objeto Yul (*Yul object*) | Un contrato entero en Yul: código de despliegue y el objeto `runtime` dentro | `object "Counter" { code { ... } object "runtime" { ... } }` |
| Propagar un error (*bubbling*) | Revertir con los mismos bytes con que revirtió el contrato llamado | `returndatacopy(ptr, 0, size)` y `revert(ptr, size)` |
| `--strict-assembly` | Opción de solc que compila un archivo de Yul puro | `solc-0.8.38 --strict-assembly --bin src/Counter.yul` |
| Test diferencial (*differential testing*) | Prueba que compara dos implementaciones de lo mismo con las mismas entradas | `addChecked` en assembly contra `a + b` |
| `u256` | El único tipo de Yul de la EVM: una palabra de 256 bits | `-1` y `2²⁵⁶ - 1` son la misma palabra |
| Yul | Lenguaje intermedio de solc, con variables y funciones pero opcodes como operaciones | `let x := add(1, 2)` |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | [Semana 29 — Optimización de gas →](../../week-29-optimizacion_de_gas/README.md) |
