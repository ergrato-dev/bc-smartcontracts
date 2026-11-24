# Teoría 03 — Handlers

## 🎯 Objetivos

- Explicar por qué el fuzzer, llamando al contrato directamente, casi no prueba nada.
- Escribir un handler: cuentas, entradas acotadas y acciones que no revierten.
- Llevar la cuenta de lo que debería haber con variables fantasma.
- Probar también lo que el protocolo debe rechazar.
- Comprobar con mutantes que tus invariantes atrapan fallos.

## Un vault que pasa sin probar nada

El vault del ejercicio 02 guarda un token y da participaciones. Con el vault como objetivo
directo, una invariante sencilla pasa:

```text
[PASS] invariant_SharesBackedByAssets() (runs: 256, calls: 128000, reverts: 128000)
| Vault    | deposit  | 63806 | 63806   | 0        |
| Vault    | withdraw | 64194 | 64194   | 0        |
```

Las 128 000 llamadas revierten. Las cuentas que elige el fuzzer no tienen tokens ni han dado
allowance, así que `deposit` falla siempre; sin depósitos, `withdraw` también. El vault nunca
sale del estado de `setUp`, y la invariante pasa porque no hay nada que comprobar.

## El handler

Un **handler** es un contrato que se pone entre el fuzzer y el protocolo. El fuzzer llama al
handler; cada función del handler es una **acción** que prepara lo que hace falta y llama al
protocolo de forma que tenga sentido:

```solidity
contract VaultHandler is Test {
    Token public token;
    Vault public vault;
    address[] public actors;

    // Lo que el vault debería tener, según el handler.
    uint256 public ghostDeposited;

    constructor(Token token_, Vault vault_) {
        token = token_;
        vault = vault_;
        actors.push(makeAddr("alice"));
        actors.push(makeAddr("bob"));
        actors.push(makeAddr("carol"));
    }

    function deposit(uint256 actorSeed, uint256 assets) external {
        address actor = actors[actorSeed % actors.length];
        assets = bound(assets, 1, 1_000_000e18);
        token.mint(actor, assets);
        vm.startPrank(actor);
        token.approve(address(vault), assets);
        vault.deposit(assets);
        vm.stopPrank();
        ghostDeposited += assets;
    }
}
```

Y en el test, el objetivo es el handler y nada más:

```solidity
handler = new VaultHandler(token, vault);
targetContract(address(handler));
```

![El handler entre el fuzzer y el protocolo: el fuzzer llama a una acción con números aleatorios; el handler elige una de sus cuentas, acota la entrada con bound, prepara saldo y allowance, llama al protocolo con vm.prank y, si sale bien, actualiza sus variables fantasma; tras cada llamada, las invariantes comparan el estado del protocolo con las variables fantasma](../0-assets/02-handler.svg)

Las cuatro piezas de un handler:

| Pieza | En el ejemplo | Para qué |
| ----- | ------------- | -------- |
| **Cuentas** (*actors*) | `actors[actorSeed % actors.length]` | Pocas cuentas fijas: la que deposita es la que retira, y sus saldos se pueden sumar en una invariante |
| **Entradas acotadas** | `bound(assets, 1, 1_000_000e18)` | El `bound` de la semana 09: valores con sentido sin descartar la entrada |
| **Precondiciones** | `mint` y `approve` antes de `deposit` | La llamada al protocolo no revierte por falta de saldo o de allowance |
| **Variables fantasma** (*ghost variables*) | `ghostDeposited += assets` | La cuenta, llevada aparte, de lo que el protocolo debería tener |

El número que recibe una acción (`actorSeed`) no es una cuenta: es una semilla para elegir una de
las tuyas. Y las acciones no tienen que ser solo de usuarios: en el ejercicio 02, `addYield`
manda tokens al vault sin depositar, como haría un rendimiento. Sin esa acción, el precio de una
participación siempre es 1 y el fallo del vault no se ve nunca.

Con el handler, el mismo vault:

```text
[FAIL: assertion failed: 1839503193972906336940995 != 1827302886870147413019674] invariant_SharesAddUp
	[Sequence] (original: 19, shrunk: 4)
		... calldata=deposit(uint256,uint256) args=[1, 100000000000000000000000 [1e23]]
		... calldata=addYield(uint256) args=[1000000000000000000000000 [1e24]]
		... calldata=deposit(uint256,uint256) args=[21838953708549868168146491371012655290136 [2.183e40], ...]
		... calldata=withdraw(uint256,uint256) args=[1000000000000000000000000 [1e24], 1000000000000000000000000 [1e24]]
```

Los argumentos que ves son los que eligió el fuzzer, **antes** del `bound`: `2.183e40` es una
semilla de cuenta, y `1e24` en `withdraw` se acota a las participaciones que tiene la cuenta.

## Variables fantasma

Una variable fantasma es estado del handler que no existe en el protocolo. Cuenta lo que debería
haber, con la información que tiene el handler y el protocolo no:

```solidity
function invariant_AssetsAccounted() public view {
    assertEq(vault.totalAssets(), handler.ghostDeposited() + handler.ghostYield() - handler.ghostWithdrawn());
}
```

