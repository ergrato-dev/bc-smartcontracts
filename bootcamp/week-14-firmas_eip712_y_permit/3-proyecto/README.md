# Proyecto — Órdenes firmadas

> Decimocuarta capa del protocolo de tu dominio: un miembro firma su alta fuera de la cadena
> y otra cuenta la envía y paga la tasa, y gastar puntos ya no exige un `approve`: basta un
> permit firmado.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana terminados y tu proyecto de la
semana 13 en `main`.

## Capa que se añade y por qué ahora

Hasta la semana 13, quien registra es siempre `msg.sender`: tiene que tener ETH, pagar la tasa
y el gas, y firmar la transacción. Y gastar puntos en `registerWithPoints` cuesta dos
transacciones: `approve` en el token y después el alta. Esta semana:

- **`registerBySig`**: el miembro firma una orden EIP-712 `Registration` (quién, qué etiqueta,
  nonce y plazo). Un **patrocinador** (la oficina de tu red, un club, una tienda) la envía y
  paga la tasa y el gas. El recurso, el certificado y los puntos son del miembro.
- **`registerWithPermit`**: el token de fidelidad hereda de `ERC20Permit`, y el registro usa
  el permit para quemar los puntos en la misma transacción del alta.
- **`msg.sender` deja de ser quien registra** dentro de `_register` y `_notifyHook`: los dos
  reciben `registrant` como parámetro.
- **El dominio del registro es su `PROTOCOL_NAME`**, versión `"1"`. El del token, su `name`.
- **La pausa bloquea también las dos altas nuevas.**

En la semana 15 el registro pasa a ser actualizable: un proxy delante y la lógica detrás.

**El dominio te lo asigna el instructor.** Usa los nombres, la tasa y la colección de tus
semanas anteriores.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-14
   ```

2. Copia el starter entero, con su `.gitignore`, en una carpeta `week-14/` (ajusta la ruta a
   donde clonaste el bootcamp). Después trae tus pruebas de fuzzing y de fork y el
   `.gas-snapshot` de la semana 13:

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-14-firmas_eip712_y_permit/3-proyecto/starter week-14
   cp week-13/test/RegistryFuzz.t.sol week-13/test/RegistryFork.t.sol week-14/test/
   cp week-13/.gas-snapshot week-14/
   ```

3. Pon los nombres de tu dominio: en `week-14/src/Registry.sol`, los del registro y la tasa;
   en `week-14/src/LoyaltyToken.sol` y `week-14/src/Certificate.sol`, el nombre y el símbolo
   del token y de la colección. El resto de `src/` es tu semana 13: si cambiaste algo allí,
   cópialo también.

4. Entra al contenedor y mira el rojo:

   ```bash
   cd week-14
   docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
   forge test
   ```

**Verifica**: `103 tests passed, 19 failed, 1 skipped (123 total tests)`. Fallan:

- 12 de los 14 de `RegistrySig.t.sol`, con `TODO: registerBySig`. Pasan
  `test_DomainNameIsTheProtocol` (el dominio ya está en la cabecera) y
  `test_RevertWhen_RegisterBySigWhilePaused` (`whenNotPaused` también).
- Los 7 de `RegistryPermit.t.sol`, con `EvmError: Revert`: el token aún no tiene `permit`,
  `nonces` ni `eip712Domain`.

Si ves `100 passed, 22 failed`, te faltan los nombres del paso 3: fallan también
`test_NamesAreSet`, `test_TokenIsDeployedByTheRegistry` y
`test_CertificateIsDeployedByTheRegistry`.

## Qué hay en el starter

| Archivo | Qué es |
| ------- | ------ |
| `foundry.toml`, `.gitignore` | Con el remapping de OpenZeppelin. No los cambies |
| `src/Registry.sol` | Tu registro de la semana 13, que ya hereda de `EIP712` y `Nonces`, con `REGISTRATION_TYPEHASH`, `ExpiredSignature`, `InvalidSigner`, `_registerWithPoints`, las cabeceras de `registerBySig` y `registerWithPermit`, y sus `// TODO:` |
| `src/LoyaltyToken.sol`, `src/Certificate.sol` | Tu token y tu colección, sin los nombres. El token, con un `// TODO:` |
| `src/` (resto) | `IRegistry`, `LabelLib`, `IERC165` e `IRegistrationHook`, sin cambios |
| `test/` de la semana 13 | `Registry`, `RegistryHook`, `RegistryMulticall`, `RegistryLoyalty`, `RegistryCertificate`, `RegistryRoles` y `RegistryTimelock`, sin cambios. **No los modifiques** |
| `test/RegistrySig.t.sol` | 14 tests de las altas con orden firmada. **No lo modifiques** |
| `test/RegistryPermit.t.sol` | 7 tests del permit del token y del alta con permit. **No lo modifiques** |

