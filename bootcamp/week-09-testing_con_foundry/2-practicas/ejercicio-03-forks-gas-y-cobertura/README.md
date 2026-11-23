# Ejercicio 03 — Forks, gas y cobertura

> Al terminar habrás encontrado con `forge coverage` lo que una suite en verde no probaba,
> habrás guardado el gas de una llamada y habrás probado un contrato desplegado en anvil
> sobre una copia de la red, sin cambiarla.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teorías 04 y 05](../../1-teoria/04-forks.md) leídas y
[ejercicio 02](../ejercicio-02-fuzz/README.md) terminado.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/TipJar.sol` | Un bote de propinas: `tip(mensaje)` recibe ETH de cualquiera y `withdraw()` se lo envía todo al dueño. **Terminado: no lo cambies** |
| `test/TipJar.t.sol` | Dos tests escritos (`test_Tip` y `test_RevertWhen_TipIsZero`) y los de los pasos 1 y 2 |
| `test/TipJarFork.t.sol` | Los tests de los pasos 3 y 4, sobre un fork de tu anvil |

Como en los ejercicios anteriores: borra el `revert("TODO: Paso N");` y escribe las líneas
marcadas con `//> `.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-09-testing_con_foundry/2-practicas/ejercicio-03-forks-gas-y-cobertura/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con cuatro `Warning (2018)`, los de las funciones que solo revierten.

**Verifica**: `2 tests passed, 3 failed, 0 skipped (5 total tests)`. Pasan los dos tests
escritos. Fallan `test_Step1_Withdraw`, `test_Step2_TipGas` y el `setUp()` de
`TipJarForkTest`: cuando falla `setUp`, forge lo cuenta como un solo fallo y no ejecuta los
tests de ese contrato.

## Paso 1: Lo que la suite no probaba

**Por qué**: los dos tests escritos pasan. ¿Prueban todo el contrato? Pregúntaselo a
`forge coverage`. Como no da informe si algún test falla, deja fuera los de los pasos:

```bash
forge coverage --report summary --match-path test/TipJar.t.sol --no-match-test Step
```

```
| File           | % Lines       | % Statements  | % Branches   | % Funcs      |
| src/TipJar.sol | 50.00% (7/14) | 37.50% (6/16) | 25.00% (1/4) | 66.67% (2/3) |
```

`withdraw` no se ejecutó nunca: la mitad del contrato, y la parte que mueve el dinero, sin
probar. `--report debug` lo confirma línea a línea con `hits: 0`.

**Abre** `test/TipJar.t.sol`, en `test_Step1_Withdraw`, y prueba sus tres caminos: alguien
que no es el dueño, un bote vacío y una retirada que funciona. El dueño es el contrato de
test (lo desplegó en `setUp`); por eso el test trae un `receive()`, para poder cobrar.

```solidity
vm.prank(alice);
vm.expectRevert(abi.encodeWithSelector(TipJar.NotOwner.selector, alice));
jar.withdraw();

vm.expectRevert(TipJar.NothingToWithdraw.selector);
jar.withdraw();

hoax(alice, 1 ether);
jar.tip{value: 0.5 ether}("hola");
uint256 before = address(this).balance;
jar.withdraw();
assertEq(address(this).balance - before, 0.5 ether);
assertEq(address(jar).balance, 0);
```

**Verifica**:

```bash
forge coverage --report summary --match-path test/TipJar.t.sol --no-match-test Step2
```

```
| File           | % Lines         | % Statements   | % Branches   | % Funcs       |
| src/TipJar.sol | 100.00% (14/14) | 93.75% (15/16) | 75.00% (3/4) | 100.00% (3/3) |
```

Todas las líneas, pero no todas las ramas. Con `--report debug` verás la que falta:

```
- Branch (branch: 3, path: 0) (location: (source ID: 19, lines: 42..43, bytes: 1620..1652), hits: 0) -> "if (!ok) revert TransferFailed()"
```

Para cubrirla, el dueño tendría que rechazar el ETH: un bote desplegado desde un contrato
sin `receive`. Es una rama defensiva; puedes escribir ese test como reto, o dejarla
anotada y saber explicar por qué no está cubierta.

## Paso 2: Medir una llamada

**Por qué**: el informe de gas te da un resumen de todas las llamadas a `tip`. Para seguir
un caso concreto, `vm.snapshotGasLastFrame` mide la última llamada y la guarda con nombre en
`snapshots/TipJarTest.json`, que se versiona. Las dos propinas de alice no cuestan lo mismo
y el test lo deja escrito.

