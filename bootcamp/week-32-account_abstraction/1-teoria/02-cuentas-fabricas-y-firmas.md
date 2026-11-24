# Teoría 02 — Cuentas, fábricas y firmas

## 🎯 Objetivos

- Calcular la dirección de una cuenta antes de desplegarla y desplegarla con su primera operación.
- Explicar por qué el dueño tiene que ir en el código de creación y no en una llamada posterior.
- Montar una cuenta con OpenZeppelin: `Account`, un firmante y `ERC7821` para lotes.
- Saber qué firmas puede aceptar una cuenta y qué cambia para firmar mensajes (ERC-1271).
- Conocer las reglas que los bundlers ponen a la validación (ERC-7562) y por qué existen.

## Qué problema resuelve

La cuenta del ejercicio 01 la despliega el test con `new`. En la vida real, ¿quién despliega la
cuenta de alguien que todavía no tiene ETH? Y si la cuenta es un contrato, ¿cómo recibe fondos
antes de existir? ERC-4337 responde con una **fábrica** y una **dirección contrafactual**: la
dirección se calcula antes, se le puede mandar ETH, y la primera UserOperation la despliega.

La segunda pregunta es qué firma acepta la cuenta. Una EOA solo sabe ECDSA. Una cuenta contrato
puede aceptar lo que quiera: una passkey del móvil, tres de cinco claves, una clave de sesión que
caduca. Eso es lo que la hace útil, y lo que más hay que revisar.

## Cómo funciona

### La dirección contrafactual

Con `CREATE2` (semana 10) la dirección depende de tres cosas: la fábrica, una sal (*salt*) y el
hash del código de creación, que incluye los argumentos del constructor:

```text
dirección = keccak256(0xff ++ fábrica ++ sal ++ keccak256(código de creación ++ argumentos))[12:]
```

La fábrica la calcula con `getAddress(owner, salt)`. El usuario manda ETH a esa dirección, que no
tiene código. La primera operación lleva `initCode = fábrica ++ calldata de createWallet(owner, salt)`.
El EntryPoint, al validar, ve que `sender` no tiene código, llama a la fábrica a través de un
contrato auxiliar, el **SenderCreator**, y comprueba que lo desplegado está justo en `sender`. Si
no, revierte con `AA14 initCode must return sender`.

**Dónde**: en `src/WalletFactory.sol` del ejercicio 01:

```solidity
function createWallet(address owner, uint256 salt) external returns (SimpleWallet wallet) {
    if (msg.sender != address(senderCreator)) revert NotSenderCreator(msg.sender);
    address predicted = getAddress(owner, salt);
    if (predicted.code.length > 0) return SimpleWallet(payable(predicted));
    wallet = new SimpleWallet{salt: bytes32(salt)}(entryPoint, owner);
}

function getAddress(address owner, uint256 salt) public view returns (address) {
    bytes32 initCodeHash =
        keccak256(abi.encodePacked(type(SimpleWallet).creationCode, abi.encode(entryPoint, owner)));
    return Create2.computeAddress(bytes32(salt), initCodeHash);
}
```

Si la cuenta ya existe, `createWallet` la devuelve sin revertir: así la llamada es idempotente.
La fábrica solo acepta al SenderCreator: la cuenta nace siempre de una UserOperation, como hace la
fábrica de ejemplo de la v0.8 de eth-infinitism.

**Ejecuta**: `forge test -vv --mt test_Counterfactual`. El test calcula la dirección, le manda
1 ETH, envía la primera operación con `initCode` y después una segunda sin él:

```text
[PASS] test_Counterfactual() (gas: 980801)
Logs:
  prevista 0x6D74429A816A3E7b607F7ea7f608150Ed9322196
  codigo antes 0
  codigo despues 2767
  pagado con despliegue 761870000000000
  pagado sin despliegue 98430000000000
```

