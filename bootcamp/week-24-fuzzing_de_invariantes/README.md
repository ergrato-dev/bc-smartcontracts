# Semana 24 — Fuzzing de invariantes

Las semanas 21 a 23 buscaron fallos con una lista de preguntas, con ataques escritos a mano y con
analizadores que leen el código. Esta semana el código se ejecuta en secuencias que nadie
escribió: un **fuzzer** llama a tus contratos cientos de miles de veces, en cualquier orden y con
cualquier valor, y comprueba tras cada llamada lo que tiene que ser verdad siempre, sus
**invariantes**. Lo haces con el fuzzer de forge y con **Medusa**, el de Trail of Bits, sobre las
mismas propiedades. Aprendes a escribir el *handler* que hace útil una campaña y a comprobar con
**mutantes** que tus invariantes de verdad atrapan fallos.

## 🎯 Objetivos de aprendizaje

- Explicar en qué se diferencia el fuzzing con estado del de la semana 09, y qué demuestra una
  campaña en verde.
- Sacar las invariantes de un protocolo de lo que promete: conservación, contabilidad, límites.
- Escribir tests de invariantes con forge y leer su salida: secuencia encogida, tabla de llamadas
  y fallos guardados.
- Escribir un handler con cuentas, entradas acotadas, precondiciones y variables fantasma.
- Ejecutar Medusa sobre un harness compartido con forge, con propiedades y aserciones.
- Comprobar una suite con mutantes y escribir en el informe lo que no prueba.

## 📋 Prerrequisitos

[Semana 23](../week-23-analisis_estatico/README.md) terminada: tu protocolo con el análisis
estático, el detector propio y el informe de auditoría, en `main`. Del resto del bootcamp, esta
semana usa sobre todo los tests de fuzz y `bound` de la semana 09, y la bóveda de participaciones
de la semana 22.

La imagen del contenedor trae Medusa desde esta semana. Reconstrúyela:

```bash
docker build -t bc-smartcontracts-dev docker
```

**Verifica**: dentro del contenedor, `medusa --version` imprime `medusa version 1.5.0`. Medusa
solo publica binarios para Linux x64: en un Mac con Apple Silicon, la imagen arm64 no lo trae, y
el ejercicio 03 y el proyecto necesitan la imagen amd64 (`docker build --platform linux/amd64`).

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — Del fuzz a las invariantes](1-teoria/01-de-fuzz-a-invariantes.md) | 40 min |
| 2 | [Teoría 02 — Invariantes en Foundry](1-teoria/02-invariantes-en-foundry.md) | 45 min |
| 3 | [Teoría 03 — Handlers](1-teoria/03-handlers.md) | 55 min |
| 4 | [Teoría 04 — Medusa](1-teoria/04-medusa.md) | 40 min |
| 5 | [Ejercicio 01 — Invariantes](2-practicas/ejercicio-01-invariantes/README.md) | 1 h 30 min |
| 6 | [Ejercicio 02 — Handlers](2-practicas/ejercicio-02-handlers/README.md) | 2 h |
| 7 | [Ejercicio 03 — Medusa](2-practicas/ejercicio-03-medusa/README.md) | 1 h 30 min |
| 8 | [Proyecto — Invariantes de tu protocolo](3-proyecto/README.md) | 4 h |
| 9 | [Rúbrica de evaluación](rubrica-evaluacion.md) (autoevaluación) | 30 min |
| 10 | [Ebooks](4-recursos/ebooks-free/README.md), [videos](4-recursos/videografia/README.md), [webgrafía](4-recursos/webgrafia/README.md) y [glosario](5-glosario/README.md) | 30 min |

## ⏱️ Distribución del tiempo (14 h)

| Parte | Tiempo |
| ----- | ------ |
| Teoría | 3 h |
| Prácticas | 5 h |
| Proyecto | 4 h |
| Autoevaluación, recursos y glosario | 1 h |
| Margen para campañas largas | 1 h |

## ✅ Cómo saber que terminaste

- Los ejercicios 01 y 02 con `forge test` sin error, y el 03 con `bash test.sh`: forge y Medusa en
  verde.
- En tu repositorio, `bash test.sh` de `week-24/` acaba sin error, con los cuatro mutantes muertos.
  `week-24/audit/README.md` tiene la sección de fuzzing, y hay un pull request `week-24` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 23](../week-23-analisis_estatico/5-glosario/README.md) | **Semana 24 — Fuzzing de invariantes** | [Teoría 01 — Del fuzz a las invariantes →](1-teoria/01-de-fuzz-a-invariantes.md) |

← [Volver al índice del bootcamp](../README.md)
