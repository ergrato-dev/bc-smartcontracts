# Proyecto — Un vault de puntos

> Tus usuarios ganan puntos de fidelidad con cada alta, pero los puntos parados no les dan nada.
> Esta semana añades a tu protocolo un vault ERC-4626 donde guardarlos: cada alta del registro le
> emite un bonus, y quien tiene shares cobra su parte. Lo conectas sin cambiar el constructor del
> token, lo defiendes del ataque de inflación, mides lo que encarece cada alta y lo añades a tu
> informe de auditoría con sus amenazas.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana en verde; tu proyecto de la semana 29 en
`main`.

## Capa que se añade y por qué ahora

Tu `LoyaltyToken` de la semana 14 emite 10 puntos al registrante de cada alta. Los puntos se
transfieren y se gastan en el registro, pero quien los guarda no gana nada. La capa DeFi de tu
protocolo es un **vault de puntos**: un ERC-4626 sobre el token (teoría 03). Cada alta emite,
además, un **bonus** de 1 punto al vault. Como `totalAssets` es el saldo del vault, cada bonus sube
lo que vale cada share: los usuarios que guardan sus puntos cobran una parte de la actividad del
protocolo, en proporción a lo que guardan.

Ahora es cuando tienes todo lo necesario: el ERC-4626 de OpenZeppelin y sus shares virtuales
(teoría 03), el ataque de inflación de la semana 22, el modelo de amenazas de la semana 26, los
mutantes de la semana 24 y el gas guardado de la semana 29.

Dos problemas de diseño:

- **El token no conoce al vault.** El vault necesita la dirección del token para desplegarse
  (`ERC4626(points)`), así que el token no puede recibir la del vault en su constructor. El token
  gana una función `setStakingVault` que solo puede llamar el administrador del registro, y una
  sola vez: si se pudiera cambiar, quien controla al administrador desviaría el bonus a otra
  dirección.
- **El bonus llega antes que nadie.** Las altas anteriores al primer depósito mandan su bonus a un
  vault sin shares. Sin shares virtuales, el primero en depositar se lo llevaría entero. Con un
  offset de 6, ese bonus es de las shares virtuales: nadie lo gana, y nadie lo roba.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-30
   ```

2. Copia el starter en `week-30/` y pon encima tus contratos, tus pruebas, tu gas guardado y tu
   informe de la semana 29:

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-30-defi/3-proyecto/starter week-30
   cp -r week-29/contracts/src week-29/contracts/script week-29/contracts/snapshots week-30/contracts/
   cp -r week-29/contracts/test/invariant week-29/contracts/test/formal week-29/contracts/test/audit week-29/contracts/test/evm week-29/contracts/test/asm week-29/contracts/test/gas week-30/contracts/test/
   cp week-29/detectors/unpaused_register.py week-30/detectors/
   cp -r week-29/audit week-30/
   ls -l week-30/contracts/lib week-30/contracts/src/PointsVault.sol
   ```

   **Verifica**: `lib -> /opt/lib`, y `PointsVault.sol` existe: es el del starter, porque tu semana
   29 no tenía. Tu `LoyaltyToken.sol` y tu `DeployProtocol.s.sol` son los tuyos, sin el vault.

3. Entra al contenedor y mira el rojo:

   ```bash
   cd week-30
   docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
   cd contracts
   forge test
   ```

**Verifica**: no compila. Los tests de `test/defi/PointsVault.t.sol` usan lo que todavía no existe:

```text
Error (9582): Member "vault" not found or not visible after argument-dependent lookup in struct DeployProtocol.Deployment memory.
  --> test/defi/PointsVault.t.sol:34:17:
```

## Qué hay en el starter

| Ruta | Qué es |
| ---- | ------ |
| `contracts/src/`, `contracts/script/`, `contracts/test/` (salvo `defi/`) | Los de la solución de la semana 29: tu referencia. Tú usas los tuyos |
| `contracts/src/LoyaltyToken.sol` | El token de referencia con lo nuevo declarado y sus `// TODO (semana 30)` |
| `contracts/src/PointsVault.sol` | El vault, con su `// TODO (semana 30)` |
| `contracts/script/DeployProtocol.s.sol` | El despliegue con el campo `vault` y su `// TODO (semana 30)` |
| `contracts/test/defi/PointsVault.t.sol` | Los ocho tests del vault. **No los modifiques** |
| `mutants.sh` | Los veinte mutantes de la semana 29 y cuatro nuevos, del vault. **No lo modifiques** |
| `test.sh`, `check-report.sh` | Los de la semana 29 |
| `detectors/` | El detector de la semana 23; pon encima el tuyo |