La primera operación cuesta casi ocho veces la segunda: despliega 2767 bytes de código. Por eso la
fábrica necesita un `verificationGasLimit` mucho mayor; con 600 000 el despliegue se queda sin gas
y el EntryPoint responde `AA13 initCode failed or OOG`.

### El dueño, dentro del hash

El dueño va en los argumentos del constructor, y por tanto en el hash del código. Otra cuenta con
otro dueño tendría otra dirección. Compáralo con una fábrica que despliega sin dueño y luego llama
a `initialize(owner)`: el atacante ve la operación en el mempool, despliega antes en la misma
dirección (la sal es pública) y se hace dueño de una cuenta que ya tiene el ETH del usuario. La
regla es la de los proxies de la semana 15: lo que da poder se fija en la creación.

### Cuentas con OpenZeppelin

OpenZeppelin 5.7 trae las piezas para no escribir la cuenta a mano:

| Pieza | Qué pone |
| ----- | -------- |
| `Account` | `validateUserOp`, el prefund, `entryPoint()` y `getNonce()`; deja abstracta la firma |
| `SignerECDSA` | Un dueño con clave ECDSA, como `SimpleWallet` |
| `SignerP256`, `SignerWebAuthn` | Una passkey: la clave del móvil o del portátil (curva secp256r1) |
| `MultiSignerERC7913` | Varias claves y un umbral, como el multisig de la semana 13 |
| `SignerEIP7702` | La propia EOA es la cuenta (teoría 04) |
| `ERC7821` | `execute(mode, executionData)`: un lote de llamadas, todas o ninguna |

Una cuenta se arma heredando `Account`, un firmante y `ERC7821`, y diciendo quién puede ejecutar.
**Dónde**: en `src/ProtocolAccount.sol` de tu proyecto, la cuenta de esta semana:

```solidity
contract ProtocolAccount is Account, SignerEIP7702, ERC7821 {
    IEntryPoint private immutable _entryPoint;

    constructor(IEntryPoint entryPoint_) {
        _entryPoint = entryPoint_;
    }

    function entryPoint() public view override returns (IEntryPoint) {
        return _entryPoint;
    }

    function _erc7821AuthorizedExecutor(address caller, bytes32 mode, bytes calldata executionData)
        internal
        view
        override
        returns (bool)
    {
        return caller == address(entryPoint()) || super._erc7821AuthorizedExecutor(caller, mode, executionData);
    }
}
```

`Account` de OpenZeppelin 5.7 usa por defecto el EntryPoint v0.9; el protocolo usa el v0.8.0, el
de la imagen, y por eso sobrescribe `entryPoint()`. `ERC7821` por defecto solo deja ejecutar a la
propia cuenta; el `override` añade al EntryPoint, que solo llama después de validar la firma.

El lote de ERC-7821 se codifica así: el modo `0x01` en el primer byte (lote, y revierte si una
llamada falla) y los datos, un `abi.encode` de un array de `Execution(target, value, callData)`.

### Firmar mensajes: ERC-1271

Una UserOperation la valida el EntryPoint. Pero un `permit` (semana 14) o una orden firmada para un
mercado los valida otro contrato con `ecrecover`, y una cuenta contrato no tiene clave privada que
recupere su dirección. **ERC-1271** añade a la cuenta `isValidSignature(hash, firma)`, y los
contratos que quieren aceptar cuentas preguntan con `SignatureChecker` de OpenZeppelin en vez de
`ECDSA.recover`. `LoyaltyToken` usa `ERC20Permit`, que solo acepta ECDSA: una cuenta de la fábrica
del ejercicio 01 no podría firmar un permit de puntos. Con EIP-7702 (teoría 04) la cuenta es la
EOA, y la firma ECDSA de la EOA sí vale: es lo que usa tu proyecto.

### Tres formas de tener una cuenta

