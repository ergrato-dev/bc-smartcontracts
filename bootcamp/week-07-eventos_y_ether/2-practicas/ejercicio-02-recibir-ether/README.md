# Ejercicio 02 — Recibir ETH

> Al terminar habrás cobrado ETH en una función `payable`, aceptado envíos sin datos con
> `receive`, rechazado llamadas desconocidas con `fallback`, leído el saldo del contrato y
> convertido unidades de ETH y de tiempo.

**Duración estimada**: 2 h
**Prerrequisitos**: [Ejercicio 01](../ejercicio-01-eventos/README.md) terminado;
[Teorías 02 y 03](../../1-teoria/02-unidades-y-variables-globales.md) leídas.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/TipJar.sol` | Un bote de propinas con un mínimo (`MIN_TIP = 0.001 ether`) y un cierre (`CLOSES_AT`), que el constructor ya calcula. Aquí trabajas |
| `test/TipJar.t.sol` | Cinco tests, uno por paso. **No lo modifiques** |

Los tests usan dos piezas nuevas de la plantilla:

- `vm.deal(alice, 1 ether)` le da a una cuenta de prueba 1 ETH para gastar.
- `address(jar).call{value: x}(datos)` envía ETH y datos sin nombrar ninguna función: es
  como llegan `receive` y `fallback`. Devuelve `ok` (si salió bien) y lo que respondió el
  contrato.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-07-eventos_y_ether/2-practicas/ejercicio-02-recibir-ether/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con `Warning (2018)` y `Warning (5667)`.

**Verifica**: cinco `FAIL`. Los de los pasos 1, 4 y 5 con `TODO: Paso 1`.

## Paso 1: Una función `payable`

**Por qué**: sin `payable`, la función rechaza el ETH. Con `payable`, el ETH ya está en el
contrato cuando empieza la función, y `msg.value` dice cuánto llegó.

**Abre** `src/TipJar.sol`:

```solidity
function tip() public payable {
    if (block.timestamp >= CLOSES_AT) revert JarClosed(CLOSES_AT);
    if (msg.value < MIN_TIP) revert TipTooSmall(MIN_TIP, msg.value);
    tipsOf[msg.sender] += msg.value;
    totalTips += msg.value;
    emit Tipped(msg.sender, msg.value);
}
```

Si revierte, el ETH vuelve a quien lo envió. `tip` es `public` y no `external` porque en
el paso 2 la llama `receive`.

**Verifica**: `[PASS] test_Step1_Tip()`. El test comprueba que Alice se queda con
`0.99 ether`, que 1 gwei no llega al mínimo y que un bote creado con `new TipJar(0)` ya
está cerrado.

Prueba a quitar `payable` de `tip` y ejecuta `forge test`. No compila:

```
Error (7006): Cannot set option "value" on a non-payable function type.
  --> test/TipJar.t.sol:26:9:
   |
26 |         jar.tip{value: 0.01 ether}();
   |         ^^^^^^^^^^^^^^^^^^^^^^^^^^
```

Vuelve a ponerlo.

## Paso 2: `receive`

**Por qué**: una transferencia sin datos (como las de la semana 02) no nombra ninguna
función. `receive` decide qué hacer con ella; aquí, tratarla como una propina.

```solidity
receive() external payable {
    tip();
}
```

**Verifica**: `[PASS] test_Step2_Receive()`. 0.002 ETH a pelo cuentan como propina de
Alice; 1 wei no llega al mínimo y el envío falla (`ok == false`).

## Paso 3: `fallback` que rechaza

**Por qué**: si alguien llama a una función que no existe, es un error suyo. Mejor un error
claro que quedarse con su ETH en silencio.

```solidity
fallback() external {
    revert UnknownFunction(msg.sig);
}
```

`msg.sig` son los 4 primeros bytes de los datos: el selector que intentó llamar. Al no ser
`payable`, ni siquiera acepta ETH.

**Verifica**: `[PASS] test_Step3_Fallback()`. El test llama con `0x12345678` y espera
`UnknownFunction(0x12345678)`; con 0.01 ETH, el envío falla y Alice conserva su 1 ETH.

## Paso 4: El saldo del contrato

**Por qué**: el contrato es una cuenta con saldo propio, en wei.

```solidity
function balance() external view returns (uint256) {
    return address(this).balance;
}
```

**Verifica**: `[PASS] test_Step4_Balance()`: dos propinas, `0.03 ether`.

## Paso 5: Unidades

**Por qué**: el contrato solo ve wei y segundos. Para mostrar otra unidad, divide por su
sufijo.

```solidity
function stats(address from) external view returns (uint256 tipsInGwei, uint256 daysLeft) {
    tipsInGwei = tipsOf[from] / 1 gwei;
    if (block.timestamp < CLOSES_AT) daysLeft = (CLOSES_AT - block.timestamp) / 1 days;
}
```

El `if` evita restar cuando el bote ya cerró: `CLOSES_AT - block.timestamp` daría negativo
y revertiría con `Panic(0x11)` (semana 05).

**Verifica**: `forge test` termina con
`5 tests passed, 0 failed, 0 skipped (5 total tests)` y sin warnings. `0.0015 ether` son
`1 500 000` gwei; un bote de `36 hours` tiene `1` día completo por delante.

`forge build` te muestra además una nota de su revisión de estilo:

```
warning[locked-ether]: contract can receive ETH but has no mechanism to send it out
```

Tiene razón: nadie puede sacar las propinas. En el ejercicio 03 aprendes a enviar ETH.

## ✅ Criterios de éxito

- `forge test` pasa los 5 tests sin warnings.
- Explicas qué pasa con el ETH cuando `tip` revierte.
- Explicas cuándo se ejecuta `receive`, cuándo `fallback` y por qué este `fallback` no es
  `payable`.
- Explicas por qué este bote, tal como está, es un riesgo para quien deja propinas.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Eventos](../ejercicio-01-eventos/README.md) | **Ejercicio 02 — Recibir ETH** | [Ejercicio 03 — Enviar ETH →](../ejercicio-03-enviar-ether/README.md) |
