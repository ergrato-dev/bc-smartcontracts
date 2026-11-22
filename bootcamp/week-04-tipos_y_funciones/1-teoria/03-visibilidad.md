# Teoría 03 — Visibilidad

## 🎯 Objetivos

- Elegir entre `external`, `public`, `internal` y `private` para cada función.
- Usar el getter automático de una variable de estado `public`.
- Explicar por qué `private` no oculta ningún dato.
- Reconocer los errores de visibilidad del compilador.

---

## 1. Qué problema resuelve

En la semana 03 todas las funciones eran `external` y las variables de estado no llevaban
visibilidad: las leías con funciones escritas a mano (`get()`, `total()`). La
**visibilidad** dice desde dónde se puede usar una función o una variable: desde fuera
del contrato (una cuenta, `cast`, otro contrato) o solo desde dentro. Es la primera
frontera de seguridad: cada función que se ve desde fuera es una puerta que cualquiera
puede abrir.

## 2. Las cuatro visibilidades de una función

| Visibilidad | Desde fuera | Desde el propio contrato | Desde un contrato que hereda (semana 10) |
| ----------- | ----------- | ------------------------ | ---------------------------------------- |
| `external` | ✅ | ❌ | ❌ |
| `public` | ✅ | ✅ | ✅ |
| `internal` | ❌ | ✅ | ✅ |
| `private` | ❌ | ✅ | ❌ |

Toda función tiene que decir la suya. Si la olvidas:

```solidity
function f() pure returns (uint256) { // ❌ sin visibilidad
    return 1;
}
```

```
Error (4937): No visibility specified. Did you intend to add "public"?
```

Una función `external` no se puede llamar por su nombre desde dentro del contrato:

```solidity
function f() external pure returns (uint256) {
    return 1;
}

function g() external pure returns (uint256) {
    return f(); // ❌
}
```

```
Error (7576): Undeclared identifier. "f" is not (or not yet) visible at this point.
```

Si la función se llama desde fuera y desde dentro, hazla `public`. Si solo desde dentro,
`internal` o `private`. Por convención, los nombres de funciones `internal` y `private`
empiezan por `_`: `_fee(amount)` avisa al que lee de que no es una puerta.

## 3. Funciones internas

Una función `internal` es un trozo de lógica reutilizable que nadie de fuera puede
ejecutar. No aparece en la ABI:

```solidity
function _fee(uint256 amount) internal pure returns (uint256) {
    return amount / 100;
}

function add(uint256 amount) public {
    total += amount - _fee(amount);
}
```

Llamar a una función interna es un salto dentro del mismo bytecode: no hay llamada nueva
ni selector.

## 4. Visibilidad de las variables de estado

Las variables de estado admiten `public`, `internal` o `private` (no `external`). Sin
nada, son `internal`: así estaban las de la semana 03.

Con `public`, el compilador escribe por ti una función con el nombre de la variable que
devuelve su valor: el **getter**. Este contrato:

```solidity
contract Config {
    uint256 public constant MAX_LIMIT = 1000;
    address public immutable OWNER;
    uint256 public limit;
    uint256 private secret = 7;
    // constructor y setLimit...
}
```

tiene en su ABI:

```bash
forge inspect Config abi --json | jq -c '[.[] | {type,name}]'
```

```
[{"type":"constructor","name":null},{"type":"function","name":"MAX_LIMIT"},{"type":"function","name":"OWNER"},{"type":"function","name":"limit"},{"type":"function","name":"setLimit"}]
```

`limit()`, `OWNER()` y `MAX_LIMIT()` son getters; `secret` no tiene. Un getter es una
función `external view`: se llama con `cast call "$CONFIG" "limit()(uint256)"`.

## 5. `private` no es secreto

`private` solo significa que **otros contratos** no pueden leer la variable a través del
código. El dato está en el storage, y el storage es público:

```bash
cast call "$CONFIG" "secret()(uint256)"
```

```
Error: server returned an error response: error code 3: execution reverted, data: "0x"
```

No hay función `secret()`: el bytecode no encuentra el selector y revierte. Pero
`secret` es la segunda variable que ocupa storage (las constantes e inmutables no
cuentan), así que está en el slot 1:

```bash
cast storage "$CONFIG" 1 | cast to-dec
```

```
7
```

Nada que se guarde en un contrato es secreto: ni contraseñas, ni claves, ni la respuesta
de un juego. Lo verás tú mismo en el ejercicio 03.

## 6. Antipatrones y riesgos

- **`public` por costumbre**: cada función visible desde fuera es superficie de ataque.
  Empieza por `internal` y abre solo lo que tiene que llamar una cuenta u otro contrato.
- **Funciones auxiliares `public`**: una función que solo calcula para otra puede acabar
  llamándose desde fuera con argumentos que nadie previó. Hazla `internal`.
- **Guardar un secreto en una variable `private`**: es legible con `cast storage`.
- **Funciones que escriben estado sin control**: por ahora cualquiera puede llamar a
  `setLimit`. La semana 05 añade `require` y modificadores para decidir quién puede.

## 7. Trucos

- `forge inspect <Contrato> abi --json` lista todas las puertas del contrato: repásala
  antes de desplegar.
- Una variable `public` te ahorra escribir su función de lectura y garantiza que el
  nombre de la función coincide con el de la variable.
- Prefijo `_` para todo lo `internal` o `private`: se ve a simple vista qué es puerta y
  qué no.

## ✅ Checklist

- [ ] Explico qué permite cada una de las cuatro visibilidades.
- [ ] Sé por qué una función `external` no se llama desde dentro y qué usar en su lugar.
- [ ] Sé qué getter genera una variable `public` y cómo llamarlo con `cast`.
- [ ] Leo una variable `private` de un contrato desplegado.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 02 — Variables de estado y storage](02-variables-de-estado-y-storage.md) | **Teoría 03 — Visibilidad** | [Teoría 04 — Funciones: view, pure y retornos →](04-funciones-view-pure-y-retornos.md) |
