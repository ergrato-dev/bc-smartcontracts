# Semana 27 — La EVM por dentro

Desde la semana 03 compilas Solidity y despliegas el resultado sin mirarlo. Esta semana abres la
caja: el **bytecode** que ejecuta la EVM, los **opcodes** que lo forman, la **pila** de palabras de
32 bytes donde trabajan, la **memoria** que nace vacía en cada llamada, los **slots** de storage
donde vive cada variable, y la **calldata** y la **returndata** por las que entran y salen los
datos. Escribes bytecode a mano, lees el storage privado de un contrato y codificas calldata byte a
byte. En el proyecto compruebas, slot a slot, que el proxy de tu protocolo guarda cada dato donde
lo dejó la versión anterior.

## 🎯 Objetivos de aprendizaje

- Explicar cómo ejecuta la EVM un contrato: pila, contador de programa, opcodes y gas de cada paso.
- Leer el bytecode de solc: prólogo, comprobación de ETH y *dispatcher* por selector.
- Calcular el coste de la memoria y reconocer los ataques que se apoyan en él.
- Calcular el slot de cualquier dato: variables empaquetadas, mappings, arrays, strings, structs y
  espacios de nombres ERC-7201, y leerlo con `cast storage` y `vm.load`.
- Codificar calldata a mano, saber qué rechaza el decodificador y abrir la returndata de un revert.
- Explicar el precio de `SLOAD` y `SSTORE` (frío, caliente, reembolsos), el del transient storage y
  el de la calldata.

## 📋 Prerrequisitos

[Semana 26](../week-26-auditoria/README.md) terminada: tu protocolo con su informe de auditoría
final, en `main`. Esta semana usa el ABI encoding y `call` de la semana 10, los proxies, ERC-1967 y
ERC-7201 de la semana 15, la reentrancy de la semana 21 y la *return bomb* de su proyecto.

La imagen del contenedor no cambia: es la de la semana 25.

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — La máquina de pila](1-teoria/01-la-maquina-de-pila.md) | 50 min |
| 2 | [Teoría 02 — La memoria](1-teoria/02-la-memoria.md) | 40 min |
| 3 | [Teoría 03 — El storage por dentro](1-teoria/03-el-storage-por-dentro.md) | 50 min |
| 4 | [Teoría 04 — Calldata y returndata](1-teoria/04-calldata-y-returndata.md) | 40 min |
| 5 | [Ejercicio 01 — Bytecode a mano](2-practicas/ejercicio-01-bytecode-a-mano/README.md) | 1 h 30 min |
| 6 | [Ejercicio 02 — Storage al descubierto](2-practicas/ejercicio-02-storage-al-descubierto/README.md) | 2 h |
| 7 | [Ejercicio 03 — Calldata y memoria](2-practicas/ejercicio-03-calldata-y-memoria/README.md) | 2 h |
| 8 | [Proyecto — Mapa de storage](3-proyecto/README.md) | 4 h |
| 9 | [Rúbrica de evaluación](rubrica-evaluacion.md) (autoevaluación) | 30 min |
| 10 | [Ebooks](4-recursos/ebooks-free/README.md), [videos](4-recursos/videografia/README.md), [webgrafía](4-recursos/webgrafia/README.md) y [glosario](5-glosario/README.md) | 30 min |

## ⏱️ Distribución del tiempo (14 h)

| Parte | Tiempo |
| ----- | ------ |
| Teoría | 3 h |
| Prácticas | 5 h 30 min |
| Proyecto | 4 h |
| Autoevaluación, recursos y glosario | 1 h |
| Margen para el mapa de storage | 30 min |

## ✅ Cómo saber que terminaste

- Los tres ejercicios con `forge test` sin error: `5 passed`, `6 passed` y `6 passed`, y la traza
  del paso 6 del ejercicio 01 seguida opcode a opcode.
- En tu repositorio, `bash test.sh` de `week-27/` acaba sin error, con los cinco tests de
  `test/evm/StorageMap.t.sol` en verde y los catorce mutantes muertos, y hay un pull request
  `week-27` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 26](../week-26-auditoria/5-glosario/README.md) | **Semana 27 — La EVM por dentro** | [Teoría 01 — La máquina de pila →](1-teoria/01-la-maquina-de-pila.md) |

← [Volver al índice del bootcamp](../README.md)
