# Semana 09 — Testing con Foundry

Hasta ahora los tests venían escritos y tú escribías el contrato. Esta semana es al revés:
los contratos están terminados y escribes tú las pruebas. Aprendes a mandar sobre quién
llama, cuánto ETH hay y qué hora es; a exigir un revert, un evento o una llamada concretos;
a probar reglas con cientos de entradas aleatorias (fuzzing); a probar contra una copia de
una red en marcha (fork); y a medir el gas y la cobertura de tus tests. En el proyecto, tu
registro recibe pruebas que detectan fallos que sus 44 tests de ejemplo dejan pasar.

## 🎯 Objetivos de aprendizaje

- Usar los cheatcodes de forge para fijar la cuenta, el saldo, la hora y el bloque de un
  test, y leer su traza.
- Exigir con `expectRevert`, `expectEmit` y `expectCall` lo que debe pasar en una llamada.
- Escribir propiedades con fuzzing, acotar sus entradas con `bound` y `vm.assume` y leer
  un contraejemplo.
- Probar un contrato desplegado sobre un fork de anvil y moverlo de bloque.
- Medir el gas con informes, `forge snapshot` y `snapshotGasLastFrame`, y la cobertura con
  `forge coverage`.
- Reconocer los riesgos: expectativas que pasan por el motivo equivocado, rangos que
  esconden el fallo, forks sin bloque fijo y cobertura confundida con corrección.

## 📋 Prerrequisitos

[Semana 08](../week-08-herencia_interfaces_y_librerias/README.md) terminada: herencia,
interfaces y librerías. Tu repositorio `bc-smartcontracts-<dominio>` con el proyecto de la
semana 08 en `main`.

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — Cheatcodes](1-teoria/01-cheatcodes.md) | 40 min |
| 2 | [Teoría 02 — Reverts, eventos y llamadas](1-teoria/02-reverts-eventos-y-llamadas.md) | 35 min |
| 3 | [Teoría 03 — Fuzz testing](1-teoria/03-fuzz-testing.md) | 40 min |
| 4 | [Teoría 04 — Forks](1-teoria/04-forks.md) | 35 min |
| 5 | [Teoría 05 — Gas y cobertura](1-teoria/05-gas-y-cobertura.md) | 30 min |
| 6 | [Ejercicio 01 — Cheatcodes](2-practicas/ejercicio-01-cheatcodes/README.md) | 2 h |
| 7 | [Ejercicio 02 — Fuzz testing](2-practicas/ejercicio-02-fuzz/README.md) | 2 h |
| 8 | [Ejercicio 03 — Forks, gas y cobertura](2-practicas/ejercicio-03-forks-gas-y-cobertura/README.md) | 2 h |
| 9 | [Proyecto — Registro a prueba de fuzzing](3-proyecto/README.md) | 4 h |
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

- Los tres ejercicios: `forge test` en verde y sin warnings (el 03, también con
  `FORK_URL`).
- En tu repositorio, `forge test` de `week-09/` pasa 51 tests y salta el de fork, tus
  propiedades detectan los dos mutantes, el test de fork pasa contra tu despliegue en anvil,
  `.gas-snapshot` está versionado y hay un pull request `week-09` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 08](../week-08-herencia_interfaces_y_librerias/5-glosario/README.md) | **Semana 09 — Testing con Foundry** | [Teoría 01 — Cheatcodes →](1-teoria/01-cheatcodes.md) |

← [Volver al índice del bootcamp](../README.md)
