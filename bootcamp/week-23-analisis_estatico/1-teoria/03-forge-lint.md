# Teoría 03 — forge lint

## 🎯 Objetivos

- Ejecutar `forge lint`, leer un aviso y saber qué severidades mira por defecto.
- Configurarlo en `foundry.toml` y hacer que falle en un script.
- Elegir entre los cuatro comentarios de silencio, y combinarlos con los de Slither en la misma
  línea.
- Comparar lo que ven forge lint y Slither, y por qué conviene pasar los dos.

## El linter de Foundry

Un **linter** es un analizador estático que avisa de errores probables y de estilo. `forge lint`
viene dentro de `forge` (Foundry `v1.9.0` en la imagen): no hay nada que instalar. Está escrito en
Rust y aprovecha la compilación en caché de forge. Sobre el protocolo del proyecto, ya compilado,
`forge lint src` tarda unos 0,04 segundos y `slither .`, unos 5: Slither borra la caché y
recompila todo cada vez.

Lo usas desde la semana 10 sin pedirlo: `forge build` lo ejecuta al terminar de compilar, y los
`// forge-lint: disable-next-line(...)` de tus contratos silencian sus avisos. Esta semana lo
ejecutas a propósito:

```bash
cd bootcamp/week-23-analisis_estatico/2-practicas/ejercicio-02-forge-lint/starter
forge lint src
```

`src` limita el análisis a esa carpeta, que es lo que se despliega; una ruta en la línea de
comandos pasa por encima de la clave `ignore` de la configuración. Un aviso:

```text
warning[unchecked-call]: low-level call does not check the success return value
   ╭▸ src/Staking.sol:77:9
   │
77 │         payable(msg.sender).call{value: reward}(""); // <- Paso 1
   │         ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   │
   ╰ help: https://getfoundry.sh/forge/linting/unchecked-call
```

- `warning[unchecked-call]`: el nivel y el nombre del lint (su identificador).
- `src/Staking.sol:77:9`: archivo, línea y **columna**. Los subrayados marcan la expresión exacta,
  no la función entera: es más preciso que Slither.
- `help`: la documentación del lint, con un ejemplo y la corrección.

Algunos avisos traen además una **nota** con la forma de silenciarlos. `unsafe-typecast`, por
ejemplo, propone `// casting to 'uint96' is safe because [explain why]` encima del
`disable-next-line`: hasta la herramienta pide el porqué.

## Severidades

Cada lint tiene una severidad: `high`, `med`, `low`, `info`, `gas` o `code-size`. Las tres
primeras salen como `warning[...]`; las demás, como `note[...]`. **Por defecto** forge lint solo
ejecuta `high`, `med` y `low`: lo dice `forge config --json`, en la clave `lint`:

```json
{"severity":["high","medium","low"],"exclude_lints":[],"ignore":[],"lint_on_build":true, ...}
```

Para ver las otras, pídelas con `--severity` (después de la ruta: la opción admite varios valores
y se comería `src`):

```bash
forge lint src --severity info gas
```

En el ejercicio 02 da tres notas: `low-level-calls`, `named-struct-fields` (el `Position(...)` sin
nombres de campo) y `unused-error` (el `TransferFailed` que nadie usa hasta el paso 1).

| Opción | Qué hace |
| ------ | -------- |
| `--severity high med` | Solo esas severidades |
| `--only-lint unchecked-call` | Solo ese lint |
| `--deny warnings` | Termina con error si hay algún `warning` |
| `--deny notes` | Termina con error si hay algún `warning` o `note` |
| `--report-unused-suppressions` | Avisa de los comentarios de silencio que ya no silencian nada |

Sin `--deny`, `forge lint` termina siempre con código 0, aunque avise. Para un `test.sh` o CI:
`forge lint --deny warnings src`.

## `[lint]` en `foundry.toml`

La configuración va en `foundry.toml`, en su propia sección:

```toml
[lint]
severity = ["high", "med", "low"]
exclude_lints = ["mixed-case-function"]
ignore = ["src/legacy/**"]
lint_on_build = true
```

| Clave | Qué fija |
| ----- | -------- |
| `severity` | Qué severidades se ejecutan |
| `exclude_lints` | Lints que no se ejecutan nunca, en todo el proyecto |
| `ignore` | Archivos que no se analizan |
| `lint_on_build` | Si `forge build` lo ejecuta al compilar. Con `false`, solo `forge lint` |

