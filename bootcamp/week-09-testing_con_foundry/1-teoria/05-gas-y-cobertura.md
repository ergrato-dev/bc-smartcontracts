# Teoría 05 — Gas y cobertura

## 🎯 Objetivos

- Leer el informe de gas de `forge test --gas-report`.
- Guardar el gas de los tests con `forge snapshot` y detectar cambios con `--diff` y
  `--check`.
- Medir una llamada concreta con `vm.snapshotGasLastFrame`.
- Medir qué código ejecutan tus tests con `forge coverage` y entender qué no te dice.

---

## 1. Qué problema resuelve

Que los tests pasen responde a "¿hace lo que debe?". Quedan dos preguntas más:

- **¿Cuánto cuesta?** Cada llamada que escribe paga gas (semana 02). Un cambio inocente
  puede encarecer una función que se llama miles de veces. Hay que **medirlo**, y saber
  cuándo cambia.
- **¿Qué no he probado?** Una suite de 40 tests en verde puede no ejecutar nunca un `if`.
  Ese `if` es una regla sin prueba.

Forge responde a las dos con informes que salen de los mismos tests. Los ejemplos usan el
`Faucet` y el `test/Faucet.t.sol` de las teorías 01 y 02.

## 2. El informe de gas

```bash
forge test --match-path test/Faucet.t.sol --gas-report
```

```
| src/Faucet.sol:Faucet Contract |                 |       |        |       |         |
+=====================================================================================+
| Deployment Cost                | Deployment Size |       |        |       |         |
|--------------------------------+-----------------+-------+--------+-------+---------|
|                         358422 |            1447 |       |        |       |         |
|--------------------------------+-----------------+-------+--------+-------+---------|
|                                |                 |       |        |       |         |
|--------------------------------+-----------------+-------+--------+-------+---------|
| Function Name                  | Min             | Avg   | Median | Max   | # Calls |
|--------------------------------+-----------------+-------+--------+-------+---------|
| drip                           |           23885 | 41991 |  52625 | 52625 |       7 |
╰--------------------------------+-----------------+-------+--------+-------+---------╯
```

| Columna | Qué es |
| ------- | ------ |
| `Deployment Cost` | Gas de desplegar el contrato |
| `Deployment Size` | Tamaño del bytecode desplegado, en bytes |
| `Min` … `Max` | Gas de cada función en todas las llamadas que hicieron los tests |
| `# Calls` | Cuántas veces la llamaron |

`drip` cuesta 52 625 cuando paga y 23 885 en su llamada más barata, una que revierte. El
informe resume **lo que hicieron tus tests**: si ningún test prueba el caso caro, el `Max`
no lo refleja.

## 3. `forge snapshot`

El informe se lee y se olvida. Para notar cuándo cambia el gas, guárdalo en un archivo que
git compare:

```bash
forge snapshot --match-path test/Faucet.t.sol
cat .gas-snapshot
```

```
FaucetTest:test_Clock() (gas: 11859)
FaucetTest:test_Drip() (gas: 63627)
FaucetTest:test_EmitsDripped() (gas: 65564)
FaucetTest:test_RevertWhen_DripTwiceTheSameDay() (gas: 127805)
FaucetTest:test_RevertWhen_Empty() (gas: 33218)
FaucetTest:test_SendsEther() (gas: 64074)
FaucetTest:test_StateIsFreshInEachTest() (gas: 9834)
```

Es el gas de cada **test entero**, no de cada función. Ahora cambia `drip` para leer
`lastDrip[msg.sender]` una sola vez:

```solidity
uint256 last = lastDrip[msg.sender];
uint256 next = last + COOLDOWN;
if (last != 0 && block.timestamp < next) revert TooSoon(next);
```

`--diff` compara con el archivo guardado:

```bash
forge snapshot --match-path test/Faucet.t.sol --diff
```

```
━ FaucetTest::test_Clock() (gas: 11859 → 11859 | 0 0.000%)
━ FaucetTest::test_StateIsFreshInEachTest() (gas: 9834 → 9834 | 0 0.000%)
↓ FaucetTest::test_EmitsDripped() (gas: 65564 → 65390 | -174 -0.265%)
↓ FaucetTest::test_SendsEther() (gas: 64074 → 63900 | -174 -0.272%)
↓ FaucetTest::test_Drip() (gas: 63627 → 63453 | -174 -0.273%)
↓ FaucetTest::test_RevertWhen_DripTwiceTheSameDay() (gas: 127805 → 127281 | -524 -0.410%)
↓ FaucetTest::test_RevertWhen_Empty() (gas: 33218 → 33042 | -176 -0.530%)

--------------------------------------------------------------------------------
Total tests: 7, ↑ 0, ↓ 5, ━ 2
Overall gas change: -1222 (-0.325%)
```

