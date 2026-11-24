# Teoría 01 — Del fuzz a las invariantes

## 🎯 Objetivos

- Distinguir el fuzzing sin estado de la semana 09 del fuzzing con estado: una llamada frente a
  una secuencia.
- Definir una invariante y reconocer sus formas más comunes en un contrato.
- Sacar las invariantes de tu protocolo de lo que promete, no de lo que hace el código.
- Saber qué demuestra una campaña en verde y qué no.

## Una llamada frente a una secuencia

En la semana 09 escribiste tests de fuzz: una función con parámetros que forge llama 256 veces
con valores aleatorios. Cada ejecución parte del mismo estado, el de `setUp`, y hace **una**
llamada. Es fuzzing **sin estado** (*stateless*): encuentra el valor que rompe una función, pero
nunca el orden de llamadas que la rompe.

Muchos fallos de contratos no están en una función sino entre dos. En el ejercicio 01, `Seats`
tiene tres funciones y cada una, por separado, hace lo que dice. Sus cinco tests unitarios pasan.
Pero esta secuencia rompe el contador:

```text
book(0)                       → booked = 1, la butaca 0 es tuya
transferSeat(0, address(0))   → la butaca 0 "no es de nadie", y booked sigue en 1
```

Ningún test de una llamada la encuentra: hacen falta dos, en ese orden, desde la misma cuenta.
El **fuzzing con estado** (*stateful*) genera secuencias: llama a una función, luego a otra sobre
el estado que dejó la primera, y así hasta cientos de llamadas. Después de cada una comprueba una
lista de propiedades que tienen que ser verdad **siempre**.

![Fuzzing sin estado frente a fuzzing con estado: el primero repite una llamada sobre el estado de setUp; el segundo encadena llamadas aleatorias y comprueba las invariantes después de cada una, hasta que una falla y el fuzzer encoge la secuencia a las llamadas imprescindibles](../0-assets/01-fuzz-con-estado.svg)

## Invariantes

Una **invariante** es una afirmación sobre el estado que se cumple después de cualquier
secuencia de llamadas. No dice qué hace una función: dice qué no puede llegar a pasar nunca.

| Forma | Ejemplo en un contrato | Ejemplo en tu protocolo |
| ----- | ---------------------- | ----------------------- |
| **Conservación**: un total es la suma de sus partes | `totalSupply == Σ balanceOf` | Los certificados de todas las cuentas suman `count` |
| **Contabilidad**: lo que hay es lo que entró menos lo que salió | El saldo de un vault es depositado + rendimiento − retirado | El ETH del registro es lo cobrado menos lo retirado |
| **Límite**: un valor nunca pasa de un tope | `booked <= CAPACITY` | `activeCount <= capacity` |
| **Coherencia**: dos variables que dicen lo mismo coinciden | `seatsOf[h]` cuenta las butacas de `h` | `activeCount == count − retiradas` |
| **Solvencia**: el contrato puede pagar todo lo que debe | Las participaciones valen como mucho lo que guarda el vault | Lo pagado de más se devuelve entero |
| **Transición**: un estado solo cambia en un sentido | Un recurso retirado no vuelve a estar activo | `count` nunca baja |

Fíjate en que ninguna menciona una función. Por eso valen para secuencias que nadie escribió a
mano: cualquiera que las rompa es un fallo.

## De dónde salen

La fuente de una invariante es **lo que el protocolo promete**: la documentación, los
comentarios de NatSpec, el modelo de amenazas de tu informe de auditoría. No el código: si
copias en la invariante lo que hace el código, compruebas que el código hace lo que hace.

Tres preguntas que dan casi todas:

1. **¿Qué se cuenta dos veces?** Cada contador que guarda algo que también se podría calcular
   (`booked`, `activeCount`, `totalShares`) tiene una invariante de coherencia con el cálculo.