`exclude_lints` tiene el mismo peligro que excluir un detector de Slither: apaga también los
avisos verdaderos de mañana. Los ejercicios y el proyecto no lo usan. `--no-lint` en `forge build`
quita el lint de una sola compilación: los `test.sh` lo usan para comprobar los warnings de solc
por separado.

## Cuatro formas de silenciar

| Comentario | Dónde va | Qué silencia |
| ---------- | -------- | ------------ |
| `// forge-lint: disable-next-line(lint)` | En la línea anterior | La línea siguiente |
| `// forge-lint: disable-line(lint)` | Al final de la misma línea | Esa línea |
| `// forge-lint: disable-next-item(lint)` | Encima de una función o contrato | Todo ese elemento |
| `// forge-lint: disable-start(lint)` y `disable-end(lint)` | Alrededor de un bloque | El bloque |

Varios lints van separados por comas: `disable-next-item(calls-loop, reentrancy-events)`. Usa el
más estrecho que funcione: `disable-next-item` sobre una función de 30 líneas silencia también
la línea 31 que alguien añada.

## Slither y forge lint en la misma línea

Los dos piden su comentario **justo en la línea anterior**, y los dos no caben. En el proyecto,
`withdrawFees` envía ETH a `to`, y los dos lo marcan como envío a un destino arbitrario. Si apilas
los dos comentarios, el de arriba deja de funcionar: ya no está en la línea anterior. La
solución: Slither encima, forge lint al final de la línea.

```solidity
// Solo TREASURER_ROLE llega aquí. Los dos analizadores reconocen `onlyOwner`, no `onlyRole`.
// slither-disable-next-line arbitrary-send-eth
(bool ok,) = to.call{value: amount}(""); // forge-lint: disable-line(arbitrary-send-eth)
```

Con varias líneas avisadas dentro de una función corta, `disable-next-item` sobre la función deja
libres las líneas anteriores para Slither.

## forge lint frente a Slither

En el staking del ejercicio 02, los dos se solapan, pero no del todo:

![Lo que encontró cada control en el staking: los dos ven la división antes de multiplicar y la llamada sin comprobar; solo forge lint ve las tres conversiones que truncan; solo Slither da cuatro falsos positivos; ninguno ve que unstake no paga la recompensa, y eso lo encuentra un test](../0-assets/02-lo-que-ve-cada-control.svg)

| | forge lint | Slither |
| - | ---------- | ------- |
| Instalación | Dentro de `forge` | Python, aparte (en la imagen, `uv tool`) |
| Velocidad | Usa la caché de forge | `forge clean` y compilación completa |
| Precisión de la ubicación | Línea y columna | Función y líneas |
| Reentrancy entre funciones | Señala la llamada y la variable escrita después | Lista las demás funciones por las que se puede volver a entrar |
| Conversiones que truncan | `unsafe-typecast` | No tiene detector |
| Resúmenes (`vars-and-auth`...) | No | 27 impresoras |
| Reglas propias | No | Sí, en Python (teoría 04) |

Ninguno es mejor: ven cosas distintas y se equivocan en cosas distintas. Son baratos, así que se
pasan los dos, y cada aviso de cualquiera de ellos se triaja.

## ⚠️ Riesgos

- **`forge lint` sin `--deny` no falla nunca.** Un script que lo ejecuta "para ver" no protege nada.
- **Las severidades `info` y `gas` no se ejecutan por defecto.** Si quieres revisarlas, pídelas.
- **Comentarios que ya no silencian nada.** Un `disable-next-line` que sobrevive a la línea que
  justificaba confunde a quien lea: `--report-unused-suppressions` los encuentra.
- **`disable-next-item` demasiado ancho.** Silencia todo lo que se añada después a esa función.

## 📝 Resumen

- `forge lint src` analiza el AST, sin instalar nada; `forge build` lo ejecuta al compilar.
- Por defecto, solo `high`, `med` y `low`; `--deny warnings` lo vuelve un control.
- `[lint]` en `foundry.toml` fija severidades, exclusiones, archivos ignorados y si va con el build.
- Cuatro comentarios: `disable-next-line`, `disable-line`, `disable-next-item`, `disable-start/end`.
- Con Slither en la misma línea: Slither encima, forge lint al final.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 02 — Slither](02-slither.md) | **Teoría 03 — forge lint** | [Teoría 04 — Detectores propios →](04-detectores-propios.md) |
