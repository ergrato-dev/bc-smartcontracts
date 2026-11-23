# Proyecto — Ataques clásicos a tu protocolo

> Empiezas la auditoría de tu protocolo. Escribes cuatro atacantes contra tu registro, uno por
> cada clase de vulnerabilidad de la semana, y dejas sus tests como prueba de que no entran.
> Uno de los ataques sí encuentra algo: un hook puede triplicar el gas de cada alta. Lo
> corriges, lo llevas al registro desplegado con una actualización, y abres el informe de
> auditoría que irás completando hasta la semana 26.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana en verde; tu proyecto de la semana 20 en
`main`.

## Capa que se añade y por qué ahora

Hasta ahora, cada semana añadía funciones. Desde esta, la fase 5 las ataca. Tu protocolo ya
tiene todo lo que se ataca en esta semana: envía ETH (`withdrawFees`), llama a un contrato
externo en mitad de un alta (el hook), tiene roles e inicializadores, y vive detrás de un proxy.

Un ataque que no funciona también es un resultado: si lo dejas como test, el día que alguien
cambie el orden de `withdrawFees` o quite un `onlyRole`, el test falla. Y un ataque que funciona
es un **hallazgo**: se describe, se corrige y se prueba que la corrección lo cierra.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-21
   ```

2. Copia el starter en `week-21/` y pon encima tus contratos de la semana 20, sin tocar lo que
   trae el starter nuevo (`test/` y `PatchV3.s.sol`):

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-21-vulnerabilidades_clasicas/3-proyecto/starter week-21
   cp -r week-20/contracts/src week-20/contracts/script week-21/contracts/
   ls -l week-21/contracts/lib
   ```

   **Verifica**: `lib -> /opt/lib`. Tus `src/` y `script/` son los de la semana 20; `cp` no
   borra, así que `PatchV3.s.sol` sigue ahí. Si tenías tests propios en `week-20/contracts/test`, cópialos también.

3. Entra al contenedor y mira el rojo:

   ```bash
   cd week-21
   docker run --rm -it -p 8545:8545 -v "$PWD":/workspace bc-smartcontracts-dev
   bash test.sh
   ```

**Verifica**: los 8 tests de `RegistryV3Test` pasan y `ClassicAttacksTest` da
`2 passed; 5 failed`. Cuatro fallan porque sus atacantes tienen `TODO`; el quinto,
`test_ReturnBombHookCannotInflateGas`, falla con `HookFailed != expected HookFailed` porque tu
registro todavía tiene el fallo.

## Qué hay en el starter

| Ruta | Qué es |
| ---- | ------ |
| `contracts/src/`, `contracts/script/` | Los de la solución de la semana 20: tu referencia. Tú usas los tuyos |
| `contracts/src/Registry.sol` | Con un `// TODO (semana 21)` en `_notifyHook`: el requisito 5 |
| `contracts/script/PatchV3.s.sol` | Despliega una implementación nueva de V3 y actualiza el proxy sin inicializar nada. Hecho |
| `contracts/test/attackers/` | **Tu trabajo**: cuatro atacantes con `// TODO:` y su pista. `ReturnBombHook.sol` está hecho |
| `contracts/test/ClassicAttacks.t.sol` | 7 tests: despliegan con tus scripts, actualizan a V3 y atacan. **No los modifiques** |
| `contracts/test/RegistryV3.t.sol` | Los 8 tests de la semana 20 |
| `test.sh` | `forge test`, y después `forge build --deny warnings` |

## Requisitos

| # | Dónde | Qué |
| - | ----- | --- |
| 1 | `attackers/ReentrantTreasury.sol` | En `receive`, suma lo recibido y vuelve a llamar a `withdrawFees` dentro de un `try`; guarda el error |
| 2 | `attackers/StateSpyHook.sol` | En `onItemRegistered`, lee `count`, `activeCount`, `getItem(id).registrant` y el dueño del certificado |
| 3 | `attackers/Phisher.sol` | En `claimPrize`, intenta `grantRole(DEFAULT_ADMIN_ROLE, THIEF)` dentro de un `try`; guarda el error |
| 4 | `attackers/GasBurnerHook.sol` | En `onItemRegistered`, un bucle infinito que escriba en storage |
| 5 | Tu `Registry._notifyHook` | `HookFailed` lleva solo el selector del motivo, o `""` si tiene menos de 4 bytes |
| 6 | `week-21/audit/README.md` | Lo creas tú con la plantilla de abajo: las cinco clases revisadas en tu protocolo y el hallazgo H-01 |

