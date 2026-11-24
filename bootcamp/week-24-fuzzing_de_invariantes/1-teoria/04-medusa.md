# Teoría 04 — Medusa

## 🎯 Objetivos

- Ejecutar Medusa sobre un proyecto Foundry y leer su resultado.
- Escribir un harness: un contrato que despliega el sistema, ofrece las acciones y declara las
  propiedades.
- Distinguir las pruebas de propiedad de las pruebas de aserción.
- Configurar `medusa.json` y saber en qué se diferencia Medusa de forge.

## Medusa en la imagen

**Medusa** es el fuzzer de Trail of Bits, los autores de Slither. Es un programa aparte, escrito
en Go, que compila tu proyecto, despliega un contrato y lo llama en secuencias, como el fuzzer de
invariantes de forge. La imagen trae la versión `1.5.0`, verificada con su sha256:

```bash
medusa --version
```

```text
medusa version 1.5.0
```

Medusa solo publica binarios para Linux x64: en un Mac con Apple Silicon, la imagen arm64 no lo
trae. Para compilar usa `crytic-compile`, la misma biblioteca que usa Slither, que a su vez llama
a `forge build`.

## El harness

Medusa no tiene `setUp` ni `targetContract`. Despliega los contratos que le digas en
`medusa.json` **sin argumentos**, y llama a sus funciones. Así que el contrato que despliega es un
**harness**: en su constructor despliega el sistema, y sus funciones son las acciones, como un
handler.

```solidity
import {Vm} from "forge-std/Vm.sol";

contract VestingProperties {
    // La dirección de los cheatcodes, la misma en forge y en Medusa.
    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    Token internal token;
    Vesting internal vesting;

    constructor() {
        token = new Token();
        vesting = new Vesting(token, address(this), 365 days, 1_000_000e18);
        token.mint(address(vesting), 1_000_000e18);
    }

    function release() external {
        uint256 releasedBefore = vesting.released();
        uint256 amount = vesting.release();
        assert(vesting.released() == releasedBefore + amount);
    }

    function property_receivedWithinVested() external view returns (bool) {
        return token.balanceOf(address(this)) <= vesting.vested(block.timestamp);
    }
}
```

**Dónde**: en `test/VestingProperties.sol` del ejercicio 03. No hereda de `Test`: declara `vm`
él mismo, porque los cheatcodes de Medusa están en la misma dirección que los de forge.

Medusa prueba dos cosas a la vez:

| Prueba | Cómo se escribe | Cuándo falla |
| ------ | --------------- | ------------ |
| **De propiedad** (*property*) | Una función `property_` sin parámetros que devuelve `bool` | Tras cualquier llamada, devuelve `false` o revierte |
| **De aserción** (*assertion*) | Un `assert` en cualquier función del harness | La llamada acaba en `assert` fallido |

Las propiedades son tus invariantes. Las aserciones comprueban una acción concreta: en
`release`, que lo enviado sea justo lo que sube `released`. Un `revert` normal o un `require` no
cuentan como fallo de aserción: solo `assert` (con la configuración por defecto).

## `medusa.json`

`medusa init` escribe la configuración por defecto en `medusa.json`. Las claves que cambia esta
semana:

| Clave | Por defecto | Esta semana | Para qué |
| ----- | ----------- | ----------- | -------- |
| `fuzzing.targetContracts` | `[]` | `["VestingProperties"]` | Los contratos que despliega y llama |
| `fuzzing.workers` | `10` | `4` | Procesos en paralelo |
| `fuzzing.testLimit` | `0` (sin límite) | `50000` | Para tras tantas llamadas |
| `fuzzing.timeout` | `0` (sin límite) | `120` | Y, en todo caso, tras tantos segundos |
| `fuzzing.testing.testViewMethods` | `true` | `false` | Sin pruebas de aserción sobre las funciones `view` del harness |
| `compilation.platformConfig.args` | `[]` | `["--foundry-compile-all"]` | Compilar también `test/`, donde está el harness |
| `slither.useSlither` | `true` | `false` | Sin pasar Slither antes, ni su caché `slither_results.json` |

Sin límites, Medusa sigue hasta que lo paras con Ctrl+C. Por defecto, para en el primer fallo
(`stopOnFailedTest`). Y por defecto llama desde tres cuentas, `0x10000`, `0x20000` y `0x30000`, y
despliega desde la última.

Dos ajustes que necesita un proyecto Foundry:

- **`--foundry-compile-all`.** Sin él, crytic-compile no compila `test/` y Medusa dice `no
  assertion, property, optimization, or custom tests were found to fuzz`.
- **`dynamic_test_linking = false`** en `foundry.toml`. Con el valor por defecto de forge 1.9,
  crytic-compile falla con `Unknown file: foundry-pp/DeployHelper...sol`, un archivo auxiliar que
  forge genera para los tests.

## Ejecutarlo

**Dónde**: en la raíz del ejercicio, dentro del contenedor.

```bash
medusa fuzz --config medusa.json --no-color
```

Con el fallo del vesting sin corregir, en unos 10 segundos:

