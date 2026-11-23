# Semana 15 — Contratos actualizables

El código de un contrato desplegado no cambia nunca. Esta semana aprendes a cambiarlo sin
cambiar su dirección: un **proxy** guarda el estado y reenvía cada llamada con `delegatecall`
a una **implementación**, y actualizar es apuntar a otra. Escribirás un proxy a mano para ver
todas sus piezas, y después usarás los de OpenZeppelin, transparent y UUPS. Verás los tres
riesgos que trae: el orden del storage entre versiones, el constructor que el proxy no
ejecuta y quién tiene el poder de cambiar el código. En el proyecto, tu registro pasa a vivir
detrás de un proxy UUPS y recibe una versión 2 sin perder nada.

## 🎯 Objetivos de aprendizaje

- Explicar cómo un proxy separa el estado del código con `fallback` y `delegatecall`.
- Guardar la implementación en el slot de EIP-1967 y leerla con `cast storage`.
- Comparar layouts con `forge inspect` y escribir una V2 compatible con la V1.
- Sustituir el constructor por `initialize`, cerrar la implementación e inicializar una V2
  con `reinitializer`.
- Desplegar y actualizar un proxy transparent (con su `ProxyAdmin`) y uno UUPS (con
  `_authorizeUpgrade`).
- Reconocer los riesgos: colisiones de storage, implementaciones sin inicializar,
  `initialize` adelantado, choque de selectores y un `_authorizeUpgrade` sin control.

## 📋 Prerrequisitos

[Semana 14](../week-14-firmas_eip712_y_permit/README.md) terminada: firmas, EIP-712 y permit.
Tu repositorio `bc-smartcontracts-<dominio>` con el proyecto de la semana 14 en `main`.

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — Proxies y delegatecall](1-teoria/01-proxies-y-delegatecall.md) | 35 min |
| 2 | [Teoría 02 — Storage layout](1-teoria/02-storage-layout.md) | 50 min |
| 3 | [Teoría 03 — Initializers](1-teoria/03-initializers.md) | 45 min |
| 4 | [Teoría 04 — UUPS y transparent](1-teoria/04-uups-y-transparent.md) | 50 min |
| 5 | [Ejercicio 01 — Proxy a mano](2-practicas/ejercicio-01-proxy-a-mano/README.md) | 2 h |
| 6 | [Ejercicio 02 — Initializers y transparent](2-practicas/ejercicio-02-initializers-y-transparent/README.md) | 2 h |
| 7 | [Ejercicio 03 — UUPS y storage layout](2-practicas/ejercicio-03-uups-y-storage-layout/README.md) | 2 h |
| 8 | [Proyecto — Registro actualizable](3-proyecto/README.md) | 4 h |
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

- Los tres ejercicios: `forge test --deny warnings` en verde (12, 12 y 10 tests).
- En tu repositorio, `forge test` de `week-15/` pasa 138 tests y salta el de fork; en anvil
  desplegaste el registro detrás de su proxy, registraste en V1, actualizaste a V2 y viste el
  límite por cuenta; el test de fork pasa contra el proxy, `.gas-snapshot` está actualizado y
  hay un pull request `week-15` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 14](../week-14-firmas_eip712_y_permit/5-glosario/README.md) | **Semana 15 — Contratos actualizables** | [Teoría 01 — Proxies y delegatecall →](1-teoria/01-proxies-y-delegatecall.md) |

← [Volver al índice del bootcamp](../README.md)
