# Semana 26 — Auditoría

Durante cinco semanas has mirado tu protocolo con cinco técnicas: la revisión por clases de
vulnerabilidad, los ataques económicos, el análisis estático, las invariantes y la verificación
formal. Esta semana las juntas en un proceso: una **auditoría**, con su alcance fijado en un
commit, su **modelo de amenazas**, sus hallazgos con **severidad** y **prueba de concepto**, y un
**informe** que lee alguien que no escribió el código. Practicas las dos caras: la del auditor que
escribe el informe y la del atacante que resuelve un **CTF** en tu contenedor.

## 🎯 Objetivos de aprendizaje

- Recorrer las siete fases de una auditoría y fijar su alcance.
- Hacer el modelo de amenazas de un protocolo: actores, activos, fronteras y amenazas, cada una
  con su prueba.
- Convertir amenazas en tests y hallazgos en pruebas de concepto de Foundry.
- Dar a cada hallazgo una severidad con impacto y probabilidad, y separar los falsos positivos.
- Escribir un informe de auditoría completo, con revisión de correcciones y limitaciones.
- Saber qué hacer con un fallo en un contrato desplegado: divulgación responsable y bug bounties.

## 📋 Prerrequisitos

[Semana 25](../week-25-verificacion_formal/README.md) terminada: tu protocolo con specs de Halmos
y su informe, en `main`. Esta semana usa todo lo de la fase 5, la reentrancy entre funciones y el
DoS por envío de la semana 21, el redondeo de la semana 22, los inicializadores de la semana 15 y
las firmas de la semana 14.

La imagen del contenedor no cambia: es la de la semana 25.

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — Metodología de auditoría](1-teoria/01-metodologia-de-auditoria.md) | 45 min |
| 2 | [Teoría 02 — Modelado de amenazas](1-teoria/02-modelado-de-amenazas.md) | 45 min |
| 3 | [Teoría 03 — Hallazgos y severidad](1-teoria/03-hallazgos-y-severidad.md) | 50 min |
| 4 | [Teoría 04 — Informe y divulgación](1-teoria/04-informe-y-divulgacion.md) | 40 min |
| 5 | [Ejercicio 01 — Modelo de amenazas](2-practicas/ejercicio-01-modelo-de-amenazas/README.md) | 1 h 30 min |
| 6 | [Ejercicio 02 — Hallazgos con PoC](2-practicas/ejercicio-02-hallazgos-con-poc/README.md) | 2 h |
| 7 | [Ejercicio 03 — CTF local](2-practicas/ejercicio-03-ctf-local/README.md) | 2 h |
| 8 | [Proyecto — Informe de auditoría final](3-proyecto/README.md) | 4 h |
| 9 | [Rúbrica de evaluación](rubrica-evaluacion.md) (autoevaluación) | 30 min |
| 10 | [Ebooks](4-recursos/ebooks-free/README.md), [videos](4-recursos/videografia/README.md), [webgrafía](4-recursos/webgrafia/README.md) y [glosario](5-glosario/README.md) | 30 min |

## ⏱️ Distribución del tiempo (14 h)

| Parte | Tiempo |
| ----- | ------ |
| Teoría | 3 h |
| Prácticas | 5 h 30 min |
| Proyecto | 4 h |
| Autoevaluación, recursos y glosario | 1 h |
| Margen para el informe | 30 min |

## ✅ Cómo saber que terminaste

- Los tres ejercicios con `forge test` sin error: `5 passed`, `5 passed` y `4 passed`, y el
  `FINDINGS.md` del ejercicio 02 con los cuatro hallazgos y el falso positivo.
- En tu repositorio, `bash test.sh` de `week-26/` acaba sin error, empezando por
  `✅ informe: ...` y terminando con los doce mutantes muertos. `week-26/audit/README.md` es un
  informe completo, y hay un pull request `week-26` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 25](../week-25-verificacion_formal/5-glosario/README.md) | **Semana 26 — Auditoría** | [Teoría 01 — Metodología de auditoría →](1-teoria/01-metodologia-de-auditoria.md) |

← [Volver al índice del bootcamp](../README.md)
