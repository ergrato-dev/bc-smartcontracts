# Semana 01 — Criptografía y blockchain

Antes de escribir un solo contrato necesitas entender qué garantiza una blockchain y
cómo lo consigue. Esta semana trabajas solo con la terminal: calculas hashes, derivas
direcciones desde claves, firmas y verificas mensajes, y construyes a mano una cadena de
bloques para ver por qué no se puede alterar. Al final, la primera capa del protocolo de
tu dominio: su cuenta y su ficha firmada.

## 🎯 Objetivos de aprendizaje

- Explicar qué problema resuelve una blockchain y cuándo **no** hace falta.
- Construir el contenedor de desarrollo y usar `cast` para convertir datos y bytes.
- Calcular hashes keccak256 y explicar sus propiedades.
- Derivar una dirección desde una clave privada, a mano y con `cast`.
- Firmar y verificar mensajes, y explicar qué demuestra una firma.
- Construir una cadena de hashes y detectar una alteración.
- Describir el consenso por prueba de participación y la finalidad.

## 📋 Prerrequisitos

Saber programar en algún lenguaje (variables, funciones, condicionales, bucles) y
moverte en la terminal. Nada de blockchain. Necesitas **Docker** y **git** instalados
([`docs/setup.md`](../../docs/setup.md)) y una cuenta de GitHub.

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — Qué problema resuelve una blockchain](1-teoria/01-que-problema-resuelve-una-blockchain.md) | 30 min |
| 2 | [Teoría 02 — El contenedor y cast](1-teoria/02-el-contenedor-y-cast.md) | 30 min |
| 3 | [Teoría 03 — Funciones hash](1-teoria/03-funciones-hash.md) | 30 min |
| 4 | [Teoría 04 — Claves y direcciones](1-teoria/04-claves-y-direcciones.md) | 30 min |
| 5 | [Teoría 05 — Firmas digitales](1-teoria/05-firmas-digitales.md) | 30 min |
| 6 | [Teoría 06 — Bloques y cadena](1-teoria/06-bloques-y-cadena.md) | 30 min |
| 7 | [Ejercicio 01 — Hashes con cast](2-practicas/ejercicio-01-hashes-con-cast/README.md) | 2 h |
| 8 | [Ejercicio 02 — Claves y direcciones](2-practicas/ejercicio-02-claves-y-direcciones/README.md) | 2 h |
| 9 | [Ejercicio 03 — Firmar y verificar](2-practicas/ejercicio-03-firmar-y-verificar/README.md) | 2 h |
| 10 | [Proyecto — Ficha criptográfica](3-proyecto/README.md) | 4 h |
| 11 | [Rúbrica de evaluación](rubrica-evaluacion.md) (autoevaluación) | 30 min |
| 12 | [Ebooks](4-recursos/ebooks-free/README.md), [videos](4-recursos/videografia/README.md), [webgrafía](4-recursos/webgrafia/README.md) y [glosario](5-glosario/README.md) | 30 min |

## ⏱️ Distribución del tiempo (14 h)

| Parte | Tiempo |
| ----- | ------ |
| Teoría | 3 h |
| Prácticas | 6 h |
| Proyecto | 4 h |
| Autoevaluación, recursos y glosario | 1 h |

## ✅ Cómo saber que terminaste

- Los tres ejercicios terminan con `6 de 6 pasos correctos` en `bash test.sh`.
- En tu repositorio `bc-smartcontracts-<dominio>`, `bash test.sh` de `week-01/` pasa los
  8 tests del proyecto y hay un pull request `week-01` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Índice del bootcamp](../README.md) | **Semana 01 — Criptografía y blockchain** | [Teoría 01 — Qué problema resuelve una blockchain →](1-teoria/01-que-problema-resuelve-una-blockchain.md) |

← [Volver al índice del bootcamp](../README.md)
