# Teoría 02 — Slither

## 🎯 Objetivos

- Ejecutar Slither sobre un proyecto Foundry y leer cada parte de un hallazgo.
- Filtrar lo que no importa con opciones y con `slither.config.json`, y hacer que falle en un
  script.
- Silenciar un hallazgo en una línea, con su justificación.
- Usar las impresoras para resumir un contrato antes de auditarlo.

## Slither en la imagen

[Slither](https://github.com/crytic/slither) es el analizador estático de Trail of Bits, escrito
en Python. La imagen del bootcamp trae la versión `0.11.5`, instalada como herramienta de uv
(`uv tool install`) con su propio entorno de Python: no se mezcla con las dependencias del
indexador de la semana 19.

```bash
slither --version
```

Imprime `0.11.5`. Slither no compila por su cuenta: usa **crytic-compile**, que reconoce un
proyecto Foundry por su `foundry.toml` y llama a forge. Al ejecutarlo lo ves en las primeras
líneas:

```text
'forge clean' running (wd: /workspace)
'forge config --json' running
'forge build --build-info --skip ./test/** ./script/** --force' running (wd: /workspace)
```

Tres cosas que salen de ahí:

- **Borra `out/` y `cache/`** (`forge clean`) y recompila todo. En un proyecto grande tarda.
- **No analiza `test/` ni `script/`**: solo lo que se despliega. Los atacantes y los mocks de los
  tests no ensucian el informe.
- **Lee el `--build-info`**: el AST de solc para cada archivo. Si el proyecto no compila, Slither
  tampoco.

## Ejecutarlo y leer un hallazgo

Desde la carpeta que tiene el `foundry.toml`, en el contenedor:

```bash
cd bootcamp/week-23-analisis_estatico/2-practicas/ejercicio-01-slither/starter/contracts
slither .
```

Cada hallazgo empieza por `Detector:` y su nombre. El primero del ejercicio 01:

```text
Detector: reentrancy-eth
Reentrancy in Crowdfund.refund() (src/Crowdfund.sol#72-84):
	External calls:
	- (ok,None) = msg.sender.call{value: amount}() (src/Crowdfund.sol#78)
	State variables written after the call(s):
	- contributed[msg.sender] = 0 (src/Crowdfund.sol#80)
	Crowdfund.contributed (src/Crowdfund.sol#24) can be used in cross function reentrancies:
	- Crowdfund.claimReward() (src/Crowdfund.sol#87-93)
	- Crowdfund.contribute() (src/Crowdfund.sol#48-55)
	- Crowdfund.contributed (src/Crowdfund.sol#24)
	- Crowdfund.refund() (src/Crowdfund.sol#72-84)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-1
```

- La primera línea dice **qué** y **dónde**: la función y sus líneas (`#72-84`).
- Después, **por qué**: la llamada externa (línea 78) y la variable escrita después (línea 80).
- Además avisa de la **reentrancy entre funciones** (semana 21): `contributed` la leen también
  `claimReward` y `contribute`, así que quien vuelve a entrar puede hacerlo por cualquiera de ellas.
- `Reference` lleva a la documentación del detector: qué busca, un ejemplo de ataque y cómo se
  corrige. Léela la primera vez que veas un detector.

La última línea resume: `INFO:Slither:. analyzed (6 contracts with 101 detectors), 21 result(s)
found` sin configuración. Los 6 contratos incluyen los de OpenZeppelin que importa `Crowdfund`.

## Los detectores

```bash
slither --list-detectors
```

Imprime una tabla con los 101: número, nombre, qué detecta, impacto y confianza. Algunas filas:

```text
| 25  | reentrancy-eth                | Reentrancy vulnerabilities (theft of ethers)  | High          | Medium     |
| 28  | unchecked-transfer            | Unchecked tokens transfer                     | High          | Medium     |
| 34  | incorrect-equality            | Dangerous strict equalities                   | Medium        | High       |
| 53  | tx-origin                     | Dangerous usage of `tx.origin`                | Medium        | Medium     |
| 70  | missing-zero-check            | Missing Zero Address Validation               | Low           | Medium     |
| 74  | timestamp                     | Dangerous usage of `block.timestamp`          | Low           | Medium     |
| 85  | naming-convention             | Conformity to Solidity naming conventions     | Informational | High       |
| 97  | constable-states              | State variables that could be declared constant | Optimization | High      |
```

(Recortada: la salida real tiene la columna del medio más ancha.) Van ordenados por impacto y confianza:
los primeros son los que más importan.

## Filtrar

Sin filtros, Slither informa de todo, también de OpenZeppelin y del estilo. Las opciones que más
se usan:

| Opción | Qué quita |
| ------ | --------- |
| `--exclude-dependencies` | Los hallazgos que están solo en dependencias (`/opt/lib`, `lib/`) |
| `--exclude-informational` | Impacto `Informational`: nombres, versiones de `pragma`, llamadas de bajo nivel |
| `--exclude-optimization` | Impacto `Optimization`: gas |
| `--exclude-low` | Impacto `Low` |
| `--filter-paths "src/mocks"` | Lo que esté en rutas que casen con esa expresión regular |
| `--detect reentrancy-eth,tx-origin` | Todos los demás: solo ejecuta los que nombras |
| `--exclude timestamp` | Ese detector |

`naming-convention` merece un comentario: avisa de que `REWARD` no está en `mixedCase`. El
bootcamp escribe los `immutable` en mayúsculas, como pide forge lint
(`screaming-snake-case-immutable`). Las dos herramientas no se ponen de acuerdo, y es
informativo: se excluye.

## Hacer que falle

Para usar Slither en un `test.sh` o en CI necesitas que termine con error si encuentra algo:

| Opción | Termina con error si hay hallazgos de impacto... |
| ------ | ------------------------------------------------ |
| `--fail-pedantic` | Cualquiera (es lo que hace sin ninguna opción) |
| `--fail-low` | Bajo, medio o alto |
| `--fail-medium` | Medio o alto |
| `--fail-high` | Alto |
| `--fail-none` | Nunca |

## `slither.config.json`

Repetir las opciones en cada ejecución es fácil de olvidar. Slither lee `slither.config.json` de
la carpeta donde lo ejecutas. Cada clave es una opción, con `_` en vez de `-`, salvo el umbral de
fallo, que es una sola clave, `fail_on`, con `pedantic`, `low`, `medium`, `high` o `none`:

```json
{
  "exclude_dependencies": true,
  "exclude_informational": true,
  "exclude_optimization": true,
  "fail_on": "low"
}
```

Es la configuración de los ejercicios y del proyecto: no mira OpenZeppelin, ignora estilo y gas,
y falla desde impacto bajo. Con ella, el ejercicio 01 pasa de 21 hallazgos a 8. Una clave mal
escrita no da error: Slither imprime `slither.config.json has an unknown key` y la ignora. Mira
esa línea la primera vez que uses una configuración. Para ejecutar sin ella:
`slither . --config-file /dev/null`.

## Silenciar en una línea

Un falso positivo o un riesgo aceptado se silencia con un comentario en la línea **anterior**:

```solidity
// Unos segundos de margen no cambian nada en una campaña de días.
// slither-disable-next-line timestamp
if (block.timestamp >= DEADLINE) revert CampaignEnded();
```

- El comentario va **justo encima** de una de las líneas que cita el hallazgo: la de la llamada,
  la de la comparación o la de la asignación.
- Puedes dar varios detectores separados por comas: `incorrect-equality,timestamp`.
- Para un bloque entero: `// slither-disable-start timestamp` y `// slither-disable-end timestamp`.
- `slither . --show-ignored-findings` enseña también los silenciados: sirve para revisar que cada
  silencio sigue teniendo sentido.

Cuando la misma línea necesita también un comentario de forge lint, los dos no caben "justo
encima". La teoría 03 lo resuelve.

## Las impresoras

Además de detectores, Slither tiene **impresoras** (*printers*): resúmenes del código que no
buscan fallos, pero te orientan antes de leer. `slither --list-printers` lista las 27 que trae.
Dos que vas a usar:

`--print human-summary` resume el proyecto: líneas de código propias y de dependencias, líneas
de assembly, cuántos hallazgos hay de cada impacto, y por contrato cuántas funciones tiene, qué
ERC implementa y si recibe o envía ETH o usa tokens. En el ejercicio 01, `Crowdfund` sale con 8
funciones, `Receive ETH`, `Send ETH` y `Tokens interaction`, y 2 hallazgos altos, 2 medios y 4
bajos.

`--print vars-and-auth` dice, por función, qué variables de estado escribe y qué condiciones pone
sobre `msg.sender`. En el ejercicio 01 (recortada a cuatro filas):

```text
| Function       | State variables written   | Conditions on msg.sender |
| contribute     | ['contributed', 'raised'] | []                       |
| withdraw       | []                        | ['msg.sender != owner']  |
| refund         | ['contributed']           | []                       |
| setOwner       | ['owner']                 | []                       |
```

`setOwner` escribe `owner` y no tiene **ninguna** condición sobre `msg.sender`: mira `tx.origin`.
Es la tabla de control de acceso de la semana 21, hecha en un segundo. Cualquier función que
escriba algo importante con la última columna vacía merece una lectura.

`--print slithir` imprime la representación intermedia de cada función: la usa la teoría 04.

## La salida en JSON

`slither . --json -` imprime los hallazgos en JSON por la salida estándar (con un nombre de
archivo en vez de `-`, lo guarda ahí). Cada hallazgo de `.results.detectors` tiene `check` (el
detector), `impact`, `confidence`, `description`, `elements` (las funciones, nodos y variables
implicados, con su ubicación) y `first_markdown_element`:

```bash
slither . --json - 2>/dev/null | jq -c '.results.detectors[0] | {check, impact, confidence, first_markdown_element}'
```

```json
{"check":"reentrancy-eth","impact":"High","confidence":"Medium","first_markdown_element":"src/Crowdfund.sol#L72-L84"}
```

Sirve para llevar los hallazgos a una tabla del informe sin copiarlos a mano.

## ⚠️ Riesgos

- **`forge clean` en cada ejecución.** Slither borra `out/` y `cache/`. Si tenías un despliegue a
  medias que dependía de ellos, vuelve a compilar.
- **Un proyecto que no compila no se analiza.** El error de Slither es poco claro
  (`InvalidCompilation`); ejecuta antes `forge build` y lee su error.
- **Excluir detectores en la configuración** (`"detectors_to_exclude"`) silencia también los
  hallazgos verdaderos futuros. Usa el comentario en la línea.
- **El JSON y el informe dicen lo que Slither entiende**, no lo que el código hace: cada hallazgo
  sigue necesitando tu veredicto.

## 📝 Resumen

- `slither .` compila con forge (sin `test/` ni `script/`) y pasa 101 detectores.
- Cada hallazgo dice detector, función, líneas y por qué, con un enlace a su documentación.
- `slither.config.json` fija los filtros y el umbral de fallo; `--fail-low` lo vuelve un control.
- `// slither-disable-next-line <detector>` silencia una línea; escribe el porqué encima.
- `vars-and-auth` resume quién escribe qué y con qué permiso.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 01 — Qué es el análisis estático](01-que-es-el-analisis-estatico.md) | **Teoría 02 — Slither** | [Teoría 03 — forge lint →](03-forge-lint.md) |