Los tests que lo comprueban:

| Test | Clase | Qué mira |
| ---- | ----- | -------- |
| `test_ReentrantTreasuryCollectsOnce` | Reentrancy | Un tesorero que vuelve a entrar cobra las tasas una vez; la segunda entrada da `NothingToWithdraw` |
| `test_HookSeesFinalState` | Reentrancy de solo lectura | Durante el aviso, el hook ve el alta escrita: `count`, `activeCount`, `registrant` y certificado |
| `test_PhisherCannotUseAdminOrigin` | `tx.origin` | El administrador llama al cebo y el cebo recibe `AccessControlUnauthorizedAccount(cebo, rol)` |
| `test_GasBurningHookCannotBlockRegister` | DoS | Con un hook que gasta todo, el alta se hace y emite `HookFailed(1, "")` |
| `test_ReturnBombHookCannotInflateGas` | DoS | Con un hook que revierte con 64 000 bytes, el alta gasta menos de 500 000 y el log lleva 4 bytes |
| `test_PatchKeepsState` | Actualización | `PatchV3` cambia la implementación y no toca versión, altas, tasa ni `maxPerAccount` |
| `test_RevertWhen_StrangerCallsPrivileged` | Control de acceso | Un extraño no puede pausar, cobrar, cambiar el hook o el feed, dar roles, actualizar, inicializar, emitir puntos ni certificados |

`test_RevertWhen_StrangerCallsPrivileged` y `test_PatchKeepsState` ya pasan con tu código de la
semana 20: el control de acceso lo hiciste bien en la semana 13. Si tu protocolo tiene más
funciones privilegiadas que el starter, añádelas a ese test.

### El hallazgo: return bomb

Tu `_notifyHook` atrapa el error del hook con `catch (bytes memory reason)` y lo emite entero en
`HookFailed`. El hook decide qué devuelve: `ReturnBombHook` revierte con un custom error que
lleva 64 000 bytes. Con su tope de 100 000 de gas le sobra para construirlo.

Quien paga es quien registra: copiar esos bytes a la memoria del registro cuesta, y escribirlos
en un log, 8 de gas por byte. Lo verás abajo en anvil: el alta pasa de unos 305 000 de gas a
921 568. No roba nada y el alta sigue funcionando, pero cada usuario paga el triple, y tu página
de la semana 18, que estima el gas antes de enviar, le enseña ese precio.

El hook lo elige el administrador, así que hace falta que el administrador elija mal o que el
hook tenga a su vez un fallo. Por eso es de severidad **baja**. Pero es real, la corrección es
una línea y deja el contrato sin depender de que el hook se porte bien:

```solidity
catch (bytes memory reason) {
    // Solo el selector: `reason` lo elige el hook, y cada byte del log lo paga quien
    //   registra (semana 21, return bomb). Quedarse sin gas no deja motivo.
    emit HookFailed(id, reason.length < 4 ? bytes("") : abi.encodePacked(bytes4(reason)));
}
```

`bytes4(reason)` se queda con los cuatro primeros bytes: el selector, que dice qué error fue.
`catch (bytes memory reason)` sigue copiando el motivo entero a memoria, pero eso lo limita el
gas del propio hook; lo caro era el log. Tu indexador de la semana 19 sigue leyendo el mismo
evento.

## Cómo verificar

### Los tests

```bash
bash test.sh
```

**Verifica**: `8 passed` en `RegistryV3Test` y `7 passed` en `ClassicAttacksTest`, y ningún
warning en la compilación final. Mientras queden `TODO` en los atacantes, la compilación avisa
de `Unused function parameter` y de `Function state mutability can be restricted to pure`:
desaparecen al resolverlos.