`RegistryPermit.t.sol` ve el token como `IERC20Permit`: así compila antes de que añadas
`ERC20Permit`, y sus tests fallan al llamar a funciones que aún no existen.

## Requisitos

1. **El token acepta permits**: `LoyaltyToken` hereda de `ERC20Permit`, con el mismo nombre
   que pasas a `ERC20`.
2. **`_register` y `_notifyHook` reciben `registrant`** y lo usan en el `Item`, en `_idsOf`,
   en `ItemRegistered`, en el certificado y en el aviso al hook. Las altas de siempre pasan
   `msg.sender`.
3. **`registerBySig(registrant, label, deadline, signature)`**, `payable` y `whenNotPaused`,
   comprueba en este orden: plazo (`ExpiredSignature`), firmante del struct `Registration`
   con el nonce de `registrant` (`InvalidSigner(signer, registrant)`), capacidad y tasa. El
   nonce se gasta con `_useNonce` dentro del struct hash.
4. **`registerWithPermit(label, deadline, v, r, s)`**, `whenNotPaused`, llama al `permit` del
   token para `msg.sender` por `POINTS_PRICE` dentro de un `try ... {} catch {}`, y después a
   `_registerWithPoints(label)`.
5. **Tus propiedades de fuzzing siguen siendo ciertas**, `.gas-snapshot` actualizado y
   `forge snapshot --fuzz-seed 1 --check` en verde.
6. **Desplegado en anvil** desde la cuenta de tu `INDEX`: un alta firmada por otra cuenta y
   patrocinada por ti, y un alta con permit. El test de fork pasa contra ese despliegue.

## Por qué el orden de `registerBySig`

```solidity
if (block.timestamp > deadline) revert ExpiredSignature(deadline);
bytes32 structHash = keccak256(
    abi.encode(REGISTRATION_TYPEHASH, registrant, keccak256(bytes(label)), _useNonce(registrant), deadline)
);
address signer = ECDSA.recover(_hashTypedDataV4(structHash), signature);
if (signer != registrant) revert InvalidSigner(signer, registrant);
```

Primero el plazo, que es lo más barato. Después la firma, antes que la capacidad y la tasa:
una orden que no es del miembro se rechaza por eso, sea cual sea el estado del registro.
¿Y si el nonce se gasta y después la tasa es incorrecta? El `revert` deshace todo, también `_useNonce`: el test
`test_RevertWhen_WrongFeeKeepsTheNonce` lo comprueba y después usa la misma firma con éxito.

¿Puede alguien robar una orden del mempool y enviarla antes? Sí, pero pagando la tasa de su
bolsillo, y el recurso sigue siendo del miembro: no gana nada. Por eso aquí no hace falta un
`try`, y en `registerWithPermit` sí (teoría 04).

## Cómo verificar

```bash
forge test
```

**Verifica**: `122 tests passed, 0 failed, 1 skipped (123 total tests)`, sin warnings
(`forge test --deny warnings`). Fíjate en `test_SponsorRegistersForMember`: el sponsor pagó
la tasa, y el recurso, el certificado, los 10 puntos y el nonce son del miembro.

Al compilar con `forge build`, el linter avisa de algo nuevo:

```
warning[block-timestamp]: usage of `block.timestamp` in a comparison may be manipulated by validators
```

Un validador puede mover el timestamp de su bloque unos segundos. Para un plazo de horas da
igual, así que se silencia esa línea diciendo por qué:

```solidity
        // Un validador puede mover el timestamp unos segundos: para un plazo de horas da igual.
        // forge-lint: disable-next-line(block-timestamp)
        if (block.timestamp > deadline) revert ExpiredSignature(deadline);
```

### Lo que cuesta la capa nueva

```bash
forge snapshot --fuzz-seed 1 --diff
```

```
↑ RegistryTest::test_RegisterStoresItem() (gas: 299395 → 299451 | 56 0.019%)
↑ RegistryTest::test_AdminAndCapacityAreSetAtDeploy() (gas: 6920272 → 8501673 | 1581401 22.852%)
```

Un alta cuesta casi lo mismo: pasar `registrant` como parámetro en vez de leer `msg.sender`.
Lo que sube es desplegar: el registro lleva el código de `EIP712` y `Nonces`, y el token, el
de `ERC20Permit`, y todo ese bytecode se paga una vez al crear los contratos. Tus números
serán otros. Después regenera y comprueba:

```bash
forge snapshot --fuzz-seed 1
forge snapshot --fuzz-seed 1 --check
```

### En anvil: un alta patrocinada

