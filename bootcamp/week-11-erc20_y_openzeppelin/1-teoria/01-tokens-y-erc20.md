# Teoría 01 — Tokens y ERC-20

## 🎯 Objetivos

- Explicar qué es un token y por qué es un contrato, no una moneda de la red.
- Nombrar las funciones y los eventos del estándar ERC-20.
- Convertir entre tokens y unidades mínimas con `decimals`.
- Leer y mover un token con `cast`, y leer sus transferencias en los logs.

---

## 1. Qué problema resuelve

El ETH es la moneda de la red: su saldo lo guarda la propia EVM en cada cuenta (semana 07).
Pero muchas aplicaciones quieren su propia unidad de valor: puntos de fidelidad, un dólar
digital, el voto en una organización, la participación en un fondo.

Un **token** es eso: un contrato que guarda una tabla de saldos (`dirección → cantidad`)
y deja moverlos según sus reglas. Nada más. La red no sabe que existe; para ella son
llamadas a un contrato y escrituras en su storage.

El problema aparece cuando hay miles de tokens. Una wallet, un exchange o otro contrato
querrían manejarlos todos sin leer el código de cada uno. Para eso hace falta que todos
respondan a las mismas funciones con los mismos nombres.

**ERC-20** ([EIP-20](https://eips.ethereum.org/EIPS/eip-20), 2015) es ese acuerdo: la
interfaz que tiene que cumplir un token **fungible**. Fungible significa que cada unidad
vale lo mismo que cualquier otra: tu token y el mío son intercambiables, como dos billetes
de 10. (Los no fungibles, donde cada token es único, son la semana 12.)

Un **ERC** (*Ethereum Request for Comments*) es un EIP que define un estándar de
aplicación: no cambia la red, solo fija cómo se habla con un tipo de contrato.

## 2. Cómo funciona

El estándar pide seis funciones y dos eventos. Tres funciones de lectura más son
opcionales, aunque casi todos los tokens las tienen:

| Función | Qué hace |
| ------- | -------- |
| `totalSupply()` | Cuántas unidades existen en total |
| `balanceOf(account)` | Cuántas tiene una cuenta |
| `transfer(to, value)` | Mueve `value` de quien llama a `to`. Devuelve `bool` |
| `approve(spender, value)` | Permite que `spender` mueva hasta `value` de las tuyas (teoría 02) |
| `allowance(owner, spender)` | Cuánto puede mover aún `spender` de `owner` (teoría 02) |
| `transferFrom(from, to, value)` | Mueve de `from` gastando el permiso de quien llama (teoría 02) |
| `name()`, `symbol()`, `decimals()` | Opcionales: nombre, abreviatura y decimales |

| Evento | Cuándo se emite |
| ------ | --------------- |
| `Transfer(from, to, value)` | En cada movimiento, también al crear (`from` = `address(0)`) y al destruir (`to` = `address(0)`) |
| `Approval(owner, spender, value)` | En cada `approve` |

Los eventos no son decoración. Un contrato no puede preguntar "¿qué cuentas tienen este
token?": la tabla de saldos no se recorre. Las wallets y los exploradores reconstruyen
el historial leyendo los `Transfer` de los logs (semana 07).

### Decimales

La EVM no tiene números con decimales. Un token guarda enteros y declara con `decimals`
dónde va la coma al mostrarlos. Con `decimals = 18`, la cantidad guardada `2500000000000000000`
se muestra como `2.5`. Es lo mismo que wei y ether (semana 07): 18 decimales es lo habitual
porque imita al ETH, pero no es obligatorio. USDC usa 6.

`decimals` solo cambia cómo se muestra. Los contratos siempre trabajan en **unidades
mínimas**: `transfer(to, 1)` mueve una unidad mínima, no un token.

## 3. Cómo se escribe

En `src/Coin.sol` de un proyecto nuevo (copia la plantilla de siempre), un token con solo
la mitad del estándar: saldos y `transfer`. La otra mitad llega en la teoría 02.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

contract Coin {
    string public constant name = "Class Coin";
    string public constant symbol = "CLS";
    uint8 public constant decimals = 18;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    error InsufficientBalance(address from, uint256 balance, uint256 needed);

    constructor(uint256 supply) {
        totalSupply = supply;
        balanceOf[msg.sender] = supply;
        emit Transfer(address(0), msg.sender, supply);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        uint256 balance = balanceOf[msg.sender];
        if (balance < value) revert InsufficientBalance(msg.sender, balance, value);
        balanceOf[msg.sender] = balance - value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
}
```

- `name`, `symbol` y `decimals` son `constant` públicas: Solidity genera las funciones
  `name()`, `symbol()` y `decimals()` que pide el estándar. Van en minúsculas porque así se
  llaman en el estándar.
- `balanceOf` es un mapping público: su getter es justo `balanceOf(address)`.
- El constructor crea todo el suministro para quien despliega y lo anuncia con un
  `Transfer` desde `address(0)`. Así una wallet ve aparecer los tokens.
- `transfer` devuelve `true`. El estándar lo pide; la teoría 04 cuenta qué pasa con los
  tokens que no lo hacen.

### Desplegar y usar con `cast`

Dentro del contenedor, con `anvil --silent &` arrancado:

```bash
M="test test test test test test test test test test test junk"
PK0=$(cast wallet private-key "$M" 0); A0=$(cast wallet address "$PK0")
A1=$(cast wallet address $(cast wallet private-key "$M" 1))
forge create src/Coin.sol:Coin --private-key "$PK0" --broadcast --constructor-args $(cast parse-units 1000 18)
C=0x5FbDB2315678afecb367f032d93F642f64180aa3
cast call $C "symbol()(string)"
cast call $C "totalSupply()(uint256)"
cast format-units $(cast call $C "balanceOf(address)" $A0) 18
```

```
"CLS"
1000000000000000000000 [1e21]
1000
```

`cast parse-units 1000 18` convierte tokens en unidades mínimas (multiplica por 10¹⁸) y
`cast format-units ... 18` hace lo contrario. A `format-units` se le pasa la respuesta sin
decodificar (sin `(uint256)`): con el `[1e21]` del final no la entendería.

Envía 2,5 tokens a la cuenta 1:

```bash
cast send $C "transfer(address,uint256)" $A1 $(cast parse-units 2.5 18) --private-key "$PK0"
cast call $C "balanceOf(address)(uint256)" $A1
```

Recibo con `status 1 (success)`, y `2500000000000000000 [2.5e18]`.

### Las transferencias, en los logs

```bash
cast logs --from-block 0 --address $C "Transfer(address indexed,address indexed,uint256)"
```

El primer log es la creación, en el bloque 1:

```
  topics: [
  	0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
  	0x0000000000000000000000000000000000000000000000000000000000000000
  	0x000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266
  ]
  ...
  decoded:
  	param0: 0x0000000000000000000000000000000000000000
  	param1: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
  	param2: 1000000000000000000000 [1e21]
```

El topic 0 es `cast keccak "Transfer(address,address,uint256)"`, y es **el mismo en todos
los tokens ERC-20 del mundo**. Por eso un explorador encuentra todas las transferencias de
todos los tokens con un solo filtro. `from` y `to` van en topics porque son `indexed`; la
cantidad va en `data`.

## 4. Antipatrones y riesgos

**Enviar tokens al propio contrato del token.** Es un error frecuente al copiar una
dirección:

```bash
cast send $C "transfer(address,uint256)" $C $(cast parse-units 1 18) --private-key "$PK0"
cast format-units $(cast call $C "balanceOf(address)" $C) 18
```

`status 1 (success)` y `1`: el token quedó en el saldo del contrato `Coin`, que no tiene
ninguna función para sacarlo. Está perdido para siempre. En la historia de Ethereum se han
perdido así millones en tokens. El ejercicio 02 lo impide.

**Enviar a `address(0)`.** Este `Coin` lo permite. Sería otra pérdida, y además los logs lo
confundirían con una destrucción de tokens. OpenZeppelin lo rechaza (teoría 03).

**Confundir unidades.** `transfer(to, 1)` no envía un token, envía 10⁻¹⁸ tokens. Al revés,
un contrato que suma cantidades de dos tokens con distintos `decimals` (18 y 6) mezcla
unidades que no se parecen. Trabaja siempre en unidades mínimas y convierte solo al
mostrar.

**Creer que un token "es" su nombre o su símbolo.** `name` y `symbol` los elige quien
despliega: cualquiera puede desplegar un token llamado "USD Coin" con símbolo `USDC`. Lo
único que identifica a un token es la **dirección de su contrato**. Una wallet o un contrato
que acepta un token por su símbolo puede recibir uno falso.

**Errores con el saldo insuficiente.** El estándar no fija cómo fallar. Este `Coin` usa
un error propio:

```
Error: ... execution reverted: custom error 0xdb42144d: ...: InsufficientBalance(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC, 0, 1)
```

Otros tokens revierten con un texto o, los más antiguos, devuelven `false` sin revertir.
Quien llama tiene que estar preparado para todos (teoría 04).

## 5. Trucos

- `cast parse-units 1.5 18` da `1500000000000000000`, y `cast format-units 1500000 6` da
  `1.500000`. Úsalos en vez de contar ceros.
- En Solidity, `ether` también sirve como "×10¹⁸" para un token de 18 decimales:
  `100 ether` es `100 * 10**18`. Para uno de 6, escribe `100 * 10**6`.
- `cast sig-event "Transfer(address,address,uint256)"` imprime el topic 0 del evento, igual
  que `cast keccak`.

## ✅ Checklist

- [ ] Sé qué guarda un contrato de token y qué no sabe la red de él.
- [ ] Nombro las seis funciones y los dos eventos de ERC-20.
- [ ] Convierto entre tokens y unidades mínimas con `decimals` y con `cast`.
- [ ] Explico por qué el topic 0 de `Transfer` es el mismo en todos los tokens.
- [ ] Sé por qué un token enviado al contrato del token se pierde.
- [ ] Sé que un token se identifica por su dirección, no por su símbolo.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Semana 11 — ERC-20 y OpenZeppelin](../README.md) | **Teoría 01 — Tokens y ERC-20** | [Teoría 02 — Allowance →](02-allowance.md) |