## El token emite el bonus

**Abre** tu `contracts/src/LoyaltyToken.sol` y, al lado, el del starter. Copia lo que el del
starter declara de nuevo: la constante `STAKING_BONUS` (1 punto), la variable `stakingVault`, el
evento `StakingVaultSet` y los errores `NotRegistryAdmin`, `InvalidVault` y `VaultAlreadySet`. Con
los nombres de tu dominio, si tu token los usa, pero con estas firmas: los tests las llaman.

Después, resuelve los dos `TODO`:

```solidity
function setStakingVault(address vault) external {
    if (!IAccessControl(REGISTRY).hasRole(0x00, msg.sender)) revert NotRegistryAdmin(msg.sender);
    if (vault == address(0)) revert InvalidVault(vault);
    if (stakingVault != address(0)) revert VaultAlreadySet(stakingVault);
    stakingVault = vault;
    emit StakingVaultSet(vault);
}
```

`0x00` es `DEFAULT_ADMIN_ROLE` (semana 13): el token pregunta al registro, con la interfaz
`IAccessControl` de OpenZeppelin, si quien llama es su administrador. Y en el hook, después de los
puntos del registrante:

```solidity
address vault = stakingVault;
if (vault != address(0)) _mint(vault, STAKING_BONUS);
```

Si el bonus no cabe en el tope de `MAX_SUPPLY`, la emisión revierte entera, como ya pasaba con los
puntos del registrante: el registro lo anota en `HookFailed` y el alta sigue (semana 10).

## El vault

**Abre** `contracts/src/PointsVault.sol`. El vault entero es el `ERC4626` de OpenZeppelin con el
token como activo. Resuelve el `TODO`:

```solidity
function _decimalsOffset() internal pure override returns (uint8) {
    return 6;
}
```

Las shares tienen 24 decimales. Con el offset a 0, el ataque de `test_DonationAttackDoesNotPay`
deja a `alice` sin ninguna share, y el bonus de antes del primer depósito se lo lleva ella en
`test_StakersEarnTheBonus`.

## El despliegue

**Abre** tu `contracts/script/DeployProtocol.s.sol`. Añade `PointsVault vault;` al final del
struct `Deployment` y, después de `setHook`:

```solidity
d.vault = new PointsVault(d.loyalty);
d.loyalty.setStakingVault(address(d.vault));
```

Quien firma el script es el administrador del registro desde `initialize`. El despliegue pasa de
cinco transacciones a siete: actualiza el comentario de arriba del script.

**Verifica**:

```bash
forge test --mc PointsVaultTest
```

`8 tests passed`. Si alguno falla, el mensaje dice qué falta. Por ejemplo, sin el offset:

```text
[FAIL: assertion failed: 18 != 24] test_DeployConnectsTheVault() (gas: 23667)
[FAIL: alice pierde su deposito: 0 < 9990000000000000000] test_DonationAttackDoesNotPay() (gas: 1334016)
```

## El gas del alta

El bonus no es gratis: cada alta lee `stakingVault`, un `SLOAD` frío, y emite una segunda vez.
`test.sh` comprueba primero tu gas guardado de la semana 29, y ahora no coincide:

```bash
FORGE_SNAPSHOT_CHECK=true forge test --mc RegisterGasTest
```

```text
[RegisterGasTest] Failed to match snapshots:
- [register] 217324 → 227148
- [registerBatch3] 467613 → 483485
Error: Snapshots differ from previous run
```

Es el cambio que esperabas, así que lo aceptas: `forge test` reescribe
`snapshots/RegisterGasTest.json`, y lo subes con el resto. Tus números serán otros si tu protocolo
cambió algo en las semanas 21 a 29; lo que cuenta es que el archivo y el informe digan los mismos.

```bash
forge test
```

**Verifica**: `53 tests passed, 0 failed`: los 45 de la semana 29 y los ocho del vault.

## El informe

**Abre** `week-30/audit/README.md` y añade el vault:

