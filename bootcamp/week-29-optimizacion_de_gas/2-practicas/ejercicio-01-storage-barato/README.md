# Ejercicio 01 — Storage barato

> Al terminar habrás empaquetado un `struct`, sacado de un bucle las lecturas y escrituras de
> storage, cambiado un `mapping` de `bool` por un bitmap, pasado a `immutable` una variable que
> no cambia y sustituido un array de storage por un evento. Y sabrás cuánto ahorró cada cosa.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 01 — Medir el gas](../../1-teoria/01-medir-el-gas.md) y
[Teoría 02 — El storage manda](../../1-teoria/02-el-storage-manda.md) leídas.

## Contexto

Proyecto Foundry. `Club` es un club de socios: altas, puntos para todos, premios que se reclaman una
vez y pagos. Funciona, y sus tests de comportamiento ya pasan. Pero cada función gasta de más en
storage, y cada paso arregla una sin cambiar lo que hace.

| Archivo | Qué es |
| ------- | ------ |
| `src/Club.sol` | El contrato: tu trabajo, pasos 1 a 5 |
| `test/Club.t.sol` | Dos tests por tema: uno de comportamiento, en verde desde el principio, y uno de gas por paso, `test_PasoN_...`, con un tope. No lo cambies |

Cada paso **sustituye** código: borra las líneas que acaban en `// <- Paso N` y descomenta (quita
el `//> ` del principio) las que hay debajo, las del mismo paso. Los topes de gas valen para solc
0.8.38 sin optimizador, la configuración de este `foundry.toml`.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-29-optimizacion_de_gas/2-practicas/ejercicio-01-storage-barato/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `5 tests passed, 5 failed`. Pasan los cinco de comportamiento y fallan los cinco de
gas, cada uno con su número:

```text
[FAIL: Paso 1: join gasta demasiado: 95824 >= 80000] test_Paso1_JoinFitsBudget()
```

`95824` es el gas de la transacción de `join`, con sus 21 000 de base (teoría 01), y `80000`, el
tope.

## Paso 1: Empaquetar `Member`

**Por qué**: con `active` primero y `points` detrás, `Member` ocupa tres slots: `active` solo en
el primero, `points` en el segundo, `account` y `joinedAt` en el tercero. `account` (20 bytes),
`joinedAt` (8) y `active` (1) caben juntos en 29 bytes. Cada `join` escribe un `Member` nuevo:
un slot menos es un `SSTORE` de cero a otro valor menos.

**Abre** `src/Club.sol` y cambia el orden de los campos:

```solidity
struct Member {
    address account;
    uint64 joinedAt;
    bool active;
    uint256 points;
}
```

`join` construye el `Member` con los nombres de los campos, y `memberOf` lo devuelve entero: ni
una ni otra dependen del orden.

**Verifica**: `6 tests passed, 4 failed`. `test_Paso1_JoinFitsBudget` mide un `join` de una cuenta
nueva; ahora que pasa, mira su gas en la traza:

```bash
forge test --mt test_Paso1 -vvvv
```

```text
    ├─ [73973] Club::join()
```

`join` pasa de 95 824 a 73 973: 21 851 menos. Usa la misma traza en cada paso para ver el número
nuevo. `test_JoinStoresMember` sigue en verde: los datos son
los mismos.

## Paso 2: Leer una vez y escribir una vez

**Por qué**: `rewardAll` da puntos a los 10 socios del `setUp`. En cada vuelta lee
`_members.length` de storage y suma a `totalPoints` en storage: 10 lecturas de la longitud y 10
lecturas y escrituras de `totalPoints`. Las de `points` hacen falta, una por socio; las otras no.
Lee la longitud una vez a una variable local, y suma el total una vez, al final.

**Abre** `src/Club.sol` y resuelve `rewardAll`:

```solidity
uint256 n = _members.length;
for (uint256 i = 0; i < n; i++) {
    _members[i].points += amount;
}
totalPoints += amount * n;
```