```text
⇾ [FAILED] Property Test: VestingProperties.property_receivedWithinVested()
Test for method "VestingProperties.property_receivedWithinVested()" failed after the following call sequence:
[Call Sequence]
1) VestingProperties.release()() (block=13, time=13, gas=12500000, gasprice=0, value=0, sender=0x20000)
2) VestingProperties.release()() (block=13, time=13, gas=12500000, gasprice=0, value=0, sender=0x20000)
3) VestingProperties.release()() (block=13, time=13, gas=12500000, gasprice=0, value=0, sender=0x10000)
```

Debajo vienen dos trazas: la de la última llamada de la secuencia y la de la propiedad que
falló, con cada valor que devolvió:

```text
[Property Test Execution Trace]
 => [call] VestingProperties.property_receivedWithinVested()() ...
	 => [call] Vesting.vested(uint256)(13) ...
		 => [return (380517503805175038)]
	 => [call] Token.balanceOf(address)(0xA647ff3c36cFab592509E13860ab8c4F28781a66) ...
		 => [return (761035007610350076)]
	 => [return (false)]
```

Liberado, 0,38 tokens; recibido, el doble. Con el fallo corregido:

```text
⇾ fuzz: elapsed:       3s, calls:      74586 ( 24855/sec), seq/s:    247, branches:    321, corpus:     3, failures: 0/744, gas/s:    890846669
⇾ Transaction test limit reached, halting now...
⇾ [PASSED] Assertion Test: VestingProperties.release()
⇾ [PASSED] Assertion Test: VestingProperties.skipTime(uint256)
⇾ [PASSED] Property Test: VestingProperties.property_receivedWithinVested()
⇾ Test summary: 3 test(s) passed, 0 test(s) failed
⇾ html report(s) saved to: crytic-export/coverage/coverage_report.html
```

- **`calls`** y **`seq/s`**: llamadas hechas y secuencias por segundo.
- **`branches`**: ramas del código alcanzadas. Medusa guarda en su **corpus** las secuencias que
  llegan a ramas nuevas y las muta para ir más lejos: es un fuzzer **guiado por cobertura**.
- **`failures: 0/744`**: secuencias que fallaron, de las probadas.
- **El informe HTML** marca línea a línea qué alcanzó. Ábrelo en tu navegador: lo que no está
  marcado, no lo ha probado.

Medusa termina con código 0 si todo pasa y con otro si algo falla (7 con una prueba fallida), así
que funciona en un `test.sh`. No tiene semilla fija: dos ejecuciones dan secuencias distintas.

## Medusa no es forge

El mismo harness funciona en los dos, con diferencias que hay que conocer:

| | forge | Medusa |
| - | ----- | ------ |
| El reloj | No se mueve: el harness necesita una acción con `vm.warp` | Avanza número de bloque y timestamp entre llamadas (hasta 7 días por llamada) |
| Cheatcodes | Todos | Un subconjunto: `warp`, `roll`, `deal`, `prank`, `startPrank`, `store`, `load`... Sin `vm.startBroadcast` ni `vm.computeCreateAddress` |
| `value` con `vm.prank` | Sale de la cuenta del prank | Sale de quien llama de verdad, el harness |
| Invariantes | `invariant_` en un contrato de test | `property_` en el harness |
| Entrada | Aleatoria con diccionario de valores del código | Guiada por cobertura, con corpus |

Cada fila te va a pasar. El handler del proyecto despliega el protocolo en su constructor sin
`vm.startBroadcast`, calcula la dirección del proxy sin `vm.computeCreateAddress` (con la fórmula
de CREATE de la semana 10), y da ETH también al handler para que Medusa pueda pagar las tasas.
Un cheatcode que Medusa no tiene hace revertir la llamada; si es en el constructor, Medusa no
llega a empezar:

```text
error Failed to initialize the test chain
‣ deploying RegistryProperties returned a failed status: execution reverted
```

Para usar el mismo harness en forge, el test de invariantes lo pone como objetivo y comprueba sus
propiedades:

```solidity
function setUp() public {
    props = new VestingProperties();
    targetContract(address(props));
}

function invariant_ReceivedWithinVested() public view {
    assertTrue(props.property_receivedWithinVested());
}
```

## ⚠️ Riesgos

- **Una campaña sin límite.** Sin `testLimit` ni `timeout`, un `test.sh` con Medusa no termina.
- **Un harness que revierte en el constructor.** Medusa no prueba nada y lo dice una sola vez,
  al principio. Lee la salida.
- **Fiarse del reloj.** Medusa mueve el tiempo y forge no: un oráculo con plazo de horas, como el
  de tu `RegistryV3`, se queda antiguo enseguida en Medusa y nunca en forge.
- **Mirar solo el resumen.** `[PASSED]` sobre código que el informe de cobertura no marca no dice
  nada de ese código.

## 📝 Resumen

- Medusa despliega un harness sin argumentos y lo llama en secuencias guiadas por cobertura.
- Las propiedades son funciones `property_` que devuelven `bool`; las aserciones, `assert` en las
  acciones.
- `medusa.json` fija objetivo, límites y compilación; un proyecto Foundry necesita
  `--foundry-compile-all` y `dynamic_test_linking = false`.
- El mismo harness sirve a forge y a Medusa, con cuidado con el reloj, los cheatcodes y el
  `value` de `vm.prank`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 03 — Handlers](03-handlers.md) | **Teoría 04 — Medusa** | [Ejercicio 01 — Invariantes →](../2-practicas/ejercicio-01-invariantes/README.md) |