2. **¿Por dónde entra y sale valor?** ETH, tokens, puntos: cada uno tiene una invariante de
   contabilidad, con las entradas y salidas contadas aparte.
3. **¿Qué límites promete?** Capacidad, máximo por cuenta, tope de suministro: cada uno es una
   invariante de límite, y conviene probar también que se **rechaza** lo que lo pasaría.

Tu informe de auditoría ya tiene muchas escritas en prosa. En la solución de referencia, la tabla
de la revisión por clases de la semana 21 dice que `maxPerAccount` limita cada array `_idsOf`:
eso es una invariante.

## Qué demuestra una campaña

Una campaña en verde dice: "en estas secuencias, ninguna invariante falló". No dice que no haya
fallos. El fuzzer solo prueba lo que genera, y hay tres maneras de que no genere lo que importa:

- **Revierte casi todo.** En el ejercicio 01 revierten más del 95 % de las llamadas: una butaca
  fuera de rango, una cuenta que no es la dueña. Esas llamadas no prueban nada. La teoría 03
  lo arregla con un *handler*.
- **No llega a ciertos valores.** Para pasarte una butaca a ti cuando ya tienes dos, el fuzzer
  tiene que elegir como destino justo una de sus cuentas. Con direcciones aleatorias, no lo hace.
- **La invariante es débil.** Una invariante que no mira el saldo no ve un fallo de saldo. La
  teoría 03 enseña a comprobarlo con **mutantes**: fallos que metes a propósito para ver si la
  suite los atrapa.

Por eso una campaña en verde se lee junto con la tabla de llamadas que imprime forge, y se
contrasta con mutantes. Para demostrar que una propiedad se cumple para cualquier entrada hace
falta otra técnica, la verificación formal, que llega en la semana 25.

## Dos fuzzers

| | forge (`invariant_`) | Medusa |
| - | -------------------- | ------ |
| Qué es | El fuzzer de invariantes de Foundry, dentro de `forge test` | El fuzzer de Trail of Bits, un programa aparte escrito en Go |
| Invariantes | Funciones `invariant_` en un contrato de test, con `assert*` de forge-std | Funciones `property_` que devuelven `bool`, y `assert` en cualquier función |
| Configuración | `[invariant]` en `foundry.toml` | `medusa.json` |
| El reloj | Fijo, salvo que tú lo muevas con `vm.warp` | Avanza solo entre llamadas |
| Teoría | 02 y 03 | 04 |

Los dos generan secuencias, encogen la que falla y guardan lo que encontraron. Usar los dos sobre
las mismas propiedades no es redundante: cada uno genera las entradas de otra manera, y lo que
uno no alcanza a veces lo alcanza el otro.

## ⚠️ Riesgos

- **Confundir verde con correcto.** Una suite que nunca ha fallado no ha demostrado que sirva.
  Mira cuántas llamadas revierten y pasa los mutantes.
- **Invariantes que copian el código.** Si la invariante dice lo mismo que la función, el fallo
  de la función está también en la invariante.
- **Solo invariantes.** No sustituyen a los tests unitarios ni a los de ataque de las semanas 21 y
  22: un test unitario documenta un caso concreto, y un ataque, un camino que alguien buscaría.

## 📝 Resumen

- El fuzzing sin estado prueba una llamada; el fuzzing con estado prueba secuencias y comprueba
  invariantes tras cada llamada.
- Una invariante dice qué no puede pasar nunca: conservación, contabilidad, límite, coherencia,
  solvencia, transición.
- Salen de lo que el protocolo promete: contadores dobles, entradas y salidas de valor, límites.
- Una campaña en verde solo habla de lo que el fuzzer generó: se lee con su tabla de llamadas y
  se contrasta con mutantes.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Semana 24 — Fuzzing de invariantes](../README.md) | **Teoría 01 — Del fuzz a las invariantes** | [Teoría 02 — Invariantes en Foundry →](02-invariantes-en-foundry.md) |
