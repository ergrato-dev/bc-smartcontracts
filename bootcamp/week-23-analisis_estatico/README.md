# Semana 23 — Análisis estático

Las semanas 21 y 22 buscaron fallos leyendo el código con una lista de preguntas y escribiendo
ataques. Esta semana añade programas que leen el código por ti, sin ejecutarlo: **Slither**, el
analizador de Trail of Bits, y **forge lint**, el linter de Foundry. Aprendes a leer lo que dicen,
a decidir si cada aviso es un fallo, un falso positivo o un riesgo que aceptas, y a escribir esa
decisión en el código. Después escribes tus propias reglas en Python sobre Slither. En tu
protocolo, los analizadores dan sobre todo falsos positivos, como corresponde a un código ya
revisado, y un aviso que no lo es: el alta con puntos llama al token antes de escribir el alta.

## 🎯 Objetivos de aprendizaje

- Explicar cómo un analizador estático va del código al hallazgo, y por qué da falsos positivos
  y falsos negativos.
- Ejecutar Slither sobre un proyecto Foundry, leer cada hallazgo y configurarlo con
  `slither.config.json` para que falle en un script.
- Ejecutar y configurar `forge lint`, y combinar sus comentarios de silencio con los de Slither.
- Triajar cada hallazgo como verdadero, falso positivo o aceptado, y justificarlo en su línea.
- Reconocer lo que ninguna herramienta encuentra: la lógica del negocio y la economía.
- Escribir un detector de Slither en Python, probarlo con pytest y ejecutarlo como un control.
- Añadir al informe de auditoría el análisis estático de tu protocolo y el hallazgo H-03.

## 📋 Prerrequisitos

[Semana 22](../week-22-vulnerabilidades_economicas/README.md) terminada: tu registro con H-01 y
H-02 corregidos y el informe de auditoría, en `main`. Del resto del bootcamp, esta semana usa
sobre todo las vulnerabilidades clásicas de la semana 21, que es lo que los analizadores buscan,
y Python con pytest (semana 19).

La imagen del contenedor trae Slither desde esta semana. Si la construiste antes, reconstrúyela:

```bash
docker build -t bc-smartcontracts-dev docker
```

**Verifica**: dentro del contenedor, `slither --version` imprime `0.11.5`.

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — Qué es el análisis estático](1-teoria/01-que-es-el-analisis-estatico.md) | 40 min |
| 2 | [Teoría 02 — Slither](1-teoria/02-slither.md) | 50 min |
| 3 | [Teoría 03 — forge lint](1-teoria/03-forge-lint.md) | 35 min |
| 4 | [Teoría 04 — Detectores propios](1-teoria/04-detectores-propios.md) | 55 min |
| 5 | [Ejercicio 01 — Slither](2-practicas/ejercicio-01-slither/README.md) | 2 h |
| 6 | [Ejercicio 02 — forge lint](2-practicas/ejercicio-02-forge-lint/README.md) | 1 h 30 min |
| 7 | [Ejercicio 03 — Detector propio](2-practicas/ejercicio-03-detector-propio/README.md) | 2 h 30 min |
| 8 | [Proyecto — Análisis estático de tu protocolo](3-proyecto/README.md) | 4 h |
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

- Los ejercicios con `bash test.sh` sin error: Slither con `0 result(s) found`, `forge lint` sin
  avisos y `3 passed` en los tests del detector.
- En tu repositorio, `bash test.sh` de `week-23/` acaba sin error: tests, `forge lint`, Slither y
  tu detector en verde. `week-23/audit/README.md` tiene el análisis estático y el hallazgo H-03, y
  hay un pull request `week-23` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 22](../week-22-vulnerabilidades_economicas/5-glosario/README.md) | **Semana 23 — Análisis estático** | [Teoría 01 — Qué es el análisis estático →](1-teoria/01-que-es-el-analisis-estatico.md) |

← [Volver al índice del bootcamp](../README.md)