### En anvil: el hallazgo y su corrección

La gracia es verlo en un registro ya desplegado, como el tuyo en Sepolia. Para eso, despliega
**antes** de corregir el requisito 5: si ya lo corregiste, guarda tu `Registry.sol` aparte y
vuelve a la versión de la semana 20 un momento (`git stash` o una copia).

En el contenedor del paso 3 de *Preparar la rama*, despliega hasta V3 como en la semana 20:

```bash
cd contracts
anvil --silent &
K0=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
K1=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
export ETHERSCAN_API_KEY=""
forge script script/DeployProtocol.s.sol --rpc-url anvil --broadcast --slow --private-key $K0 >/dev/null
export REGISTRY=$(jq -r '.transactions[] | select(.transactionType == "CREATE" and .contractName == "ERC1967Proxy") | .contractAddress' \
  broadcast/DeployProtocol.s.sol/31337/run-latest.json)
forge script script/UpgradeToV2.s.sol --rpc-url anvil --broadcast --slow --private-key $K0 >/dev/null
export PRICE_FEED=$(forge create lib/chainlink-contracts/src/v0.8/shared/mocks/MockV3Aggregator.sol:MockV3Aggregator \
  --rpc-url anvil --broadcast --private-key $K0 --constructor-args 8 250000000000 | grep "Deployed to" | cut -d' ' -f3)
forge script script/UpgradeToV3.s.sol --rpc-url anvil --broadcast --slow --private-key $K0 >/dev/null
```

Pon de hook el `ReturnBombHook` y da un alta con la cuenta 1 de anvil:

```bash
BOMB=$(forge create test/attackers/ReturnBombHook.sol:ReturnBombHook --rpc-url anvil --broadcast --private-key $K0 \
  | grep "Deployed to" | cut -d' ' -f3)
cast send $REGISTRY "setHook(address)" $BOMB --private-key $K0 --rpc-url anvil >/dev/null
FEE=$(cast call $REGISTRY "registrationFee()(uint256)" --rpc-url anvil | cut -d' ' -f1)
cast send $REGISTRY "register(string)" uno --value $FEE --private-key $K1 --rpc-url anvil | grep gasUsed
```

```text
gasUsed              921568
```

Ahora corrige `_notifyHook` (requisito 5) y lleva la corrección al proxy con `PatchV3`:

```bash
forge script script/PatchV3.s.sol --rpc-url anvil --broadcast --slow --private-key $K0 | grep -A1 "== Return"
cast send $REGISTRY "register(string)" dos --value $FEE --private-key $K1 --rpc-url anvil | grep gasUsed
cast logs --rpc-url anvil --address $REGISTRY "HookFailed(uint256 indexed,bytes)" --json \
  | jq -r '.[-1].data' | xargs cast decode-abi "f()(bytes)"
```

```text
== Return ==
0: address 0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0
gasUsed              305224
0x1a76361b
```

La dirección es la de la implementación nueva con los contratos del starter; con los tuyos
puede ser otra. El alta vuelve a su precio normal, y el log del último `HookFailed` lleva solo
`0x1a76361b`, que es `cast sig "Junk(bytes)"`: sabes qué error dio el hook sin pagar sus 64 000
bytes. La dirección del registro, sus altas y su tasa no han cambiado.

### En Sepolia

Si quieres llevar la corrección a tu registro de Sepolia:

```bash
export REGISTRY=<tu proxy en Sepolia>
forge script script/PatchV3.s.sol --rpc-url sepolia --account <tu keystore> --broadcast --verify
```

Si tu administrador es el timelock de la semana 13, la actualización pasa por su propuesta y su
plazo, como las anteriores. Apunta en el informe la dirección de la implementación nueva.

## El informe de auditoría

Un **informe de auditoría** dice qué se revisó, con qué, qué se encontró y en qué estado queda
cada hallazgo. Lo empiezas hoy en `week-21/audit/README.md` y lo completas cada semana hasta la
26: Slither, invariantes, verificación formal y la revisión final se añaden encima.

Esta semana rellenas dos partes:

