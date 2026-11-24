# Proyecto — Altas sin ETH

> Quien tiene puntos de tu protocolo puede darse de alta pagando con ellos, pero todavía necesita
> ETH para el gas. Esta semana lo quitas: su EOA delega en una cuenta del protocolo (EIP-7702), y
> un paymaster de la DAO paga el gas de su primera alta por el EntryPoint de ERC-4337. Con reglas,
> para que el depósito no pague nada más.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana en verde; tu proyecto de la semana 31 en
`main`; la imagen reconstruida con el EntryPoint (Paso 0 del ejercicio 01).

## Capa que se añade y por qué ahora

Desde la semana 14 tu registro tiene `registerWithPermit`: un alta pagada con 30 puntos, con un
permit firmado en vez de un `approve`. Pero la transacción la envía el usuario, y el gas se paga en
ETH. Alguien que ganó puntos (o que se los pasaron) y no tiene ETH no puede usarlos.

La capa de esta semana tiene tres piezas:

- **La cuenta.** `ProtocolAccount`: `Account`, `SignerEIP7702` y `ERC7821` de OpenZeppelin, con el
  EntryPoint v0.8.0 fijo en el código (teoría 02). El usuario no despliega nada: su EOA delega en
  ella y pasa a ser una cuenta de ERC-4337 con su misma dirección y su misma clave (teoría 04).
- **El paymaster.** `RegistrationPaymaster`: paga el gas de una operación por cuenta, si es un
  `registerWithPermit` en el registro y la cuenta ya tiene los puntos (teoría 03).
- **El despliegue.** `SponsorRegistrations.s.sol`: despliega las dos, deposita 0,5 ETH en el
  EntryPoint a nombre del paymaster, le pone stake y propone a la DAO como dueña.

Ahora es cuando tienes todo lo necesario: el permit de la semana 14, el registro actualizable de la
15, los scripts de la 16, el modelo de amenazas de la 26, los mutantes de la 24 y la DAO de la 31,
que será la dueña del depósito.

Tres decisiones de diseño:

- **EIP-7702 y no una fábrica.** Con una cuenta de fábrica, el usuario tendría una dirección nueva
  sin puntos, y el permit de `LoyaltyToken` (que solo acepta ECDSA) no funcionaría desde ella
  (teoría 02). Con EIP-7702 la cuenta es la EOA: los puntos ya están ahí y la firma del permit es
  la de siempre.
- **Una sola llamada: `registerWithPermit`.** Con `registerWithPoints` harían falta dos (`approve`
  y el alta), y el paymaster tendría que entender lotes de dos. Una llamada, una regla.
- **El cupo se apunta en la validación.** Si el alta falla en la ejecución, el gas se paga igual:
  el cupo se gastó. Por eso no hay `postOp`.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-32
   ```

2. Copia el starter en `week-32/` y pon encima tus contratos, tus pruebas, tu gas guardado y tu
   informe de la semana 31:

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-32-account_abstraction/3-proyecto/starter week-32
   cp -r week-31/contracts/src week-31/contracts/script week-31/contracts/snapshots week-32/contracts/
   cp -r week-31/contracts/test/invariant week-31/contracts/test/formal week-31/contracts/test/audit week-31/contracts/test/evm week-31/contracts/test/asm week-31/contracts/test/gas week-31/contracts/test/defi week-31/contracts/test/dao week-32/contracts/test/
   cp week-31/detectors/unpaused_register.py week-32/detectors/
   cp -r week-31/audit week-32/
   ls -l week-32/contracts/lib week-32/contracts/src/RegistrationPaymaster.sol week-32/contracts/script/SponsorRegistrations.s.sol
   ```

   **Verifica**: `lib -> /opt/lib`, y los dos archivos nuevos existen: son los del starter, porque
   tu semana 31 no los tenía.

3. Entra al contenedor y mira el rojo:

   ```bash
   cd week-32
   docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
   cd contracts
   forge test --mc SponsoredTest
   ```

**Verifica**: `0 tests passed, 9 failed`. Todas las operaciones paran antes de validar nada: el
paymaster no tiene depósito.

```text
[FAIL: FailedOp(0, "AA31 paymaster deposit too low")] test_AliceRegistersWithoutEth() (gas: 160652)
[FAIL: assertion failed: 0x0000000000000000000000000000000000000000 != 0xd21060559c9beb54fC07aFd6151aDf6cFCDDCAeB] test_OnlyTheDaoWithdrawsTheDeposit() (gas: 12806)
```

## Qué hay en el starter