Con `anvil --silent &` recién arrancado, la clave de tu `INDEX` (aquí `3`, capacidad `50` y
tasa `0.01 ether`, los de los ejemplos) y la cuenta `5` como miembro. Para ir al grano, aquí
tú sigues de administrador y pones el hook directamente; en tu protocolo de verdad, lo haría
el timelock de la semana 13.

```bash
M="test test test test test test test test test test test junk"
PK=$(cast wallet private-key "$M" 3); ME=$(cast wallet address "$PK")
PK5=$(cast wallet private-key "$M" 5); MEMBER=$(cast wallet address "$PK5")
DL=2000000000
forge create src/Registry.sol:Registry --private-key "$PK" --broadcast --constructor-args 50
REGISTRY=0x057ef64E23666F000b34aE31332854aCBd1c8544   # tu "Deployed to"
LOYALTY=$(cast call $REGISTRY "LOYALTY()(address)")
cast send $REGISTRY "setHook(address)" $LOYALTY --private-key "$PK" --json | jq -r .status
cast call $REGISTRY "eip712Domain()(bytes1,string,string,uint256,address,bytes32,uint256[])" | sed -n 2,5p
cast call $REGISTRY "nonces(address)(uint256)" $MEMBER
```

```
0x1
"Repair Network"
"1"
31337 [3.133e4]
0x057ef64E23666F000b34aE31332854aCBd1c8544
0
```

Con tu nombre de protocolo en `name` y tu dirección en `verifyingContract`, la orden del
miembro en `registration.json`:

```json
{
  "types": {
    "EIP712Domain": [
      {"name": "name", "type": "string"},
      {"name": "version", "type": "string"},
      {"name": "chainId", "type": "uint256"},
      {"name": "verifyingContract", "type": "address"}
    ],
    "Registration": [
      {"name": "registrant", "type": "address"},
      {"name": "label", "type": "string"},
      {"name": "nonce", "type": "uint256"},
      {"name": "deadline", "type": "uint256"}
    ]
  },
  "primaryType": "Registration",
  "domain": {"name": "Repair Network", "version": "1", "chainId": 31337, "verifyingContract": "0x057ef64E23666F000b34aE31332854aCBd1c8544"},
  "message": {"registrant": "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc", "label": "north", "nonce": 0, "deadline": 2000000000}
}
```

El miembro firma; tú envías y pagas:

```bash
SIG=$(cast wallet sign --private-key "$PK5" --data --from-file registration.json)
cast wallet verify --address $MEMBER --data --from-file registration.json $SIG
cast send $REGISTRY "registerBySig(address,string,uint256,bytes)" $MEMBER north $DL $SIG --value 0.01ether --private-key "$PK" --json | jq -c '[.status, .from, .logs[0].topics[2]]'
cast call $REGISTRY "getItem(uint256)((uint256,address,uint8,uint256,string))" 1
cast call $REGISTRY "nonces(address)(uint256)" $MEMBER
cast call $LOYALTY "balanceOf(address)(uint256)" $MEMBER
```

```
Validation succeeded. Address 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc signed this message.
["0x1","0x90f79bf6eb2c4f870365e785982e1f101e93b906","0x0000000000000000000000009965507d1a55bcc2695c58ba16fb37d819b0a4dc"]
(1, 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc, 1, 1795410298 [1.795e9], "north")
1
10000000000000000000 [1e19]
```

La transacción es tuya (`0x90f7…`), pero el `registrant` de `ItemRegistered` (su segundo
topic) y del recurso es el miembro, que además gana los 10 puntos. El timestamp será otro.
Ahora reenvía la misma orden, y después cámbiale la etiqueta:

```bash
cast send $REGISTRY "registerBySig(address,string,uint256,bytes)" $MEMBER north $DL $SIG --value 0.01ether --private-key "$PK"
cast send $REGISTRY "registerBySig(address,string,uint256,bytes)" $MEMBER south $DL $SIG --value 0.01ether --private-key "$PK"
```

```
Error: ... custom error 0x7ba5ffb5: ...: InvalidSigner(0x4657dacD55B56c6d6E17E1e2b55F00E1A90A08d2, 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc)
Error: ... custom error 0x7ba5ffb5: ...: InvalidSigner(0x4CD13fD5D15036c9539e96242cCfA7fc9D1CA63B, 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc)
```

El nonce ya es 1, y `south` no es lo que firmó: dos hashes distintos, dos direcciones de nadie.

### En anvil: un alta con permit

Tres altas pagando ETH te dan 30 puntos, lo justo para una con puntos. Lee el dominio del
token:

```bash
cast send $REGISTRY "registerBatch(string[])" "[south,east,west]" --value 0.03ether --private-key "$PK" --json | jq -r .status
cast call $LOYALTY "balanceOf(address)(uint256)" $ME
cast call $LOYALTY "eip712Domain()(bytes1,string,string,uint256,address,bytes32,uint256[])" | sed -n 2,5p
```

```
0x1
30000000000000000000 [3e19]
"Repair Points"
"1"
31337 [3.133e4]
0x3b3112c4376d037822DECFf3Fe6CD30E1E726517
```

Tu permit para el registro por `POINTS_PRICE`, en `permit.json`: el mismo `EIP712Domain` y
`Permit` del ejercicio 03, con este dominio y este mensaje (tu nombre de token, tu
`LOYALTY`, tu `ME` y tu `REGISTRY`):

```json
  "domain": {"name": "Repair Points", "version": "1", "chainId": 31337, "verifyingContract": "0x3b3112c4376d037822DECFf3Fe6CD30E1E726517"},
  "message": {"owner": "0x90F79bf6EB2c4f870365E785982E1f101E93b906", "spender": "0x057ef64E23666F000b34aE31332854aCBd1c8544", "value": "30000000000000000000", "nonce": 0, "deadline": 2000000000}
```

Firma, parte la firma y regístrate en una sola transacción, sin `approve`:

```bash
PSIG=$(cast wallet sign --private-key "$PK" --data --from-file permit.json)
R=0x${PSIG:2:64}; S=0x${PSIG:66:64}; V=$((16#${PSIG:130:2}))
cast call $LOYALTY "allowance(address,address)(uint256)" $ME $REGISTRY
cast send $REGISTRY "registerWithPermit(string,uint256,uint8,bytes32,bytes32)" north2 $DL $V $R $S --private-key "$PK" --json | jq -r .status
cast call $LOYALTY "balanceOf(address)(uint256)" $ME
cast call $LOYALTY "nonces(address)(uint256)" $ME
cast send $REGISTRY "registerWithPermit(string,uint256,uint8,bytes32,bytes32)" north3 $DL $V $R $S --private-key "$PK"
```

```
0
0x1
10000000000000000000 [1e19]
1
Error: ... custom error 0xfb8f41b2: 000000000000000000000000057ef64e23666f000b34ae31332854acbd1c85440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a055690d9db80000, ...
```

Allowance `0` antes, y el alta pasó igual: el permit la puso y `burnFrom` la gastó. Te quedan
los 10 puntos de esa alta. Con la misma firma otra vez, el permit falla en silencio y
`burnFrom` revierte con `ERC20InsufficientAllowance` (`0xfb8f41b2`): registro, `0` y
`0x1a055690d9db80000`, 30 puntos.

**Verifica**: el test de fork, sin cambios, contra este despliegue:

```bash
cast call $REGISTRY "count()(uint256)"
FORK_URL=http://127.0.0.1:8545 REGISTRY="$REGISTRY" forge test --match-path test/RegistryFork.t.sol
```

`5` y `[PASS] test_Fork_RegistersOnACopy()`.

## Ejemplos de adaptación

Tres dominios que el instructor **no** asigna:

| Dominio | Quién firma la orden | Quién patrocina | Para qué el permit |
| ------- | -------------------- | --------------- | ------------------ |
| Biblioteca | Un socio nuevo, desde el móvil | La biblioteca, que paga el alta | Canjear puntos de lectura por un préstamo especial |
| Tienda en línea | Un vendedor que abre su catálogo | La tienda, en la campaña de bienvenida | Pagar la comisión con puntos en el mismo paso |
| Cine | Un espectador que reserva butaca | El cine, en un estreno promocional | Usar puntos de fidelidad sin dos confirmaciones |

## Criterios de calidad (no automatizables)

- Sabes explicar por qué `_register` ya no puede usar `msg.sender`.
- Sabes explicar qué impide reutilizar una orden: en el mismo registro, en otro y en otra red.
- Sabes explicar por qué `registerWithPermit` lleva `try` y `registerBySig` no.
- Sabes explicar qué gana alguien que envía antes una orden ajena del mempool.
- Sabes explicar por qué el `name` del dominio del token es el nombre del token.
- Sin `TODO` restantes, y los nombres son de tu dominio.

## Entrega

```bash
git add week-14
git commit -m "feat(week-14): add signed registrations and points permit"
git push -u origin week-14
```

Abre un pull request `week-14` → `main` en tu repositorio. En la descripción pega la salida
de `forge test`, la línea de `--diff` del despliegue, el `getItem` del alta patrocinada y el
error de reenviar la orden.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Permit](../2-practicas/ejercicio-03-permit/README.md) | **Proyecto — Órdenes firmadas** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
