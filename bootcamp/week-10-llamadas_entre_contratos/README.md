# Semana 10 — Llamadas entre contratos

Hasta ahora un contrato llamaba a otro a través de su interfaz y Solidity hacía el resto.
Esta semana ves qué hay debajo: los bytes de una llamada (codificación ABI), cómo llamar sin
revertir si el otro falla (`call`, `staticcall`, `try`/`catch`), cómo ejecutar código ajeno
sobre tu propio storage (`delegatecall`) y cómo desplegar contratos desde un contrato,
sabiendo su dirección de antemano (`CREATE` y `CREATE2`). En el proyecto, tu registro avisa
de cada alta a otro contrato sin depender de él.

## 🎯 Objetivos de aprendizaje

- Leer y construir los bytes de una llamada con `abi.encodeCall`, y decodificarlos con
  `abi.decode` y `cast`.
- Llamar con `call` y `staticcall`, leer su `(bool, bytes)` y limitar su gas.
- Explicar qué cambia con `delegatecall` y escribir un `multicall` seguro.
- Llamar con `try`/`catch`, distinguir los tipos de error y saber qué no atrapa.
- Desplegar con `new` y con `CREATE2`, y predecir la dirección antes de desplegar.
- Reconocer los riesgos: cuentas sin código, storage que no coincide, `msg.value` contado
  dos veces, oyentes que gastan todo el gas y salts que otro puede ocupar.

## 📋 Prerrequisitos

[Semana 09](../week-09-testing_con_foundry/README.md) terminada: cheatcodes, fuzzing,
forks y gas. Tu repositorio `bc-smartcontracts-<dominio>` con el proyecto de la semana 09
en `main`.

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — Codificación ABI](1-teoria/01-codificacion-abi.md) | 35 min |
| 2 | [Teoría 02 — call y staticcall](1-teoria/02-call-y-staticcall.md) | 40 min |
| 3 | [Teoría 03 — delegatecall](1-teoria/03-delegatecall.md) | 35 min |
| 4 | [Teoría 04 — try/catch](1-teoria/04-try-catch.md) | 35 min |
| 5 | [Teoría 05 — CREATE y CREATE2](1-teoria/05-create-y-create2.md) | 35 min |
| 6 | [Ejercicio 01 — ABI y llamadas de bajo nivel](2-practicas/ejercicio-01-abi-y-llamadas/README.md) | 2 h |
| 7 | [Ejercicio 02 — delegatecall y try/catch](2-practicas/ejercicio-02-delegatecall-y-try-catch/README.md) | 2 h |
| 8 | [Ejercicio 03 — CREATE y CREATE2](2-practicas/ejercicio-03-create-y-create2/README.md) | 2 h |
| 9 | [Proyecto — Registro conectado](3-proyecto/README.md) | 4 h |
| 10 | [Rúbrica de evaluación](rubrica-evaluacion.md) (autoevaluación) | 30 min |
| 11 | [Ebooks](4-recursos/ebooks-free/README.md), [videos](4-recursos/videografia/README.md), [webgrafía](4-recursos/webgrafia/README.md) y [glosario](5-glosario/README.md) | 30 min |

## ⏱️ Distribución del tiempo (14 h)

| Parte | Tiempo |
| ----- | ------ |
| Teoría | 3 h |
| Prácticas | 6 h |
| Proyecto | 4 h |
| Autoevaluación, recursos y glosario | 1 h |

## ✅ Cómo saber que terminaste

- Los tres ejercicios: `forge test --deny warnings` en verde (6, 8 y 7 tests).
- En tu repositorio, `forge test` de `week-10/` pasa 68 tests y salta el de fork; el
  registro avisa a sus puntos en anvil, el test de fork pasa contra ese despliegue,
  `.gas-snapshot` está actualizado y hay un pull request `week-10` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 09](../week-09-testing_con_foundry/5-glosario/README.md) | **Semana 10 — Llamadas entre contratos** | [Teoría 01 — Codificación ABI →](1-teoria/01-codificacion-abi.md) |

← [Volver al índice del bootcamp](../README.md)