**Verifica**: `7 tests passed, 3 failed`. `rewardAll` pasa de 278 739 a 274 220. Son solo 4519:
lo que pesa en `rewardAll` son las 10 escrituras de `points`, frías y de cero a otro valor, que
siguen ahí.

## Paso 3: Un bitmap de premios

**Por qué**: `claimed[prize] = true` escribe un slot nuevo por cada premio, de cero a otro valor.
Con un bitmap, 256 premios comparten una palabra: el premio 1, después del 0, cambia una palabra
que ya no es cero (teoría 02).

**Abre** `src/Club.sol` y resuelve la declaración, `claim` e `isClaimed`:

```solidity
mapping(uint256 => uint256) private _claimedWords;
```

```solidity
_claimedWords[prize >> 8] |= 1 << (prize & 0xff);
```

```solidity
return _claimedWords[prize >> 8] & (1 << (prize & 0xff)) != 0;
```

**Verifica**: `8 tests passed, 2 failed`. El segundo premio pasa de 44 143 a 27 036.
`testFuzz_ClaimMarksOnlyThatPrize` prueba con dos premios cualesquiera que reclamar uno no marca el
otro: es lo que rompería una máscara mal escrita.

Mira el fallo de `test_Paso5_PayFitsBudget`: `pay` gastaba 67 562 y ahora 67 584, sin que hayas
tocado `pay`. Quitaste la función pública `claimed` y cambió el orden en que el contrato busca los
selectores (teoría 04): 22 de ruido.

## Paso 4: `immutable`

**Por qué**: `owner` se escribe en el constructor y nunca más. Como variable de estado, cada
lectura es un `SLOAD`: 2100 la primera vez en cada transacción. Como `immutable`, el valor queda
escrito en el bytecode y leerlo es un `PUSH`.

**Abre** `src/Club.sol`. `owner` aparece en cuatro sitios, y los cuatro llevan su `// <- Paso 4`:
la declaración, el constructor, `rewardAll` e `isOwner`. El nombre pasa a `OWNER`, en mayúsculas
como toda `immutable`:

```solidity
address public immutable OWNER;
```

**Verifica**: `9 tests passed, 1 failed`. `isOwner` pasa de 2800 a 688: es `view`, así que la
llamada no se aísla y no lleva gas base (teoría 01), y lo que desaparece es el `SLOAD` frío.
`rewardAll` también baja, de 274 220 a 272 085.

## Paso 5: Un evento en vez de un array

**Por qué**: `pay` guarda cada importe en `payments`, un array de storage: escribe la longitud y un
elemento nuevo. Nadie en el contrato lee `payments`; está para que lo lea la página. El evento
`Paid` ya lleva el mismo dato, y un log cuesta mucho menos que dos escrituras.

**Abre** `src/Club.sol` y borra la declaración de `payments` y la línea de `pay` que lo usa: las
dos acaban en `// <- Paso 5`, y no hay nada que descomentar.

**Verifica**: `10 tests passed, 0 failed`. `pay` pasa de 67 584 a 23 242.
`test_PayEmitsPaid` comprueba que el evento sigue saliendo con quién pagó y cuánto.

## Para pensar

- En el paso 1, `points` va en su propio slot. ¿Lo pondrías en un `uint96` junto a `account`?
  ¿Qué tendría que comprobar `rewardAll` entonces, y qué pasa con `joinedAt` y `active`?
- En el paso 3, ¿cuánto costaría el premio 256 justo después del 255? ¿Y el 1000 después del 0?
- En el paso 5, la página lee los pagos del evento. ¿Qué pierdes si mañana otro contrato necesita
  saber cuánto pagó un socio?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — Cuándo no optimizar](../../1-teoria/04-cuando-no-optimizar.md) | **Ejercicio 01 — Storage barato** | [Ejercicio 02 — Código barato →](../ejercicio-02-codigo-barato/README.md) |
