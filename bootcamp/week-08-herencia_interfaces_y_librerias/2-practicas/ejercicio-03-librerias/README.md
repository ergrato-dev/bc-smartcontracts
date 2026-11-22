# Ejercicio 03 — Librerías

> Al terminar habrás escrito una librería de cálculo y otra que trabaja sobre el storage de
> quien la usa, las habrás usado con `using for` en un club que cobra una cuota y habrás
> visto cuánto se pierde al dividir antes de multiplicar.

**Duración estimada**: 2 h
**Prerrequisitos**: [Ejercicio 02](../ejercicio-02-interfaces/README.md) terminado;
[Teoría 05](../../1-teoria/05-librerias.md) leída.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/Bps.sol` | Librería de porcentajes en puntos básicos. Aquí trabajas |
| `src/AddressList.sol` | Librería para un array de direcciones sin repetidos. Aquí trabajas |
| `src/Club.sol` | Un club: entrar cuesta `FEE` (0,01 ETH); el 25 % va a la tesorería y el resto al bote de premios. Usa las dos librerías. Aquí trabajas |
| `test/Club.t.sol` | Cinco tests, uno por paso. **No lo modifiques** |

Un **punto básico** (*basis point*, bps) es una centésima de porcentaje: 10 000 bps son el
100 %, 2 500 bps el 25 %. En la EVM no hay decimales, y los importes en wei son enteros:
los porcentajes se escriben en bps para no perder precisión.

Los tests de los pasos 1 a 3 usan las librerías desde el propio contrato de test, con
`using Bps for uint256;` y un `address[] list` en su storage: una librería funciona
igual en cualquier contrato.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-08-herencia_interfaces_y_librerias/2-practicas/ejercicio-03-librerias/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con `Warning (2018)`, `Warning (5667)` y `Warning (5740)` (código inalcanzable
detrás de cada `revert`).

**Verifica**: cinco `FAIL`. El del paso 5 con `TODO: Paso 4`: para salir del club, antes
hay que entrar.

## Paso 1: Porcentajes

**Por qué**: la división entera redondea hacia abajo. Multiplicando primero, solo se
pierde lo que queda tras la última división.

**Abre** `src/Bps.sol`:

```solidity
function bps(uint256 amount, uint256 rate) internal pure returns (uint256) {
    return amount * rate / MAX;
}
```

**Verifica**: `[PASS] test_Step1_Bps()`. El 25 % de 1 ETH es 0,25 ETH, y el de 999 wei es
249 (249,75 redondeado hacia abajo).

Rompe a propósito: cambia el orden a `amount / MAX * rate` y ejecuta
`forge test --match-test test_Step1`:

```
[FAIL: assertion failed: 0 != 249] test_Step1_Bps() (gas: 4364)
```

`999 / 10000` ya es 0, y 0 por lo que sea es 0. Con 1 ETH pasa la prueba por casualidad,
porque 10^18 es múltiplo de 10 000; con importes que no lo son, cada operación regala o se
come wei. Vuelve al orden correcto.

## Paso 2: ¿Está en la lista?

**Por qué**: `self` es una referencia `storage` al array del contrato que usa la librería:
la librería lo lee sin copiarlo.

**Abre** `src/AddressList.sol`:

```solidity
function contains(address[] storage self, address account) internal view returns (bool) {
    for (uint256 i = 0; i < self.length; i++) {
        if (self[i] == account) return true;
    }
    return false;
}
```

**Verifica**: `[PASS] test_Step2_Contains()`.

## Paso 3: Quitar sin dejar huecos

**Por qué**: `delete self[i]` pone esa posición a `address(0)` pero no acorta el array.
Cambiar la que sale por la última y hacer `pop` la quita en un paso, a cambio de alterar el
orden (semana 06).

```solidity
function remove(address[] storage self, address account) internal returns (bool) {
    for (uint256 i = 0; i < self.length; i++) {
        if (self[i] == account) {
            self[i] = self[self.length - 1];
            self.pop();
            return true;
        }
    }
    return false;
}
```

**Verifica**: `[PASS] test_Step3_Remove()`. De `[alice, bob, carol]` sale alice y queda
`[carol, bob]`.

Rompe a propósito: cambia las dos líneas del intercambio por `delete self[i];` y ejecuta
`forge test --match-test test_Step3`:

```
[FAIL: assertion failed: 3 != 2] test_Step3_Remove() (gas: 100360)
```

La lista sigue con 3 posiciones y un `address(0)` donde estaba alice. Vuelve al
intercambio.

## Paso 4: Entrar en el club

**Por qué**: con `using Bps for uint256;` y `using AddressList for address[];`, el club
llama a las librerías como si fueran funciones de sus valores. `_members.contains(...)`
pasa `_members` como `self`. La parte de la tesorería se calcula con la librería y la del
bote es **el resto**, no otro porcentaje: así, el redondeo nunca deja wei sin repartir.

**Abre** `src/Club.sol`:

```solidity
function join() external payable {
    if (msg.value != FEE) revert WrongFee(FEE, msg.value);
    if (_members.contains(msg.sender)) revert AlreadyMember(msg.sender);
    _members.push(msg.sender);
    uint256 toTreasury = msg.value.bps(TREASURY_BPS);
    treasury += toTreasury;
    prizePool += msg.value - toTreasury;
    emit Joined(msg.sender, toTreasury);
}
```

**Verifica**: `[PASS] test_Step4_Join()`. De 0,01 ETH, 0,0025 van a la tesorería y 0,0075
al bote; alice no puede entrar dos veces y bob no puede pagar de más.

## Paso 5: Salir del club

**Por qué**: `remove` devuelve si la cuenta estaba. El club no repite la búsqueda: usa ese
resultado para rechazar a quien no es miembro.

```solidity
function resign() external {
    if (!_members.remove(msg.sender)) revert NotMember(msg.sender);
    emit Left(msg.sender);
}
```

**Verifica**: `forge test` termina con
`5 tests passed, 0 failed, 0 skipped (5 total tests)` y sin warnings. Alice sale, queda
bob, y alice no puede volver a salir.

`forge build` da un aviso: `warning[locked-ether]: contract can receive ETH but has no
mechanism to send it out`. Es cierto: ni la tesorería ni el bote se pueden retirar. Ya
sabes resolverlo (semana 07); aquí no es el tema.

## ✅ Criterios de éxito

- `forge test` pasa los 5 tests sin warnings.
- Explicas por qué `amount / MAX * rate` devuelve 0 con 999 wei y cuánto pierde el club
  con cada orden.
- Explicas por qué el bote se calcula como resto y no como otro porcentaje.
- Explicas por qué `AddressList` modifica el array del club aunque la librería no tenga
  estado.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Interfaces y contratos abstractos](../ejercicio-02-interfaces/README.md) | **Ejercicio 03 — Librerías** | [Proyecto — Registro modular →](../../3-proyecto/README.md) |
