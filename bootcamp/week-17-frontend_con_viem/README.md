# Semana 17 — Frontend con viem

Hasta ahora hablabas con tus contratos desde la terminal, con `cast` y `forge`. Quien use tu
protocolo no va a abrir una terminal: usará una página. Esta semana escribes el código que esa
página necesita. Usarás **TypeScript**, ejecutado con Node, y **viem**, una biblioteca que
habla con el nodo por JSON-RPC como hacía `cast`. Con viem vas a **leer** estado, **escribir**
transacciones simuladas antes de enviarlas y **escuchar** eventos. **Vite** sirve la página en
el navegador. En el proyecto, tu protocolo tiene su primera página: muestra el estado del
registro, da de alta y retira recursos, explica los errores y sigue la actividad en vivo.

## 🎯 Objetivos de aprendizaje

- Ejecutar TypeScript con Node y comprobar sus tipos con `tsc`, con dependencias fijadas por
  pnpm.
- Crear clientes de viem (público y de cartera) y leer bloques, saldos y funciones `view`.
- Pasar entre `bigint`, `number` y texto con `formatUnits` y `parseUnits` sin perder precisión.
- Escribir con el flujo simular → enviar → esperar el recibo, y decodificar el error de un
  revert.
- Leer el historial de eventos, filtrar por campos `indexed`, sacar eventos de un recibo y
  escuchar los nuevos.
- Servir una página con Vite que lee y escribe en anvil y solo lee en Sepolia.
- Reconocer los riesgos: claves en el código de la página, variables `VITE_` públicas, texto de
  la cadena pintado como HTML y enviar sin simular.

## 📋 Prerrequisitos

[Semana 16](../week-16-despliegue_y_verificacion/README.md) terminada: tu protocolo desplegado
y verificado en Sepolia. Tu repositorio `bc-smartcontracts-<dominio>` con `week-16/` en `main`.

La imagen del bootcamp trae Node y pnpm desde esta semana: reconstrúyela antes de empezar
(`docker build -t bc-smartcontracts-dev docker`).

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — De cast a TypeScript](1-teoria/01-de-cast-a-typescript.md) | 35 min |
| 2 | [Teoría 02 — Leer con viem](1-teoria/02-leer-con-viem.md) | 40 min |
| 3 | [Teoría 03 — Escribir con viem](1-teoria/03-escribir-con-viem.md) | 40 min |
| 4 | [Teoría 04 — Eventos y logs](1-teoria/04-eventos-y-logs.md) | 35 min |
| 5 | [Teoría 05 — La página con Vite](1-teoria/05-la-pagina-con-vite.md) | 30 min |
| 6 | [Ejercicio 01 — Leer la cadena](2-practicas/ejercicio-01-leer-la-cadena/README.md) | 2 h |
| 7 | [Ejercicio 02 — Escribir transacciones](2-practicas/ejercicio-02-escribir-transacciones/README.md) | 2 h |
| 8 | [Ejercicio 03 — Escuchar eventos](2-practicas/ejercicio-03-escuchar-eventos/README.md) | 2 h |
| 9 | [Proyecto — La página del protocolo](3-proyecto/README.md) | 4 h |
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

- Ejercicios 01, 02 y 03: `bash test.sh` con 5 de 5 tests en verde y `✔ sin errores de tipos`.
- En tu repositorio, `bash test.sh` de `week-17/` pasa 9 de 9 tests, con `tsc` y `vite build`
  sin errores. Tu página da de alta y retira en anvil y lee tu registro de Sepolia. Hay un pull
  request `week-17` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 16](../week-16-despliegue_y_verificacion/5-glosario/README.md) | **Semana 17 — Frontend con viem** | [Teoría 01 — De cast a TypeScript →](1-teoria/01-de-cast-a-typescript.md) |

← [Volver al índice del bootcamp](../README.md)