1. **Revisión por clases**: para cada clase de la semana, dónde aparece en **tu** protocolo,
   qué lo defiende y qué test lo prueba. Si una clase no aplica, di por qué (por ejemplo: "no
   hay `unchecked` ni conversiones a tipos más pequeños; `RegistryV3` convierte a `uint256` un
   `int256` que ya comprobó positivo").
2. **H-01**: el return bomb, con su severidad, descripción, impacto, prueba, corrección y estado.

La plantilla, para copiar y completar:

```markdown
# Auditoría de <tu protocolo>

## Alcance

| Contrato | Versión | Commit |
| -------- | ------- | ------ |
| Registry, RegistryV2, RegistryV3 | V3 | <hash del commit revisado> |
| LoyaltyToken, Certificate | — | <el mismo> |

En quién confía el protocolo: <quién tiene cada rol, quién elige el hook y el feed>.

## Revisión por clases (semana 21)

| Clase | Dónde aparece | Defensa | Test |
| ----- | ------------- | ------- | ---- |
| Reentrancy | `withdrawFees` envía ETH; `_notifyHook` llama al hook | ... | `test_ReentrantTreasuryCollectsOnce`, `test_HookSeesFinalState` |
| Control de acceso | ... | ... | `test_RevertWhen_StrangerCallsPrivileged` |
| `tx.origin` | ... | ... | `test_PhisherCannotUseAdminOrigin` |
| DoS | ... | ... | `test_GasBurningHookCannotBlockRegister`, `test_ReturnBombHookCannotInflateGas` |
| Aritmética | ... | ... | ... |

## Hallazgos

| Id | Título | Severidad | Estado |
| -- | ------ | --------- | ------ |
| H-01 | Un hook puede encarecer cada alta con un motivo de revert enorme | Baja | Corregido |

### H-01 — <título>

- **Descripción**: qué hace el código y por qué falla.
- **Impacto**: quién pierde qué, y qué hace falta para explotarlo.
- **Prueba**: el test que lo reproduce y su resultado antes de corregir.
- **Corrección**: el cambio, y el test que lo comprueba.
- **Estado**: corregido en <commit>; implementación nueva en Sepolia: <dirección o "no desplegada">.
```

## Ejemplos de adaptación

| Dominio | Dónde mira el espía | Qué privilegio intenta el cebo |
| ------- | ------------------- | ------------------------------ |
| Biblioteca | El carné emitido y el número de socios activos | Darse el rol de bibliotecario para dar de baja socios |
| Tienda en línea | El vendedor registrado y su certificado | Darse `TREASURER_ROLE` para cobrar las tasas de alta |
| Cine | La butaca reservada y el aforo ocupado | Darse el rol de taquilla para pausar las reservas |

Los nombres de tus atacantes pueden seguir siendo los del starter; los tests de tu dominio usan
tus funciones (`registerMember`, `reserveSeat`...).

## Criterios de calidad (no automatizables)

- Cada atacante dice en su comentario de cabecera qué intenta y qué demuestra que falle.
- Cada test de ataque comprueba el **efecto** del ataque (saldos, roles, estado), no solo que
  algo revierta.
- Ninguna función privilegiada de tu protocolo queda fuera de
  `test_RevertWhen_StrangerCallsPrivileged`.
- El informe dice en qué confías: quién tiene cada rol, quién elige el hook y el feed.
- H-01 explica por qué la severidad es baja y no media o alta.

## Entrega

1. `bash test.sh` acaba con `8 passed` y `7 passed`, sin warnings.
2. `week-21/audit/README.md` con la revisión por clases y H-01. Si llevaste el parche a Sepolia, la
   dirección de la implementación nueva.
3. Commit y pull request:

   ```bash
   git add week-21
   git commit -m "test(week-21): add classic attack tests and fix hook return bomb"
   git push -u origin week-21
   ```

   Abre el pull request `week-21` → `main` y fusiónalo cuando esté en verde.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — DoS y aritmética](../2-practicas/ejercicio-03-dos-y-aritmetica/README.md) | **Proyecto — Ataques clásicos a tu protocolo** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