Regla: **se actualiza solo cuando la acción sale bien**, y después de la llamada al protocolo. Si
el handler suma antes y la llamada revierte, la variable fantasma cuenta algo que no pasó.

## Cuándo saltarse una acción

A veces el protocolo va a rechazar la acción, y es lo correcto: retirar 0 participaciones,
depositar tan poco que da 0 participaciones. El handler tiene dos opciones:

1. **Saltársela** con un `return`, como `withdraw` del ejercicio 02 con `shares == 0`. Es lo más
   simple, pero esa rama del protocolo no se prueba nunca.
2. **Intentarla y comprobar que se rechaza.** Es lo que hace el handler de tu protocolo con las
   altas:

```solidity
bool allowed = _canRegister(actor, 1);
vm.prank(actor);
bool accepted;
try registry.register{value: value}("item") {
    accepted = true;
} catch {}
assert(accepted == allowed);
if (accepted) ghostFeesPaid += fee;
```

El `assert` falla en los dos sentidos: si el registro acepta un alta que tenía que rechazar, y si
rechaza una que tenía que aceptar. Forge 1.9 detecta un `assert` que falla dentro de un handler y
lo informa aparte:

```text
Assertion Tests: 1 assertion bug(s) found
[FAIL: panic: assertion failed (0x01)] test/VestingProperties.sol:VestingProperties::release
```

La primera versión del handler del proyecto se saltaba las altas cuando la cuenta llegaba a su
máximo. Pasaba todas las invariantes, y también con el límite roto a propósito: nunca intentaba la
alta que sobra.

## `fail_on_revert`

Con un handler, ninguna llamada debería revertir: el handler sabe cuándo el protocolo va a
rechazar algo y no lo intenta, o lo intenta dentro de un `try`. Con
`fail_on_revert = true`, una llamada del handler que revierte es un fallo: o el handler no sabe
cuándo revierte el protocolo, o el protocolo revierte cuando no debe.

```solidity
/// forge-config: default.invariant.fail-on-revert = true
contract RegistryInvariantsTest is Test {
```

Sin handler no tiene sentido: con el vault como objetivo directo fallaría en cuanto una llamada
revirtiera, es decir, enseguida.

## El handler también es código

Un fallo en el handler da falsas alarmas o esconde fallos de verdad. Dos que aparecieron al
escribir el del proyecto:

- **Un `startPrank` que no se cierra.** Si el `assert` va antes del `vm.stopPrank()`, al fallar
  deja el prank activo y la llamada siguiente falla con `vm.prank: cannot override an ongoing
  prank`. El `stopPrank` va antes del `assert`.
- **Saltarse lo que debe fallar**, como el límite por cuenta de arriba.

Y lo que el handler no hace, no se prueba: si no tiene una acción para `registerBySig`, ninguna
invariante dice nada de las altas por firma. Escríbelo en el informe.

## Mutantes

¿Cómo sabes que tus invariantes atrapan fallos, si con el protocolo correcto todo está en verde?
Metes tú un fallo y miras si alguna falla. Un **mutante** es el protocolo con un cambio pequeño y
a propósito: quitar una línea, cambiar `>=` por `>`. Si alguna invariante falla, el mutante
**muere**; si todas siguen en verde, **sobrevive**, y has encontrado algo que tu suite no mira.

El proyecto trae `mutants.sh`, que aplica cada mutante con `sed`, ejecuta las invariantes y
devuelve el archivo a como estaba:

```bash
mutant src/Registry.sol 's/^\(\s*\)activeCount--;/\1\/\/ activeCount--;/' "retire no resta el activo"
```

```text
✅ retire no resta el activo: muerto
✅ no se devuelve lo pagado de más: muerto
✅ el alta con puntos no quema: muerto
✅ una alta de más por cuenta: muerto
```

Elige mutantes que rompan una promesa del protocolo, uno por invariante como mínimo. Un mutante
que sobrevive no siempre es un fallo de la suite: puede que el cambio no rompa nada (un mutante
**equivalente**). Míralo antes de añadir una invariante.

## ⚠️ Riesgos

- **Variables fantasma que se actualizan aunque la acción falle.** La invariante compara con algo
  que no pasó.
- **Acotar de más.** `bound(assets, 1, 100)` no revierte nunca, y tampoco prueba cantidades
  grandes. Los límites del `bound` son los del uso real, no los que hacen que todo pase.
- **Un handler que solo hace lo fácil.** Lo que nunca intenta, nunca lo prueba.
- **Confiar en una suite sin mutantes.** Hasta que no ha fallado con un fallo conocido, no sabes
  si fallaría con uno desconocido.

## 📝 Resumen

- Sin handler, el fuzzer llama desde cuentas sin saldo ni permisos y casi todo revierte.
- Un handler tiene cuentas fijas, entradas acotadas, precondiciones y variables fantasma, que se
  actualizan solo cuando la acción sale bien.
- Lo que el protocolo debe rechazar se intenta dentro de un `try` y se comprueba con `assert`.
- `fail_on_revert` convierte cualquier revert del handler en un fallo.
- Los mutantes comprueban que la suite atrapa fallos: cada uno tiene que morir.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 02 — Invariantes en Foundry](02-invariantes-en-foundry.md) | **Teoría 03 — Handlers** | [Teoría 04 — Medusa →](04-medusa.md) |