```solidity
hoax(alice, 1 ether);
jar.tip{value: 0.1 ether}("primera");
uint256 first = vm.snapshotGasLastFrame("tip-first");

vm.prank(alice);
jar.tip{value: 0.1 ether}("segunda");
uint256 second = vm.snapshotGasLastFrame("tip-second");

assertLt(second, first);
assertLt(first, 80_000);
```

**Verifica**: `forge test --match-path test/TipJar.t.sol` pasa los 4 tests y
`cat snapshots/TipJarTest.json` muestra:

```json
{
  "tip-first": "69441",
  "tip-second": "35241"
}
```

La primera propina escribe `totalTips` y `tipsOf[alice]` cuando valen 0; la segunda, cuando
ya tienen valor. Pasar un valor del storage de 0 a distinto de 0 es de lo más caro que hace
la EVM; la semana 29 da los números. Compara con el resumen:

```bash
forge test --match-path test/TipJar.t.sol --gas-report
```

En la fila de `tip` verás `Max` 69441, el de la primera propina, y `Min` 22300, el de la
que revierte en `test_RevertWhen_TipIsZero`.

## Paso 3: Probar sobre un fork de anvil

**Por qué**: hasta ahora el bote se creaba en `setUp`. Ahora vas a probar uno desplegado
de verdad en anvil, con propinas que dejas tú con `cast`, sobre una copia.

Arranca anvil, despliega desde la cuenta 0 y deja una propina:

```bash
anvil --silent &
PK=$(cast wallet private-key "test test test test test test test test test test test junk" 0)
forge create src/TipJar.sol:TipJar --private-key "$PK" --broadcast
```

```
Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
Transaction hash: 0x7c617fa5f63f00704cb9ce87ad6fdd75e8225cec3209aec94bb8cfc832fcf695
```

```bash
cast block-number
cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "tip(string)" "hola" --value 0.05ether --private-key "$PK"
```

`cast block-number` responde `1`: el bloque del despliegue. Apúntalo, lo usas en el paso
4. El recibo de la propina dice `status 1 (success)`.

**Abre** `test/TipJarFork.t.sol`, en `setUp`. Sin la variable `FORK_URL` el test se salta;
con ella, abre el fork y toma la dirección del bote de `TIP_JAR`:

```solidity
string memory url = vm.envOr("FORK_URL", string(""));
vm.skip(bytes(url).length == 0, "sin FORK_URL");
vm.createSelectFork(url);
jar = TipJar(vm.envAddress("TIP_JAR"));
```

`test_Step3_TipOnFork` ya está escrito: lee el total que dejaste con `cast` y deja otra
propina, de carol, en la copia.

**Verifica**:

```bash
export FORK_URL=http://127.0.0.1:8545 TIP_JAR=0x5FbDB2315678afecb367f032d93F642f64180aa3
forge test --match-path test/TipJarFork.t.sol
```

`[PASS] test_Step3_TipOnFork() (gas: 81483)`, y `test_Step4_RollFork` en `FAIL` con su
`TODO`. Ahora pregunta a anvil:

```bash
cast call "$TIP_JAR" "totalTips()(uint256)"
```

```
50000000000000000 [5e16]
```

Los 0,05 ether de tu propina. Los 0,2 de carol existieron solo en la copia.

## Paso 4: Viajar a otro bloque

**Por qué**: un fork se puede mover. En el bloque anterior al despliegue no hay código en esa
dirección; en el del despliegue hay código pero aún no hay propinas. Así compruebas el
estado del contrato en un momento concreto de su historia.

```solidity
uint256 deployBlock = vm.envUint("DEPLOY_BLOCK");
vm.rollFork(deployBlock - 1);
assertEq(address(jar).code.length, 0);
vm.rollFork(deployBlock);
assertGt(address(jar).code.length, 0);
assertEq(jar.totalTips(), 0);
```

**Verifica**: con el bloque del paso 3,

```bash
export DEPLOY_BLOCK=1
forge test
```

```
Ran 2 test suites in 33.87ms (33.50ms CPU time): 6 tests passed, 0 failed, 0 skipped (6 total tests)
```

Y sin el nodo, `unset FORK_URL` y `forge test`:
`4 tests passed, 0 failed, 1 skipped (5 total tests)`, sin warnings. La suite no depende
de que haya una red.

## ✅ Criterios de éxito

- `forge test` pasa sin warnings, con y sin `FORK_URL`.
- Explicas por qué 100 % de líneas no es 100 % de ramas, con la rama que queda en
  `TipJar`.
- Explicas por qué la segunda propina cuesta menos que la primera.
- Explicas por qué el total de anvil no cambió después del test de fork.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Fuzz testing](../ejercicio-02-fuzz/README.md) | **Ejercicio 03 — Forks, gas y cobertura** | [Proyecto — Registro a prueba de fuzzing →](../../3-proyecto/README.md) |
