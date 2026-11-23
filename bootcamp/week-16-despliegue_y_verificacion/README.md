# Semana 16 — Despliegue y verificación

Hasta ahora tus contratos vivían en anvil, en tu máquina, firmados con claves que conoce todo el
mundo. Esta semana salen a una red pública. Escribirás el despliegue como un **script** de
Foundry, probado con tests y simulado antes de enviar nada; guardarás tu clave en un
**keystore** cifrado; desplegarás en **Sepolia**, la testnet de Ethereum; y **verificarás** los
contratos para que cualquiera pueda leer su código en el explorador. En el proyecto, tu
protocolo completo queda desplegado, verificado y actualizado a V2 en Sepolia.

## 🎯 Objetivos de aprendizaje

- Escribir y probar un script de despliegue con `Script`, `vm.startBroadcast()` y
  `vm.readCallers()`.
- Distinguir ejecutar, simular (`--rpc-url`) y emitir (`--broadcast`), y leer el registro de
  `broadcast/`.
- Guardar una clave en un keystore y firmar con `--account`, sin claves en comandos ni en `.env`.
- Conectarte a Sepolia con un alias de red, conseguir ETH de un faucet y simular contra la red
  real.
- Explicar qué demuestra una verificación y verificar con `--verify` y `forge verify-contract`.
- Reconocer los riesgos: claves expuestas, cuentas de anvil en redes públicas, emitir sin
  simular y verificar con otros ajustes.

## 📋 Prerrequisitos

[Semana 15](../week-15-contratos_actualizables/README.md) terminada: contratos actualizables.
Tu repositorio `bc-smartcontracts-<dominio>` con el proyecto de la semana 15 en `main`.

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — forge script](1-teoria/01-forge-script.md) | 50 min |
| 2 | [Teoría 02 — Claves y keystores](1-teoria/02-claves-y-keystores.md) | 40 min |
| 3 | [Teoría 03 — Testnets y Sepolia](1-teoria/03-testnets-y-sepolia.md) | 40 min |
| 4 | [Teoría 04 — Verificación](1-teoria/04-verificacion.md) | 50 min |
| 5 | [Ejercicio 01 — Primer script](2-practicas/ejercicio-01-primer-script/README.md) | 2 h |
| 6 | [Ejercicio 02 — Keystore y broadcast](2-practicas/ejercicio-02-keystore-y-broadcast/README.md) | 2 h |
| 7 | [Ejercicio 03 — Verificación por dentro](2-practicas/ejercicio-03-verificacion-por-dentro/README.md) | 2 h |
| 8 | [Proyecto — Despliegue en Sepolia](3-proyecto/README.md) | 4 h |
| 9 | [Rúbrica de evaluación](rubrica-evaluacion.md) (autoevaluación) | 30 min |
| 10 | [Ebooks](4-recursos/ebooks-free/README.md), [videos](4-recursos/videografia/README.md), [webgrafía](4-recursos/webgrafia/README.md) y [glosario](5-glosario/README.md) | 30 min |

## ⏱️ Distribución del tiempo (14 h)

| Parte | Tiempo |
| ----- | ------ |
| Teoría | 3 h |
| Prácticas | 6 h |
| Proyecto | 4 h |
| Autoevaluación, recursos y glosario | 1 h |

## ✅ Cómo saber que terminaste

- Ejercicio 01: `forge test --deny warnings` en verde (6 tests). Ejercicios 02 y 03:
  `bash test.sh` con 6 de 6 y 7 de 7 pasos.
- En tu repositorio, `forge test` de `week-16/` pasa 152 tests y salta el de fork; tu protocolo
  está en Sepolia, desplegado desde tu keystore, verificado en Sourcify, con un alta real y
  actualizado a V2; el test de fork pasa contra Sepolia y hay un pull request `week-16` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 15](../week-15-contratos_actualizables/5-glosario/README.md) | **Semana 16 — Despliegue y verificación** | [Teoría 01 — forge script →](1-teoria/01-forge-script.md) |

← [Volver al índice del bootcamp](../README.md)
