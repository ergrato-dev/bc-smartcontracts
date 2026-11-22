# Semana 08 — Herencia, interfaces y librerías

Tu registro de la semana 07 cobra, emite eventos y paga, pero es un solo bloque: el dueño,
la apertura y la regla de las etiquetas están escritos dentro, y nadie puede usarlo desde
otro contrato sin copiar sus firmas. Esta semana aprendes a heredar de otros contratos, a
sustituir lo que heredas sin perder sus comprobaciones, a dejar huecos que rellena un hijo,
a publicar una interfaz y a sacar código reutilizable a librerías. En el proyecto, el
registro se parte en piezas sin cambiar lo que hace.

## 🎯 Objetivos de aprendizaje

- Heredar con `is`, pasar argumentos a los constructores de los padres y saber qué recibe
  el hijo.
- Sustituir funciones con `virtual` y `override`, llamar al padre con `super` y predecir
  la linealización con herencia múltiple.
- Escribir contratos `abstract` con huecos que completan los hijos.
- Declarar interfaces, llamar a otro contrato a través de una y responder ERC-165.
- Escribir librerías `internal` y usarlas con `using for`, también sobre storage.
- Reconocer los riesgos: `override` sin `super`, padres que no leíste, interfaces que no
  garantizan el comportamiento y redondeo en los cálculos.

## 📋 Prerrequisitos

[Semana 07](../week-07-eventos_y_ether/README.md) terminada: eventos, `payable`, envío de
ETH y checks-effects-interactions. Tu repositorio `bc-smartcontracts-<dominio>` con el
proyecto de la semana 07 en `main`.

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — Herencia](1-teoria/01-herencia.md) | 35 min |
| 2 | [Teoría 02 — `virtual`, `override` y `super`](1-teoria/02-virtual-override-y-super.md) | 40 min |
| 3 | [Teoría 03 — Contratos abstractos](1-teoria/03-contratos-abstractos.md) | 30 min |
| 4 | [Teoría 04 — Interfaces](1-teoria/04-interfaces.md) | 40 min |
| 5 | [Teoría 05 — Librerías](1-teoria/05-librerias.md) | 35 min |
| 6 | [Ejercicio 01 — Herencia](2-practicas/ejercicio-01-herencia/README.md) | 2 h |
| 7 | [Ejercicio 02 — Interfaces y contratos abstractos](2-practicas/ejercicio-02-interfaces/README.md) | 2 h |
| 8 | [Ejercicio 03 — Librerías](2-practicas/ejercicio-03-librerias/README.md) | 2 h |
| 9 | [Proyecto — Registro modular](3-proyecto/README.md) | 4 h |
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
- En tu repositorio, `forge test` de `week-08/` pasa los 44 tests del proyecto, el
  contrato está desplegado en anvil con un error de cada pieza probado y hay un pull
  request `week-08` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 07](../week-07-eventos_y_ether/5-glosario/README.md) | **Semana 08 — Herencia, interfaces y librerías** | [Teoría 01 — Herencia →](1-teoria/01-herencia.md) |

← [Volver al índice del bootcamp](../README.md)
