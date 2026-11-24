# Semana 29 — Optimización de gas

Cada operación de la EVM cuesta gas, y el gas lo paga quien envía la transacción. En la semana 27
viste cuánto cuesta cada opcode y cada acceso al storage; esta semana usas esos precios para que tu
código gaste menos sin cambiar lo que hace. Primero aprendes a **medir** sin engañarte: qué número
da cada herramienta y cuál es el de la transacción de verdad. Después atacas lo que más pesa, el
storage (empaquetar, cachear, bitmaps, `immutable`, eventos), y lo que pesa menos, el código y el
compilador (calldata, custom errors, cortocircuito, `unchecked`, el optimizador). Y terminas con lo
más importante: cuándo **no** optimizar, porque cada ahorro tiene un precio en seguridad, en
claridad o en compatibilidad. En el proyecto abaratas el alta de tu registro sin cambiar su layout
de storage y dejas los números guardados y comprobados.

## 🎯 Objetivos de aprendizaje

- Distinguir el gas de una transacción, el de una llamada y el de un test, y medir con
  `vm.lastFrameGas`, snapshots con nombre, el informe de gas y el recibo de anvil.
- Explicar el aislamiento de Foundry (`isolate`), el gas base, la calldata y el reembolso.
- Bajar el coste del storage: empaquetar structs, leer y escribir una vez, bitmaps, `constant` e
  `immutable`, eventos en vez de storage y cerrojos sin escrituras de cero.
- Bajar el coste del código: calldata, custom errors, punteros a storage, cortocircuito y
  `unchecked` donde una comprobación anterior lo garantiza.
- Elegir las ejecuciones del optimizador sabiendo lo que cambian en tamaño y en gas.
- Rechazar una optimización cuando rompe la seguridad, el layout de un proxy o la claridad, y
  probar que cada una no cambia el comportamiento.

## 📋 Prerrequisitos

[Semana 28](../week-28-yul_e_inline_assembly/README.md) terminada: tu protocolo con la llamada al
hook en assembly, en `main`. Esta semana usa los precios del storage y de la calldata de la semana
27, el informe de gas y `forge snapshot` de la semana 09, los proxies y el layout de la semana 15,
la reentrancy y `unchecked` de la semana 21, los mutantes de la semana 24 y el transient storage de
las semanas 27 y 28.

La imagen del contenedor no cambia: es la de la semana 25.

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — Medir el gas](1-teoria/01-medir-el-gas.md) | 45 min |
| 2 | [Teoría 02 — El storage manda](1-teoria/02-el-storage-manda.md) | 50 min |
| 3 | [Teoría 03 — El código y el compilador](1-teoria/03-el-codigo-y-el-compilador.md) | 45 min |
| 4 | [Teoría 04 — Cuándo no optimizar](1-teoria/04-cuando-no-optimizar.md) | 40 min |
| 5 | [Ejercicio 01 — Storage barato](2-practicas/ejercicio-01-storage-barato/README.md) | 2 h |
| 6 | [Ejercicio 02 — Código barato](2-practicas/ejercicio-02-codigo-barato/README.md) | 1 h 30 min |
| 7 | [Ejercicio 03 — Optimizar sin romper](2-practicas/ejercicio-03-optimizar-sin-romper/README.md) | 2 h |
| 8 | [Proyecto — Un alta más barata](3-proyecto/README.md) | 4 h |
| 9 | [Rúbrica de evaluación](rubrica-evaluacion.md) (autoevaluación) | 30 min |
| 10 | [Ebooks](4-recursos/ebooks-free/README.md), [videos](4-recursos/videografia/README.md), [webgrafía](4-recursos/webgrafia/README.md) y [glosario](5-glosario/README.md) | 30 min |

## ⏱️ Distribución del tiempo (14 h)

| Parte | Tiempo |
| ----- | ------ |
| Teoría | 3 h |
| Prácticas | 5 h 30 min |
| Proyecto | 4 h |
| Autoevaluación, recursos y glosario | 1 h |
| Margen para el informe del proyecto | 30 min |

## ✅ Cómo saber que terminaste

- Los tres ejercicios con `forge test` sin error: `10 tests passed`, `7 tests passed` y
  `6 tests passed`, y sabes cuánto ahorró cada paso.
- En tu repositorio, `bash test.sh` de `week-29/` acaba sin error, con los cuatro tests de
  `test/gas/RegisterGas.t.sol` en verde, los números de `snapshots/RegisterGasTest.json` en tu
  informe y los veinte mutantes muertos, y hay un pull request `week-29` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 28](../week-28-yul_e_inline_assembly/5-glosario/README.md) | **Semana 29 — Optimización de gas** | [Teoría 01 — Medir el gas →](1-teoria/01-medir-el-gas.md) |

← [Volver al índice del bootcamp](../README.md)