Leer dos veces el mismo valor del storage costaba unos 170 de gas por llamada. La semana 29
explica por qué; por ahora basta con saber medirlo.

`--check` hace lo mismo pero, si algo cambió, **sale con error** (código 1) y lista las
diferencias:

```
Diff in "FaucetTest::test_EmitsDripped()": consumed "(gas: 65390)" gas, expected "(gas: 65564)" gas
```

Así un cambio de gas no pasa sin que lo veas. Si el cambio es el que querías, vuelve a
ejecutar `forge snapshot` y haz commit del `.gas-snapshot` nuevo.

**Fuzz tests en el snapshot.** Un fuzz test guarda `(runs: 256, μ: …, ~: …)`, la media y la
mediana de sus entradas. Como cada ejecución usa entradas distintas, la media cambia sola y
`--check` falla sin que toques nada. Fija la semilla en los dos comandos:
`forge snapshot --fuzz-seed 1` y `forge snapshot --fuzz-seed 1 --check`.

## 4. Medir una llamada concreta

El gas del test entero incluye `vm.prank`, los `assert` y el resto. Para una llamada sola,
`vm.snapshotGasLastFrame("nombre")` devuelve el gas de la última llamada y lo guarda en
`snapshots/<Contrato>.json`:

```solidity
function test_DripGas() public {
    vm.prank(alice);
    faucet.drip();
    uint256 used = vm.snapshotGasLastFrame("drip");
    assertLt(used, 60_000);
}
```

```bash
cat snapshots/FaucetGasTest.json
```

```json
{
  "drip": "52625"
}
```

El mismo 52 625 del informe. El `assertLt` convierte el gas en una regla: si un cambio sube
`drip` por encima de 60 000, el test falla. (Una versión anterior del cheatcode se llamaba
`snapshotGasLastCall`; forge avisa de que está obsoleta.)

## 5. Cobertura

La **cobertura** (*coverage*) mide qué partes del contrato ejecutaron los tests:

```bash
forge coverage --report summary --match-path test/Faucet.t.sol
```

```
| File            | % Lines       | % Statements    | % Branches   | % Funcs      |
| src/Faucet.sol  | 88.89% (8/9)  | 100.00% (13/13) | 75.00% (3/4) | 50.00% (1/2) |
```

| Columna | Cuenta… |
| ------- | ------- |
| `Lines` | Líneas con código que se ejecutaron |
| `Statements` | Instrucciones, más fino que líneas: una línea puede tener dos |
| `Branches` | Caminos de cada `if` o `require`: el que se cumple y el que no |
| `Funcs` | Funciones llamadas al menos una vez |

Dos huecos: `receive()` nunca se llamó (los tests le dieron saldo con `vm.deal`, no con un
envío) y el camino de `require(ok, "transfer failed")` que revierte, porque nadie rechazó el
ETH. Para ver exactamente qué falta, `--report debug` lista cada línea, instrucción y rama
con `hits: 0`.

`forge coverage` compila sin optimizar y ejecuta todos los tests: si alguno falla, no da
informe. Con `--match-path` o `--no-match-test` eliges cuáles cuentan.

## 6. Antipatrones y riesgos

- **Confundir cobertura con corrección.** 100 % dice que cada línea se ejecutó, no que se
  comprobó su resultado. Un test sin un solo `assert` sube la cobertura igual. En el
  proyecto, el registro tiene 100 % en todo y aun así hay fallos que sus tests no ven.
- **Perseguir el 100 % a cualquier precio.** Algunas ramas son defensivas (un `assert` que
  no debería poder fallar). Lo importante es que cada **regla** tenga su test, y saber
  explicar cada hueco que queda.
- **Optimizar sin medir.** Cambiar código "para ahorrar gas" sin `--diff` es adivinar. Y un
  ahorro que vuelve el código más difícil de auditar suele salir caro (semana 29).
- **Gas de un test que revierte.** Con `vm.expectRevert`, el gas mide un camino que se
  deshace. No lo uses como referencia del coste normal.

## 7. Trucos

- Versiona `.gas-snapshot` y `snapshots/`: el pull request enseña cómo cambió el gas.
- `--report lcov` genera `lcov.info`, que muchos editores pintan línea a línea.
- `forge test --gas-report` y `forge coverage` aceptan los mismos filtros que `forge test`.

## ✅ Checklist

- [ ] Leo el informe de gas y explico qué mide `Max`.
- [ ] Guardo un `.gas-snapshot`, veo el cambio con `--diff` y bloqueo cambios con `--check`.
- [ ] Mido una llamada con `vm.snapshotGasLastFrame`.
- [ ] Leo un informe de cobertura y explico por qué 100 % no significa sin fallos.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — Forks](04-forks.md) | **Teoría 05 — Gas y cobertura** | [Ejercicio 01 — Cheatcodes →](../2-practicas/ejercicio-01-cheatcodes/README.md) |
