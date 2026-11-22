# 📖 Glosario — Semana 03

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| ABI (*Application Binary Interface*) | Lista en JSON de las funciones de un contrato con sus parámetros y retornos; la usan los clientes para llamarlo | `forge inspect Counter abi` |
| `address` | Tipo de Solidity para una dirección de 20 bytes | `address lastCaller;` |
| Artefacto (*artifact*) | JSON que deja `forge build` por contrato, con ABI, bytecode y selectores | `out/Counter.sol/Counter.json` |
| Aserción (*assertion*) | Comprobación de un test; si no se cumple, el test falla | `assertEq(counter.get(), 7);` |
| Cheatcode | Función de `forge` que cambia las reglas de la EVM de prueba | `vm.prank(alice);` |
| Compilador (*compiler*) | Programa que traduce código fuente a otro formato; aquí, Solidity a bytecode | solc 0.8.38 |
| `contract` | Palabra de Solidity que define un contrato: variables de estado y funciones | `contract Counter { ... }` |
| Devolución (*refund*) | Parte del gas que se devuelve al liberar storage (poner un slot a cero) | `set(0)` usa 21784 de gas |
| `external` | Visibilidad de una función que se llama desde fuera del contrato | `function get() external view` |
| Foundry | Conjunto de herramientas para contratos: `forge`, `cast`, `anvil`, `chisel` | getfoundry.sh |
| `forge` | Herramienta de Foundry que compila, prueba y despliega contratos | `forge test` |
| `foundry.toml` | Archivo de configuración de un proyecto Foundry | `solc_version = "0.8.38"` |
| `msg.sender` | Dirección de quien llama a la función; no se puede falsificar | `lastCaller = msg.sender;` |
| `pragma` | Línea que fija la versión del compilador que acepta un archivo | `pragma solidity 0.8.38;` |
| `pure` | Función que ni lee ni escribe el estado | `function add(...) external pure` |
| Revertir (*revert*) | Detener una ejecución y deshacer todos sus cambios | `panic: arithmetic underflow or overflow (0x11)` |
| Selector | Primeros 4 bytes del keccak256 de la firma de una función; abre el `input` de cada llamada | `cast sig "increment()"` → `0xd09de08a` |
| `setUp` | Función de un test que se ejecuta antes de cada test | `counter = new Counter();` |
| Simulación (*dry run*) | Ejecución de prueba que construye la transacción sin enviarla | `forge create` sin `--broadcast` |
| Slot | Casilla de 32 bytes del storage, numerada desde 0 | `cast storage DIR 0` |
| solc | El compilador de Solidity | `Compiling 1 files with Solc 0.8.38` |
| Solidity | Lenguaje de programación de contratos para la EVM | `Counter.sol` |
| SPDX | Estándar para declarar la licencia en la primera línea del archivo | `// SPDX-License-Identifier: MIT` |
| Storage | Almacenamiento persistente de un contrato, dentro de su cuenta | `forge inspect Counter storageLayout` |
| Traza (*trace*) | Árbol de llamadas de una ejecución con gas, argumentos y resultados | `forge test -vvvv` |
| `uint256` | Entero sin signo de 256 bits; el tipo numérico básico | `uint256 number;` |
| Variable de estado (*state variable*) | Variable declarada en el contrato, fuera de las funciones; vive en el storage | `uint256 count;` |
| `view` | Función que lee el estado pero no lo cambia | `function get() external view` |
| Warning (aviso) | Mensaje del compilador que no impide compilar | `Warning (2018)` |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | [Semana 04 — Tipos y funciones →](../../week-04-tipos_y_funciones/README.md) |
