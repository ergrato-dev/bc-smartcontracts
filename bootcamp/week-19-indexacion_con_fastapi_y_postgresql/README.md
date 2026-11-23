# Semana 19 — Indexación con FastAPI y PostgreSQL

La página de la semana 18 lee el estado del contrato, pero hay preguntas que el contrato no
sabe contestar rápido: "todos los recursos de esta cuenta, ordenados, de 20 en 20", "qué pasó
ayer", "cuántas altas hubo este mes". Para eso se construye un **indexador**: un programa que lee
los eventos de la cadena una sola vez, los guarda en una base de datos y los sirve con una API.
Esta semana lo escribes en Python, con **uv** para las dependencias, **PostgreSQL** para los datos
y **FastAPI** para la API. Y aprendes lo que lo hace difícil: la cadena puede cambiar sus últimos
bloques (**reorg**), y un indexador que no lo nota guarda datos que ya no son verdad.

## 🎯 Objetivos de aprendizaje

- Explicar qué problema resuelve un indexador y por qué la cadena sigue siendo la fuente de
  verdad.
- Leer bloques y eventos por JSON-RPC desde Python y decodificar sus topics y su `data`.
- Gestionar un proyecto de Python con uv: `pyproject.toml`, `uv.lock`, `uv sync` y `uv run`.
- Guardar eventos en PostgreSQL con tipos que caben (`NUMERIC(78, 0)` para un `uint256`),
  claves que hacen la escritura idempotente y transacciones de todo o nada.
- Servir los datos con FastAPI: rutas, validación, modelos de respuesta, paginación y CORS.
- Detectar un reorg comparando hashes de bloque, deshacerlo y elegir cuántas confirmaciones
  esperar.
- Reconocer los riesgos: inyección SQL, etiquetas hostiles que tumban el indexador, números que
  JavaScript redondea, listas sin límite y datos de bloques que ya no existen.

## 📋 Prerrequisitos

[Semana 18](../week-18-dapp_con_react_y_wagmi/README.md) terminada: tu dApp en `week-18/`, en
`main`. Python se da por conocido (funciones, clases, `dataclass`, excepciones); SQL no: la
teoría 02 explica lo que usa.

La imagen del bootcamp trae Python 3.12, uv y PostgreSQL 16 desde esta semana: reconstrúyela
antes de empezar (`docker build -t bc-smartcontracts-dev docker`).

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — Por qué indexar](1-teoria/01-por-que-indexar.md) | 45 min |
| 2 | [Teoría 02 — Eventos en PostgreSQL](1-teoria/02-eventos-en-postgresql.md) | 45 min |
| 3 | [Teoría 03 — Una API con FastAPI](1-teoria/03-una-api-con-fastapi.md) | 45 min |
| 4 | [Teoría 04 — Reorgs y confirmaciones](1-teoria/04-reorgs-y-confirmaciones.md) | 45 min |
| 5 | [Ejercicio 01 — Eventos desde Python](2-practicas/ejercicio-01-eventos-desde-python/README.md) | 1 h 30 min |
| 6 | [Ejercicio 02 — Guardar en PostgreSQL](2-practicas/ejercicio-02-guardar-en-postgresql/README.md) | 2 h 30 min |
| 7 | [Ejercicio 03 — API con FastAPI](2-practicas/ejercicio-03-api-con-fastapi/README.md) | 2 h |
| 8 | [Proyecto — El indexador del protocolo](3-proyecto/README.md) | 4 h |
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

- Los tres ejercicios: `bash test.sh` con `5 passed`.
- En tu repositorio, `bash test.sh` de `week-19/` acaba en `10 passed`. Tu indexador sigue a tu
  Registry en anvil, sobrevive a un reorg y su API responde `/items` con tus recursos. Hay un
  pull request `week-19` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 18](../week-18-dapp_con_react_y_wagmi/5-glosario/README.md) | **Semana 19 — Indexación con FastAPI y PostgreSQL** | [Teoría 01 — Por qué indexar →](1-teoria/01-por-que-indexar.md) |

← [Volver al índice del bootcamp](../README.md)
