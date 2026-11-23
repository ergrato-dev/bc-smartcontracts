# Teoría 01 — Qué es el análisis estático

## 🎯 Objetivos

- Distinguir el análisis estático de los tests: qué mira cada uno y qué no.
- Seguir el camino del código al hallazgo: AST, grafo de control, representación intermedia y
  detectores.
- Explicar qué es un falso positivo y un falso negativo, y por qué los dos son inevitables.
- Saber qué clase de fallos encuentra una herramienta y cuáles no encontrará nunca.

## Un programa que lee programas

Las semanas 21 y 22 encontraron fallos de dos maneras: leyendo el código con una lista de
preguntas, y escribiendo un test que ataca. Las dos dependen de ti: de que hagas la pregunta
buena y de que escribas el test que toca.

El **análisis estático** es un programa que lee tu código **sin ejecutarlo** y avisa de lo que
reconoce como peligroso. "Estático" por oposición a "dinámico": un test ejecuta el contrato con
unos valores concretos y mira qué pasa; un analizador estático mira el código y razona sobre lo
que **podría** pasar con cualquier valor.

Ya lo usas sin llamarlo así. Cuando solc dice `Warning (9302): Return value of low-level calls not
used.`, ha hecho análisis estático: ha visto un `call` cuyo resultado nadie lee. Y desde la semana
10 silencias avisos con `// forge-lint: disable-next-line(...)`: son de `forge lint`, el linter
que Foundry ejecuta al compilar. Esta semana usas dos herramientas a propósito, las configuras, y escribes
tus propias reglas:

| Herramienta | Qué es | Teoría |
| ----------- | ------ | ------ |
| **Slither** | El analizador de Trail of Bits, en Python. 101 detectores, impresoras de resúmenes y una API para escribir los tuyos | 02 y 04 |
| **forge lint** | El linter de Foundry, en Rust, dentro de `forge`. Avisa de fallos, estilo y gas | 03 |
| **Detectores propios** | Reglas de tu protocolo escritas en Python sobre Slither | 04 |

## Del código al hallazgo

![Del código al hallazgo: forge compila con solc y deja el AST; Slither construye un grafo de control por función y traduce cada nodo a SlithIR; los detectores buscan patrones y devuelven hallazgos que tú clasificas en verdaderos, falsos positivos o aceptados; forge lint hace lo mismo dentro de forge](../0-assets/01-del-codigo-al-hallazgo.svg)

1. **El AST** (*abstract syntax tree*, árbol de sintaxis abstracta). Al compilar, solc convierte
   el texto en un árbol: un nodo para el contrato, colgando de él uno por función, de cada función
   uno por instrucción, y así hasta cada variable y cada operador. Slither no vuelve a leer el
   texto: pide el árbol al compilador. Por eso un contrato que no compila no se puede analizar.
2. **El grafo de control** (*control-flow graph*, CFG). Slither convierte cada función en un grafo:
   cada nodo es una instrucción, y las flechas dicen cuál puede ir después. Un `if` tiene dos
   salidas; un bucle, una flecha hacia atrás. Así sabe que en `refund` la llamada va **antes**
   de `contributed[msg.sender] = 0`.
3. **La representación intermedia**. Cada nodo se traduce a operaciones simples, todas de la misma
   forma: `TMP = operación(argumentos)`. Slither la llama **SlithIR**. `address(this).balance ==
   GOAL` se convierte en tres: convertir `this` en dirección, leer su saldo, comparar. Es más fácil
   buscar "una comparación `==` con un saldo" en tres operaciones que en todas las formas de
   escribirla en Solidity. La teoría 04 la usa.
4. **Los detectores**. Cada uno busca un patrón: "una llamada con valor y una variable de estado
   escrita después" (`reentrancy-eth`), "`tx.origin` en una condición" (`tx-origin`). Muchos
   siguen además **de dónde viene un valor** (análisis de flujo de datos, *taint analysis*): si
   lo controla quien llama, si sale de `block.timestamp`, si es un saldo.

## Impacto y confianza

Cada detector de Slither declara dos cosas:

- **Impacto** (*impact*): cuánto daño haría si el hallazgo es real. `High`, `Medium`, `Low`,
  `Informational` (estilo, sin riesgo) y `Optimization` (gas).
- **Confianza** (*confidence*): cuántas veces acierta el patrón. `High`, `Medium` o `Low`.

`reentrancy-eth` es `High` de impacto y `Medium` de confianza: si es real, te roban; pero no
siempre lo es. `naming-convention` es `Informational` y `High`: casi siempre acierta, y nunca
importa mucho. forge lint usa solo la severidad: `high`, `med`, `low`, `info` y `gas`.

## Falsos positivos y falsos negativos

Un analizador estático decide sin ejecutar: no sabe qué valores llegarán ni qué hace el otro
contrato. Así que se equivoca de dos maneras:

- **Falso positivo**: avisa de algo que no es un fallo. En el ejercicio 02, Slither marca
  `amount == 0` como `timestamp`, "uso peligroso de `block.timestamp`". No hay ningún timestamp en
  esa comparación: `amount` está en el mismo struct que `since`, que sí lo es, y el análisis de
  flujo de datos los mezcla.
