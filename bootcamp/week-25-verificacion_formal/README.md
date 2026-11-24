# Semana 25 — Verificación formal

La semana 24 probó tu protocolo con cientos de miles de secuencias aleatorias. Pero una muestra,
por grande que sea, no dice nada de lo que no probó. Esta semana cambias la pregunta: en vez de
"¿falla con estas entradas?", "¿**existe** alguna entrada con la que falle?". Lo respondes con
**ejecución simbólica**: las entradas son incógnitas, y un **solver SMT** decide si alguna rompe
tu especificación. Usas dos herramientas: el **SMTChecker** que viene dentro de `solc`, que
razona sobre cualquier secuencia de transacciones en contratos pequeños, y **Halmos**, de a16z,
que convierte tus tests de Foundry en demostraciones y aguanta tu protocolo entero.

## 🎯 Objetivos de aprendizaje

- Explicar qué demuestra una verificación formal, qué no, y dentro de qué modelo.
- Describir la ejecución simbólica: caminos, condiciones de camino y las respuestas del solver.
- Activar el SMTChecker desde `foundry.toml`, escribirle una spec y leer sus tres resultados,
  incluido el contraejemplo espurio.
- Escribir specs `check_` para Halmos con parámetros simbólicos, `vm.assume`, `try` y llamadas
  simbólicas, y leer su salida.
- Reconocer una demostración incompleta: specs vacías, límites de bucle y tiempos agotados.
- Comprobar las specs con mutantes y escribir en el informe lo que no se demostró.

## 📋 Prerrequisitos

[Semana 24](../week-24-fuzzing_de_invariantes/README.md) terminada: tu protocolo con invariantes,
Medusa y mutantes, en `main`. Del resto del bootcamp, esta semana usa sobre todo los proxies
ERC-1967 de la semana 15 y la fórmula de `CREATE` de la semana 10.

La imagen del contenedor trae Halmos desde esta semana, con sus solvers, z3 y yices, y la
biblioteca `halmos-cheatcodes`. Reconstrúyela:

```bash
docker build -t bc-smartcontracts-dev docker
```

**Verifica**: dentro del contenedor, `halmos --version` imprime `halmos 0.3.2` y `z3 --version`,
`Z3 version 4.12.6 - 64 bit`. Como Medusa, Halmos solo está en la imagen amd64: sus solvers no
publican paquetes para Linux arm64. En un Mac con Apple Silicon, los ejercicios 02 y 03, el
proyecto y el SMTChecker del ejercicio 01 necesitan la imagen amd64
(`docker build --platform linux/amd64`).

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — De probar a demostrar](1-teoria/01-de-probar-a-demostrar.md) | 40 min |
| 2 | [Teoría 02 — SMTChecker](1-teoria/02-smtchecker.md) | 40 min |
| 3 | [Teoría 03 — Halmos](1-teoria/03-halmos.md) | 50 min |
| 4 | [Teoría 04 — Especificaciones y límites](1-teoria/04-especificaciones-y-limites.md) | 50 min |
| 5 | [Ejercicio 01 — SMTChecker](2-practicas/ejercicio-01-smtchecker/README.md) | 1 h 15 min |
| 6 | [Ejercicio 02 — Halmos](2-practicas/ejercicio-02-halmos/README.md) | 1 h 30 min |
| 7 | [Ejercicio 03 — Specs de contrato](2-practicas/ejercicio-03-specs-de-contrato/README.md) | 1 h 30 min |
| 8 | [Proyecto — Specs de tu protocolo](3-proyecto/README.md) | 4 h |
| 9 | [Rúbrica de evaluación](rubrica-evaluacion.md) (autoevaluación) | 30 min |
| 10 | [Ebooks](4-recursos/ebooks-free/README.md), [videos](4-recursos/videografia/README.md), [webgrafía](4-recursos/webgrafia/README.md) y [glosario](5-glosario/README.md) | 30 min |

## ⏱️ Distribución del tiempo (14 h)

| Parte | Tiempo |
| ----- | ------ |
| Teoría | 3 h |
| Prácticas | 4 h 15 min |
| Proyecto | 4 h |
| Autoevaluación, recursos y glosario | 1 h |
| Margen para specs que no salen a la primera | 1 h 45 min |

## ✅ Cómo saber que terminaste

- El ejercicio 01 con `forge test` sin error y `CHC: Assertion violation check is safe!`, y el 02
  y el 03 con `bash test.sh`: forge y Halmos en verde.
- En tu repositorio, `bash test.sh` de `week-25/` acaba sin error, con las cinco specs
  demostradas y los diez mutantes muertos. `week-25/audit/README.md` tiene la sección de
  verificación formal, y hay un pull request `week-25` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 24](../week-24-fuzzing_de_invariantes/5-glosario/README.md) | **Semana 25 — Verificación formal** | [Teoría 01 — De probar a demostrar →](1-teoria/01-de-probar-a-demostrar.md) |

← [Volver al índice del bootcamp](../README.md)