| | EOA | Cuenta de ERC-4337 | EOA con EIP-7702 |
| - | --- | ------------------ | ---------------- |
| Dirección | La de la clave | Nueva, de la fábrica | La de la clave |
| Quién la despliega | Nadie | La fábrica, en la primera operación | Nadie: la EOA firma una autorización |
| Firma | ECDSA, siempre | La que diga su código | La que diga su código (y la clave, siempre) |
| `permit` de un ERC-20 | Sí | Solo si el token acepta ERC-1271 | Sí: firma la EOA |
| Si se pierde la clave | Se pierde todo | Depende de su código (recuperación social, otra clave) | Se pierde todo |

### Las reglas de la validación (ERC-7562)

El bundler simula cada operación antes de enviarla, porque si una validación falla en cadena paga
él. Pero entre la simulación y el bloque pasa tiempo. Si la validación pudiera leer cualquier
cosa, una sola transacción podría invalidar miles de operaciones del mempool y hacer que los
bundlers gasten gas en vano. **ERC-7562** limita lo que la validación puede tocar:

- Opcodes prohibidos: entre otros `TIMESTAMP`, `NUMBER`, `BLOCKHASH`, `BALANCE`, `ORIGIN` y
  `GASPRICE`. Por eso los plazos van en `validationData` y los comprueba el EntryPoint (teoría 03).
- Storage: la cuenta lee y escribe el suyo y el *asociado* a ella en otros contratos (por
  ejemplo, `balanceOf[cuenta]` de un token). Una fábrica o un paymaster que usan su propio storage
  necesitan **stake** en el EntryPoint: ETH bloqueado que pierden de reputación si abusan.

Las reglas no las aplica el EntryPoint: las aplica cada bundler al simular. Un test de Foundry no
las comprueba, y una cuenta que pasa tus tests puede ser rechazada por todos los bundlers.

## Antipatrones y riesgos

- **Dueño fuera de la creación.** Una fábrica con `initialize` posterior deja la cuenta a quien
  despliegue primero. El dueño va en los argumentos del constructor o en la sal.
- **Fábrica que revierte si la cuenta existe.** La segunda operación con `initCode` (o una
  carrera entre dos bundlers) falla. Devuelve la existente.
- **Un firmante sin probar.** Cada firmante nuevo (passkey, multisig, clave de sesión) es la
  cerradura de la cuenta. Un error en él es un error en todas las cuentas que lo usan.
- **`ecrecover` para firmas de cuentas.** Un contrato que solo acepta ECDSA deja fuera a las
  cuentas contrato. Usa `SignatureChecker`, que prueba ECDSA y luego ERC-1271.
- **Una cuenta actualizable sin cuidado.** Si la cuenta es un proxy, quien cambia la
  implementación es dueño de todo: el mismo riesgo que H-04, en cada usuario.
- **Validación que lee estado global.** Funciona en tus tests y la rechazan los bundlers.

## Trucos

- `entryPoint.getSenderAddress(initCode)` revierte con `SenderAddressResult(dirección)`: la forma
  oficial de saber la dirección que dará un `initCode`.
- `vm.computeCreate2Address(salt, initCodeHash, factory)` da la misma dirección en un test, sin
  la fábrica.
- El primer `verificationGasLimit` incluye el despliegue: mídelo una vez y deja margen.
- Prueba cada firmante con una firma buena, una de otro, una ilegible y una de otra red.

## ✅ Checklist

- [ ] Sé calcular la dirección de una cuenta antes de desplegarla.
- [ ] Sé qué lleva `initCode` y quién llama a la fábrica.
- [ ] Sé por qué el dueño va en el código de creación.
- [ ] Sé montar una cuenta con `Account`, un firmante y `ERC7821`.
- [ ] Sé por qué un `permit` no funciona con una cuenta contrato sin ERC-1271.
- [ ] Sé qué limita ERC-7562 en la validación y por qué hace falta stake.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 01 — Cuentas y UserOperations](01-cuentas-y-user-operations.md) | **Teoría 02 — Cuentas, fábricas y firmas** | [Teoría 03 — Paymasters →](03-paymasters.md) |