- **Falso negativo**: no avisa de un fallo que existe. En el mismo ejercicio, `unstake` borra la
  posición sin pagar la recompensa, y ninguna herramienta dice nada.

No es que estén mal hechas. Decidir sin ejecutar si un programa cualquiera llega a cierto estado
es imposible en general: es una forma del problema de la parada, que no tiene solución. Cada
herramienta elige dónde equivocarse. Si avisa de todo lo que **podría** ser un fallo, da muchos
falsos positivos y nadie la lee. Si avisa solo de lo que está segura, deja pasar fallos. Slither
y forge lint están en medio, y por eso existe el **triaje**.

## El triaje

Una herramienta no dice "hay un fallo": dice "aquí hay un patrón que suele serlo". Decidir si lo
es te toca a ti, hallazgo por hallazgo. Cada uno acaba en una de tres:

| Veredicto | Qué significa | Qué haces |
| --------- | ------------- | --------- |
| **Verdadero** | El fallo existe | Lo corriges y escribes el test que lo prueba |
| **Falso positivo** | El patrón está, el fallo no | Lo silencias en esa línea, con un comentario que diga por qué no es un fallo |
| **Aceptado** | El riesgo existe, y lo asumes | Lo silencias en esa línea con el porqué, y lo anotas en el informe de auditoría |

`block.timestamp` en un plazo de 7 días es el ejemplo de manual de **aceptado**: un validador
puede mover el timestamp unos segundos (semana 07), y unos segundos no cambian nada en una semana.
La diferencia con un falso positivo es que el riesgo existe: si mañana el plazo fuera de 5
segundos, ya no lo aceptarías.

Dos reglas para silenciar:

1. **En la línea, nunca en todo el proyecto.** Excluir un detector entero en la configuración
   silencia también el hallazgo verdadero que alguien escriba el mes que viene.
2. **Con el porqué encima.** Un comentario de silencio sin explicación es una deuda: quien lo lea
   no sabrá si alguien lo pensó.

## Lo que encuentran y lo que no

Los detectores buscan **patrones del código**. Encuentran bien lo que se parece siempre a sí
mismo:

- El orden de una llamada y una escritura: reentrancy (semana 21).
- `tx.origin` en una condición, un `transfer` de ERC-20 sin mirar su `bool`, un `call` sin mirar
  `ok`.
- Dividir antes de multiplicar, una conversión que trunca, una comparación estricta con un saldo.
- Variables sin inicializar, sombreado de nombres, funciones que podrían ser `external`.

No encuentran lo que depende de **lo que el contrato debería hacer**, porque eso no está en el
código:

- La lógica de negocio: que `unstake` debería pagar la recompensa, o que un alta debería costar
  la tasa.
- Las vulnerabilidades económicas de la semana 22: un precio al contado parece cualquier otra
  lectura de un pool; un sándwich no es un patrón de un contrato, sino de un bloque.
- Los hallazgos de tu informe: H-01 depende del tamaño de un motivo de revert, y H-02, de cuándo
  se actualiza el feed.

Por eso el análisis estático **no sustituye** a los tests ni a la revisión: los complementa. Es
barato (segundos, sin escribir nada), no se cansa, y revisa todo el proyecto cada vez. Es la
primera pasada, no la última.

## Una herramienta también se jubila

Hasta 2026, la otra herramienta habitual junto a Slither era **Aderyn**, de Cyfrin. Su repositorio
se archivó en 2026 y sus binarios ya no se pueden descargar: el instalador oficial
solo imprime `Aderyn has been retired and is no longer maintained.` Un analizador que nadie
mantiene deja de entender las versiones nuevas de solc, y nadie corrige sus falsos negativos.

La lección sirve para cualquier herramienta de seguridad: fija su versión (esta semana,
Slither `0.11.5`), mira que alguien la mantenga, y no dependas de una sola. Por eso el bootcamp
usa dos que se solapan, Slither y forge lint, y la comparación del ejercicio 02 enseña por qué.

## ⚠️ Riesgos

- **Cero avisos no es cero fallos.** Un informe limpio de Slither no dice nada de la lógica ni de
  la economía del protocolo.
- **Silenciar en bloque.** Excluir un detector entero porque "da mucho ruido" es la forma más
  común de perder el hallazgo que importaba.
- **Corregir para callar a la herramienta.** Cambiar el código hasta que el aviso desaparezca, sin
  entender por qué salía, puede romper otra cosa: el ejercicio 02 lo enseña.

## 📝 Resumen

- El análisis estático lee el código sin ejecutarlo: AST, grafo de control, SlithIR y detectores.
- Cada hallazgo tiene un impacto y una confianza, y puede ser falso. Se triaja uno a uno:
  verdadero, falso positivo o aceptado.
- Se silencia en la línea, con el porqué. Nunca en bloque.
- Encuentra patrones, no reglas de negocio ni economía. Complementa los tests; no los sustituye.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Semana 23 — Análisis estático](../README.md) | **Teoría 01 — Qué es el análisis estático** | [Teoría 02 — Slither →](02-slither.md) |