| Ruta | Qué es |
| ---- | ------ |
| `contracts/src/`, `contracts/script/`, `contracts/test/` (salvo `aa/`) | Los de la solución de la semana 31: tu referencia. Tú usas los tuyos |
| `contracts/src/ProtocolAccount.sol` | La cuenta para EIP-7702, completa (teoría 02) |
| `contracts/src/RegistrationPaymaster.sol` | El paymaster, con las reglas en sus `// TODO (semana 32)` |
| `contracts/script/SponsorRegistrations.s.sol` | El despliegue, con el depósito, el stake y la propiedad en su `// TODO (semana 32)` |
| `contracts/test/aa/Sponsored.t.sol` | Los nueve tests de las altas patrocinadas. **No los modifiques** |
| `contracts/test/attackers/FakeRegistry.sol` | Un contrato del atacante con la misma función que el registro |
| `contracts/foundry.toml` | El de la semana 31 con el remapping `@account-abstraction/contracts/` y sus warnings: úsalo tal cual |
| `mutants.sh` | Los veintiocho mutantes de la semana 31 y cinco nuevos, del paymaster. **No lo modifiques** |
| `test.sh`, `check-report.sh` | Los de la semana 31 |
| `detectors/` | El detector de la semana 23; pon encima el tuyo |

El `setUp` de `Sponsored.t.sol` usa tus scripts: `DeployProtocol`, las actualizaciones a V2 y V3,
`HandOverToDao` y `SponsorRegistrations`. Después, bob se da de alta cinco veces con ETH (50
puntos) y le pasa 30 a alice, que no tiene ni un wei.

## El despliegue

**Abre** `contracts/script/SponsorRegistrations.s.sol` y resuelve el `TODO`:

```solidity
s.paymaster.deposit{value: DEPOSIT}();
s.paymaster.addStake{value: STAKE}(UNSTAKE_DELAY);
s.paymaster.transferOwnership(dao);
```

El depósito paga las altas; el stake no paga nada: es la fianza que los bundlers piden a un
paymaster que guarda estado en la validación (teoría 03). `addStake` es `onlyOwner`, así que va
antes de traspasar.

`BasePaymaster` es `Ownable2Step`: `transferOwnership` solo deja a la DAO como dueña pendiente. La
DAO acepta con una propuesta que llama a `acceptOwnership()`, y hasta entonces quien firmó el
script sigue siendo el dueño. Esa propuesta es la primera que tiene que votar tu DAO.

**Verifica**: `forge test --mc SponsoredTest` da `3 tests passed, 6 failed`. Ahora el paymaster
paga, pero lo paga todo:

```text
[FAIL: assertion failed] test_AliceRegistersWithoutEth() (gas: 518383)
[FAIL: next call did not revert as expected] test_RevertWhen_SponsoringAnotherFunction() (gas: 168679)
```

El alta de alice sale, pero el paymaster no apunta que la gastó.

## Las reglas del paymaster

**Abre** `contracts/src/RegistrationPaymaster.sol`. Primero `_checkCall`, que decodifica la llamada
de ERC-7821 (teoría 02): `execute(mode, executionData)`, con `executionData` un array de
`Execution`:

```solidity
if (callData.length < 4 || bytes4(callData[:4]) != ERC7821.execute.selector) revert NotSponsored();
(bytes32 mode, bytes memory executionData) = abi.decode(callData[4:], (bytes32, bytes));
if (mode != BATCH_MODE) revert NotSponsored();
Execution[] memory calls = abi.decode(executionData, (Execution[]));
if (calls.length != 1) revert NotSponsored();
Execution memory call = calls[0];
if (call.target != address(registry) || call.value != 0) revert NotSponsored();
// casting to 'bytes4' is safe because only the first four bytes, the selector, are wanted
// forge-lint: disable-next-line(unsafe-typecast)
if (call.callData.length < 4 || bytes4(call.callData) != Registry.registerWithPermit.selector) {
    revert NotSponsored();
}
```

El comentario de `forge-lint` es necesario: `bytes4(bytes memory)` se queda con los cuatro primeros
bytes, y `forge lint` avisa de que convertir a un tipo más pequeño trunca. Aquí truncar es lo que
se quiere.

Después, `_validatePaymasterUserOp`, en este orden:

```solidity
_checkCall(userOp.callData);
if (maxCost > MAX_COST) revert TooExpensive(maxCost);
address account = userOp.sender;
if (sponsored[account]) revert AlreadySponsored(account);
if (loyalty.balanceOf(account) < pointsPrice) revert NotEnoughPoints(account);
sponsored[account] = true;
return ("", 0);
```

`pointsPrice` es `immutable`, copiado del registro en el constructor: la validación no llama al
registro, que es un proxy con su propio storage (ERC-7562). `loyalty.balanceOf(account)` sí se
puede leer: es storage asociado a la propia cuenta. Devolver `context` vacío hace que el EntryPoint
no llame a `postOp`.

**Verifica**:

```bash
forge test --mc SponsoredTest
```

`9 tests passed`. Y `forge test`, `70 tests passed, 0 failed`: los 61 de la semana 31 y los nueve
de esta. `FORGE_SNAPSHOT_CHECK=true forge test --mc RegisterGasTest` sigue en verde: las altas con
ETH no cambian de gas.

## El informe

**Abre** `week-32/audit/README.md` y añade las altas patrocinadas:

- En **Resumen**, el segundo bote de ETH: el depósito del paymaster, y qué lo protege.
- En **Alcance**, `ProtocolAccount`, `RegistrationPaymaster` y `SponsorRegistrations.s.sol` (el
  dueño que deja es una defensa). El EntryPoint v0.8.0 de eth-infinitism, fuera, como OpenZeppelin.
- En **Actores**, la cuenta delegada y el bundler. En **Activos**, el depósito del paymaster. En
  **Fronteras de confianza**, UserOperation → paymaster.
- En **Amenazas**, cinco filas nuevas:

  | Id | Amenaza | Defensa | Prueba |
  | -- | ------- | ------- | ------ |
  | T-20 | El depósito paga llamadas que no son altas | Solo `registerWithPermit` del registro, sin ETH | `test_RevertWhen_SponsoringAnotherFunction`, `test_RevertWhen_TheTargetIsNotTheRegistry` |
  | T-21 | Una cuenta vacía el depósito con muchas operaciones o mucho gas | Un alta por cuenta; tope por operación | `test_RevertWhen_SecondSponsoredRegistration`, `test_RevertWhen_GasLimitsAreHuge` |
  | T-22 | Cuentas sin puntos consiguen que se pague un alta que falla | Los puntos se comprueban en la validación | `test_RevertWhen_TheAccountHasNoPoints` |
  | T-23 | Alguien mueve lo de una cuenta delegada o retira el depósito | La cuenta solo acepta al EntryPoint y a sí misma; el depósito, solo la DAO | `test_RevertWhen_StrangerSignsTheOperation`, `test_RevertWhen_StrangerCallsTheDelegatedAccount`, `test_OnlyTheDaoWithdrawsTheDeposit` |
  | T-24 | Quien reparte 30 puntos en muchas cuentas consigue un alta patrocinada en cada una | Ninguna: riesgo aceptado | `test_AliceRegistersWithoutEth` |

- Una sección `## Altas patrocinadas (semana 32)`, antes de `## Hallazgos`, con: el flujo de una
  alta sin ETH, cada regla del paymaster y por qué, la propiedad en dos pasos, qué prueba cada
  test, qué mutante mata cada uno, y lo que no hiciste.

T-24 es un riesgo aceptado, y el informe tiene que decir por qué con números. Cada alta patrocinada
quema 30 puntos, que se ganan con tres altas con ETH. En los tests, a 1 gwei, el depósito paga
442500000000000 wei por alta patrocinada, y la tasa de un alta con ETH es 10000000000000000 wei.
Escribe con los números de tu dominio si el patrocinio sale caro o barato, y qué harías si no.

## Cómo verificar

```bash
cd /workspace
bash test.sh
```

Tarda unos minutos: Medusa y los mutantes son lo más lento. Al final:

```text
✅ patrocina cualquier destino: muerto
✅ patrocina cualquier función del registro: muerto
✅ sin cupo por cuenta: muerto
✅ patrocina a quien no tiene los puntos: muerto
✅ sin tope de gas: muerto
```

y el código de salida es 0. Por el camino, `check-report.sh` dice `✅ informe: secciones, commit,
hallazgos, gas y N pruebas citadas`, con tu N; `forge test`, `70 tests passed`; Halmos,
`Symbolic test result: 5 passed`; Slither, `0 result(s) found`; Medusa, `13 test(s) passed`; y
los treinta y tres mutantes, muertos.

## Ejemplos de adaptación

| Dominio | Quién se da de alta sin ETH | Qué patrocina el paymaster |
| ------- | --------------------------- | -------------------------- |
| Biblioteca | Un socio nuevo al que otro socio le regala puntos de lectura | Su primer préstamo pagado con puntos |
| Tienda en línea | Un cliente que recibió puntos de bienvenida | Su primer pedido canjeado con puntos |
| Cine | Un espectador con puntos de una promoción | Su primera reserva de butaca con puntos |

En los tres, la cuenta y el script son los mismos: cambian el nombre de la función patrocinada, el
precio en puntos y el tope de gas que tu dominio puede permitirse.

## Criterios de calidad (no automatizables)

- El depósito del paymaster solo paga altas: cada regla tiene un test que rompe solo esa regla.
- La validación no lee storage del registro ni usa `block.timestamp`.
- Cada amenaza nueva tiene defensa y prueba, o dice por qué se acepta, con números.
- El informe dice que hasta que la DAO acepta la propiedad, quien desplegó puede retirar el
  depósito.
- Ningún test del starter ni ningún mutante modificado para que pase.

## Entrega

1. Comprueba que `week-32/` no tiene `out/`, `cache/` ni `crytic-export/` y que sí tiene
   `contracts/snapshots/RegisterGasTest.json`.
2. Haz commit y sube la rama:

   ```bash
   git add week-32
   git commit -m "feat(week-32): sponsor registrations with a paymaster"
   git push -u origin week-32
   ```

3. Abre un pull request `week-32` → `main` y pega en la descripción la salida final de
   `bash test.sh`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Una EOA con código](../2-practicas/ejercicio-03-una-eoa-con-codigo/README.md) | **Proyecto — Altas sin ETH** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
