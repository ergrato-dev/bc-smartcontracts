# Semana 07 — Eventos y ether

En la semana 06 tu registro aprendió a guardar datos con forma, pero seguía siendo mudo y
gratis: nadie fuera del contrato se enteraba de lo que pasaba sin preguntarle, y el ETH no
entraba ni salía. Esta semana aprendes a emitir eventos que dApps e indexadores pueden
leer, a escribir importes y plazos con sus unidades, a usar las variables del bloque y de
la transacción, y a recibir y enviar ETH sin perderlo por el camino. En el proyecto,
registrar cuesta una tasa, cada cambio deja un evento y el dueño retira lo recaudado.

## 🎯 Objetivos de aprendizaje

- Declarar y emitir eventos, leerlos en el recibo y con `cast logs`, y elegir qué
  parámetros son `indexed`.
- Escribir importes con `wei`, `gwei` y `ether` y plazos con `days`, y usar `msg` y
  `block`.
- Cobrar con funciones `payable` y decidir qué hacen `receive` y `fallback`.
- Enviar ETH con `call`, comprobar el resultado y ordenar el código en
  checks-effects-interactions.
- Preferir pagos *pull* a *push* y llevar la contabilidad sin fiarse del saldo.
- Reconocer los riesgos: reentrada, ETH bloqueado, receptores que revierten, ETH forzado y
  `tx.origin`.

## 📋 Prerrequisitos

[Semana 06](../week-06-estructuras_de_datos/README.md) terminada: mappings, structs,
enums, arrays y `storage`/`memory`/`calldata`. Tu repositorio
`bc-smartcontracts-<dominio>` con el proyecto de la semana 06 en `main`.

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — Eventos y logs](1-teoria/01-eventos-y-logs.md) | 35 min |
| 2 | [Teoría 02 — Unidades y variables globales](1-teoria/02-unidades-y-variables-globales.md) | 30 min |
| 3 | [Teoría 03 — Recibir ETH](1-teoria/03-recibir-ether.md) | 40 min |
| 4 | [Teoría 04 — Enviar ETH](1-teoria/04-enviar-ether.md) | 40 min |
| 5 | [Teoría 05 — Pagos seguros](1-teoria/05-pagos-seguros.md) | 35 min |
| 6 | [Ejercicio 01 — Eventos](2-practicas/ejercicio-01-eventos/README.md) | 1 h 30 min |
| 7 | [Ejercicio 02 — Recibir ETH](2-practicas/ejercicio-02-recibir-ether/README.md) | 2 h |
| 8 | [Ejercicio 03 — Enviar ETH](2-practicas/ejercicio-03-enviar-ether/README.md) | 2 h 30 min |
| 9 | [Proyecto — Registro con tasas y eventos](3-proyecto/README.md) | 4 h |
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

- Los tres ejercicios: `forge test` en verde y sin warnings.
- En tu repositorio, `forge test` de `week-07/` pasa los 37 tests del proyecto, el
  contrato está desplegado en anvil con sus tres errores probados y hay un pull request
  `week-07` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 06](../week-06-estructuras_de_datos/5-glosario/README.md) | **Semana 07 — Eventos y ether** | [Teoría 01 — Eventos y logs →](1-teoria/01-eventos-y-logs.md) |

← [Volver al índice del bootcamp](../README.md)
