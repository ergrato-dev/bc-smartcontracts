# Semana 34 — Integración final y auditoría cruzada

La última semana. Tu protocolo está completo, y esta semana lo cierras como se cierra un protocolo
de verdad. Primero lo miras **entero**: qué contratos hay en cada cadena, quién administra cada uno
y cómo comprobar que un despliegue dejó cada rol donde debía. Después cambias de lado: **auditas el
código de otra persona**, con un método y una prueba de concepto por hallazgo, y **corriges** lo
que otra persona encuentre en el tuyo, revisando que la corrección no rompa otra cosa. Y por
último lo **entregas**: una versión etiquetada, un README de portfolio, una demo y lo que hace falta
para mantenerlo vivo después.

## 🎯 Objetivos de aprendizaje

- Comprobar un despliegue con lecturas: quién manda, que nadie más mande y que todo esté conectado.
- Auditar código ajeno con un método: alcance y commit, tabla de funciones, hipótesis, prueba de
  concepto, severidad e informe.
- Responder un informe de auditoría: corregir con tests de regresión, reconocer o disputar, y
  revisar cada corrección.
- Entregar una versión del protocolo con su README, su demo, su `SECURITY.md` y su plan de
  incidentes.
- Reconocer los riesgos: despliegues que no fallan pero están mal, hallazgos sin prueba,
  correcciones incompletas y fallos publicados antes de corregirse.

## 📋 Prerrequisitos

[Semana 33](../week-33-l2_y_cross_chain/README.md) terminada: tu protocolo en L1 y en una L2, en
`main`. El instructor te asigna una **pareja de auditoría** el primer día: la auditoría cruzada
necesita días de margen, así que empiézala antes que el resto (ver el calendario del proyecto).

Esta semana usa todo lo anterior, en especial los scripts de la 16, el indexador de la 19, las
clases de vulnerabilidades de la 21 y la 22, el informe de auditoría de la 26, la DAO de la 31 y la
L2 de la 33.

La imagen del contenedor no cambia.

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — El protocolo completo](1-teoria/01-el-protocolo-completo.md) | 45 min |
| 2 | [Teoría 02 — Auditoría cruzada](1-teoria/02-auditoria-cruzada.md) | 50 min |
| 3 | [Teoría 03 — Corregir hallazgos](1-teoria/03-corregir-hallazgos.md) | 40 min |
| 4 | [Teoría 04 — Entregar y mantener](1-teoria/04-entregar-y-mantener.md) | 45 min |
| 5 | [Ejercicio 01 — Un despliegue que se comprueba](2-practicas/ejercicio-01-un-despliegue-que-se-comprueba/README.md) | 1 h 30 min |
| 6 | [Ejercicio 02 — Auditar código ajeno](2-practicas/ejercicio-02-auditar-codigo-ajeno/README.md) | 2 h |
| 7 | [Ejercicio 03 — Corregir y revisar](2-practicas/ejercicio-03-corregir-y-revisar/README.md) | 2 h |
| 8 | [Proyecto — La entrega final](3-proyecto/README.md) | 4 h |
| 9 | [Rúbrica de evaluación](rubrica-evaluacion.md) (autoevaluación) | 30 min |
| 10 | [Ebooks](4-recursos/ebooks-free/README.md), [videos](4-recursos/videografia/README.md), [webgrafía](4-recursos/webgrafia/README.md) y [glosario](5-glosario/README.md) | 30 min |

## ⏱️ Distribución del tiempo (14 h)

| Parte | Tiempo |
| ----- | ------ |
| Teoría | 3 h |
| Prácticas | 5 h 30 min |
| Proyecto | 4 h |
| Autoevaluación, recursos y glosario | 1 h |
| Margen para la auditoría cruzada | 30 min |

## ✅ Cómo saber que terminaste

- Los tres ejercicios con `forge test` sin error: `15 tests passed`, `6 tests passed` y
  `7 tests passed`.
- En tu repositorio, `bash test.sh` de `week-34/` acaba sin error, con los catorce tests de
  `test/final/Final.t.sol` y los de `test/cross/` en verde y los cuarenta y tres mutantes muertos.
- Tu pareja tiene tu `auditoria-cruzada.md`, tú respondiste la suya, y `main` lleva la etiqueta
  `v1.0.0`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

## 🎓 Y después

Has llegado de cero en blockchain a un protocolo desplegado en dos cadenas, gobernado por una DAO,
auditado por ti y por otra persona. Lo que sigue depende de ti: concursos de auditoría públicos
(Code4rena, Sherlock, Cantina) para entrenar la teoría 02 con código real, programas de
recompensas por fallos, o contribuir a los proyectos de código abierto que has usado (Foundry,
OpenZeppelin, Slither). El repositorio que entregas hoy es tu carta de presentación.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 33](../week-33-l2_y_cross_chain/5-glosario/README.md) | **Semana 34 — Integración final y auditoría cruzada** | [Teoría 01 — El protocolo completo →](1-teoria/01-el-protocolo-completo.md) |

← [Volver al índice del bootcamp](../README.md)
