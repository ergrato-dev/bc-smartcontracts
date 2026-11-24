# Semana 28 — Yul e inline assembly

En la semana 27 leíste el bytecode que genera solc. Esta semana lo escribes casi a ese nivel con
**Yul**: el lenguaje intermedio de solc, con variables, funciones y bucles, pero con opcodes como
operaciones y sin ninguna de las comprobaciones de Solidity. Lo usas de dos formas: un contrato
entero en Yul y, sobre todo, bloques de **inline assembly** dentro de Solidity. Aprendes qué ve un
bloque de las variables de Solidity, qué reglas de memoria tiene que respetar, cómo llamar a otros
contratos copiando solo lo que necesitas, y cómo probar y auditar un código que ningún compilador
comprueba. En el proyecto reescribes en assembly la llamada al hook de tu registro para que una
return bomb deje de costarle gas a quien registra.

## 🎯 Objetivos de aprendizaje

- Escribir Yul: `let`, `:=`, opcodes, `if`, `switch`, `for`, funciones y `leave`, y un objeto Yul
  con su código de despliegue y su runtime.
- Usar las variables de Solidity desde assembly: valores, punteros de memoria, `.slot`,
  `.offset` y `.length`.
- Respetar la memoria de Solidity: scratch space, puntero de memoria libre y `memory-safe`; y
  limpiar los bits sucios.
- Usar storage y transient storage desde assembly, también en un espacio de nombres ERC-7201.
- Llamar, revertir, propagar errores y desplegar desde assembly, comprobando lo que Solidity
  comprobaría.
- Probar assembly con tests diferenciales, Halmos y mutantes, y revisarlo con una lista fija.

## 📋 Prerrequisitos

[Semana 27](../week-27-evm_por_dentro/README.md) terminada: tu protocolo con su mapa de storage,
en `main`. Esta semana usa los opcodes, la memoria, el storage y la returndata de la semana 27, la
reentrancy y la return bomb de la semana 21, el fuzzing de las semanas 09 y 24, Halmos de la
semana 25 y `create2` de la semana 10.

La imagen del contenedor no cambia: es la de la semana 25.

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — Yul, el lenguaje](1-teoria/01-yul-el-lenguaje.md) | 45 min |
| 2 | [Teoría 02 — Assembly dentro de Solidity](1-teoria/02-assembly-dentro-de-solidity.md) | 50 min |
| 3 | [Teoría 03 — Llamadas, errores y despliegues](1-teoria/03-llamadas-errores-y-despliegues.md) | 45 min |
| 4 | [Teoría 04 — Probar y auditar assembly](1-teoria/04-probar-y-auditar-assembly.md) | 40 min |
| 5 | [Ejercicio 01 — Yul paso a paso](2-practicas/ejercicio-01-yul-paso-a-paso/README.md) | 1 h 30 min |
| 6 | [Ejercicio 02 — Memoria y storage en assembly](2-practicas/ejercicio-02-memoria-y-storage-en-assembly/README.md) | 2 h |
| 7 | [Ejercicio 03 — Llamadas en assembly](2-practicas/ejercicio-03-llamadas-en-assembly/README.md) | 2 h |
| 8 | [Proyecto — La llamada al hook en assembly](3-proyecto/README.md) | 4 h |
| 9 | [Rúbrica de evaluación](rubrica-evaluacion.md) (autoevaluación) | 30 min |
| 10 | [Ebooks](4-recursos/ebooks-free/README.md), [videos](4-recursos/videografia/README.md), [webgrafía](4-recursos/webgrafia/README.md) y [glosario](5-glosario/README.md) | 30 min |

## ⏱️ Distribución del tiempo (14 h)

| Parte | Tiempo |
| ----- | ------ |
| Teoría | 3 h |
| Prácticas | 5 h 30 min |
| Proyecto | 4 h |
| Autoevaluación, recursos y glosario | 1 h |
| Margen para el informe del proyecto | 30 min |

## ✅ Cómo saber que terminaste

- Los tres ejercicios con `forge test` sin error: `9 tests passed`, `6 tests passed` y
  `11 tests passed`, y has visto fallar cada paso al quitar la comprobación que pide su README.
- En tu repositorio, `bash test.sh` de `week-28/` acaba sin error, con los cinco tests de
  `test/asm/HookCall.t.sol` en verde y los diecisiete mutantes muertos, y hay un pull request
  `week-28` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 27](../week-27-evm_por_dentro/5-glosario/README.md) | **Semana 28 — Yul e inline assembly** | [Teoría 01 — Yul, el lenguaje →](1-teoria/01-yul-el-lenguaje.md) |

← [Volver al índice del bootcamp](../README.md)
