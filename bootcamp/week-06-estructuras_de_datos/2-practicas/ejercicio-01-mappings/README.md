# Ejercicio 01 — Mappings

> Al terminar habrás escrito y leído un mapping, aprovechado su valor por defecto,
> movido valores entre dos claves, usado un mapping anidado, devuelto una clave a su valor
> por defecto con `delete` y distinguido "vale 0" de "nunca se dio de alta".

**Duración estimada**: 1 h 30 min
**Prerrequisitos**: [Teoría 01 — Mappings](../../1-teoria/01-mappings.md) leída.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/Points.sol` | Un programa de puntos con tres mappings (`points`, `isMember`, `isFriend`) y dos errores ya declarados. Aquí trabajas |
| `test/Points.t.sol` | Seis tests, uno por paso. **No lo modifiques** |

Los tres mappings son `public`: los tests los leen con sus getters, `p.points(alice)` o
`p.isFriend(alice, bob)`.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-06-estructuras_de_datos/2-practicas/ejercicio-01-mappings/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con `Warning (2018)` y `Warning (5667)`. Desaparecen al resolver los pasos.

**Verifica**: seis `FAIL`. Los tests de los pasos 3 y 5 fallan con `TODO: Paso 1`: llaman
a `addPoints` para preparar el estado.

## Paso 1: Escribir en un mapping

**Por qué**: es la operación básica: el valor de una clave, leído y modificado.

**Abre** `src/Points.sol`:

```solidity
function addPoints(address user, uint256 amount) external {
    points[user] += amount;
}
```

`points[user]` empieza en 0 para cualquier `user`, así que `+=` funciona desde la primera
vez.

**Verifica**: `[PASS] test_Step1_AddPoints()`. El test suma 10 y 5 a `alice` y comprueba
que `bob`, que nadie tocó, lee `0`.

## Paso 2: El valor por defecto

**Por qué**: "no tiene puntos" y "nunca se escribió" son lo mismo para un mapping.

```solidity
function hasPoints(address user) external view returns (bool) {
    return points[user] != 0;
}
```

**Verifica**: `[PASS] test_Step2_HasPoints()`.

## Paso 3: Mover entre dos claves

**Por qué**: una transferencia toca dos claves del mismo mapping, y la guarda va antes de
escribir.

```solidity
function transferPoints(address to, uint256 amount) external {
    uint256 available = points[msg.sender];
    if (amount > available) revert InsufficientPoints(available, amount);
    points[msg.sender] = available - amount;
    points[to] += amount;
}
```

`available` evita leer `points[msg.sender]` del storage dos veces.

**Verifica**: `[PASS] test_Step3_TransferPoints()`. El test pasa 12 de 30 a `bob` y después
intenta pasar 20 de los 18 que quedan.

## Paso 4: Mapping anidado

**Por qué**: una relación entre dos cuentas necesita dos claves.

```solidity
function setFriend(address friend, bool value) external {
    isFriend[msg.sender][friend] = value;
}
```

**Verifica**: `[PASS] test_Step4_SetFriend()`. El test comprueba que `isFriend(alice, bob)`
es `true` y que `isFriend(bob, alice)` sigue en `false`: el orden de las claves importa.

## Paso 5: `delete`

**Por qué**: devolver una clave a su valor por defecto, que además libera storage.

```solidity
function resetPoints() external {
    delete points[msg.sender];
}
```

**Verifica**: `[PASS] test_Step5_ResetPoints()`.

## Paso 6: Distinguir "vale 0" de "nunca se dio de alta"

**Por qué**: tras `join()`, una cuenta tiene 0 puntos, igual que una que nunca se unió.
`points` no puede distinguirlas; `isMember` sí.

```solidity
function join() external {
    if (isMember[msg.sender]) revert AlreadyMember(msg.sender);
    isMember[msg.sender] = true;
}
```

**Verifica**: `forge test` termina con
`6 tests passed, 0 failed, 0 skipped (6 total tests)` y sin warnings.

Prueba a cambiar la guarda por `if (points[msg.sender] != 0) revert ...` y ejecuta
`forge test --match-test test_Step6`: falla, porque la segunda llamada a `join()` ya no
revierte (`alice` sigue con 0 puntos). Vuelve a ponerla.

## ✅ Criterios de éxito

- `forge test` pasa los 6 tests sin warnings.
- Explicas por qué `points(bob)` devuelve `0` sin que nadie lo haya escrito.
- Explicas por qué hace falta `isMember` si ya existe `points`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 05 — Patrones de colecciones](../../1-teoria/05-patrones-de-colecciones.md) | **Ejercicio 01 — Mappings** | [Ejercicio 02 — Structs y enums →](../ejercicio-02-structs-y-enums/README.md) |