- En **Alcance**, la fila de `PointsVault` y las líneas nuevas de `LoyaltyToken`.
- En **Actores**, el depositante del vault, sin confianza. En **Activos**, los puntos depositados
  y el bonus.
- En **Amenazas**, tres filas nuevas, con su defensa y su prueba:

  | Id | Amenaza | Defensa | Prueba |
  | -- | ------- | ------- | ------ |
  | T-13 | Un regalo o el bonus del vault vacío se lo lleva quien deposita primero | Offset de 6 | `test_DonationAttackDoesNotPay`, `test_FirstDepositorDoesNotTakeTheEarlyBonus` |
  | T-14 | El bonus se desvía a otro vault | `setStakingVault` solo del admin, una vez | `test_RevertWhen_StakingVaultNotByAdminOrTwice` |
  | T-15 | Alguien deposita justo antes de unas altas y retira justo después | Ninguna: riesgo aceptado | `test_JustInTimeDepositSharesTheBonus` |

- Una sección `## Vault de puntos (semana 30)`, antes de `## Hallazgos`, con: cómo funciona el
  bonus, cómo se conecta el vault, el gas del alta antes y después con los números de tu
  `snapshots/RegisterGasTest.json` (`check-report.sh` los busca), qué pasa con el bonus de antes
  del primer depósito, qué prueba cada test, qué mutante mata cada uno, y lo que no hiciste.

T-15 es un riesgo aceptado, y el informe tiene que decir por qué: `test_JustInTimeDepositSharesTheBonus`
mide que quien entra con 50 puntos alrededor de 3 altas sale con menos de 53. Las defensas
conocidas (repartir el bonus a lo largo del tiempo, o un plazo mínimo para retirar) añaden estado
y cambian lo que dicen `totalAssets` o `maxWithdraw`; con 1 punto por alta, no compensan. Si tu
bonus es mayor, la decisión puede ser otra: escríbela con tus números.

## Cómo verificar

```bash
cd /workspace
bash test.sh
```

Tarda unos minutos: Medusa y los mutantes son lo más lento. Al final:

```text
✅ el bonus va al registrante: muerto
✅ cualquiera fija el vault: muerto
✅ el vault se puede cambiar: muerto
✅ sin shares virtuales: muerto
```

y el código de salida es 0. Por el camino, `check-report.sh` dice `✅ informe: secciones, commit,
hallazgos, gas y N pruebas citadas`, con tu N; `forge test`, `53 tests passed`; Halmos, las cinco
specs; Slither, 0 resultados; Medusa, `13 test(s) passed`; y los veinticuatro mutantes, muertos.

## Ejemplos de adaptación

| Dominio | El vault | El bonus |
| ------- | -------- | -------- |
| Biblioteca | Los socios guardan sus puntos de lectura en un fondo común | Cada préstamo de un libro suma un punto al fondo |
| Tienda en línea | Los clientes bloquean puntos en un "monedero premium" | Cada pedido suma un punto al monedero de todos |
| Cine | Los espectadores guardan sus puntos en el club | Cada entrada vendida suma un punto al club |

En los tres, el vault es el mismo contrato: solo cambian los nombres y, si quieres, el bonus.

## Criterios de calidad (no automatizables)

- El token no puede emitir el bonus a nadie más que al vault fijado, y nadie puede cambiarlo.
- Cada amenaza nueva tiene defensa y prueba, o dice por qué se acepta.
- El informe da el gas del alta con tus números, y dice si el coste compensa.
- Los nombres del vault y sus shares son de tu dominio, no `Staked Points` si tu token no son
  puntos.
- Ningún test del starter ni ningún mutante modificado para que pase.

## Entrega

1. Comprueba que `week-30/` no tiene `out/`, `cache/` ni `crytic-export/` y que sí tiene
   `contracts/snapshots/RegisterGasTest.json`.
2. Haz commit y sube la rama:

   ```bash
   git add week-30
   git commit -m "feat(week-30): add points vault with registration bonus"
   git push -u origin week-30
   ```

3. Abre un pull request `week-30` → `main` y pega en la descripción la salida final de
   `bash test.sh`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Un préstamo con garantía](../2-practicas/ejercicio-03-prestamo-con-garantia/README.md) | **Proyecto — Un vault de puntos** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
