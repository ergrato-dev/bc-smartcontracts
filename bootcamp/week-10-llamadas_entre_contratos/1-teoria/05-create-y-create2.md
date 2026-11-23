# Teoría 05 — CREATE y CREATE2

## 🎯 Objetivos

- Desplegar un contrato desde otro con `new`.
- Calcular de antemano la dirección de un contrato creado con `CREATE` y con `CREATE2`.
- Elegir un `salt` que nadie más pueda ocupar.
- Reconocer los riesgos de una dirección predecible.

---

## 1. Qué problema resuelve

Hasta ahora desplegabas con `forge create` desde una cuenta, o con `new` en el `setUp` de un
test. Un contrato también puede desplegar otros. A ese contrato se le llama **fábrica**
(*factory*):

- Una cuenta de usuario para cada persona (semana 32), un pool para cada par de tokens
  (semana 30), una caja fuerte para cada cliente.
- Todos con el mismo código, desplegado por un contrato que lleva la cuenta de cuáles creó.

Y a veces necesitas saber **la dirección antes de desplegar**: para enviarle ETH a una
caja que aún no existe, o para que un contrato apunte a otro que se desplegará después.

## 2. Cómo funciona

La EVM tiene dos instrucciones para crear contratos. Las dos ejecutan el **código de
creación** (*init code*): el bytecode del constructor seguido de sus argumentos
codificados con la ABI. Lo que cambia es cómo se calcula la dirección:

| | `CREATE` | `CREATE2` |
| - | -------- | --------- |
| En Solidity | `new Vault(owner)` | `new Vault{salt: s}(owner)` |
| La dirección depende de | Quien despliega y su **nonce** | Quien despliega, un **salt** de 32 bytes y el hash del código de creación |
| Fórmula | `keccak256(rlp([deployer, nonce]))`, últimos 20 bytes | `keccak256(0xff ++ deployer ++ salt ++ keccak256(initCode))`, últimos 20 bytes |
| Se predice | Si sabes cuántos contratos habrá desplegado antes | Siempre, sin depender del orden |

El **nonce** de una cuenta cuenta sus transacciones (semana 02). El de un contrato cuenta
los contratos que creó, y empieza en 1. `rlp` es la codificación que usa Ethereum para
listas; no necesitas hacerla a mano, `cast` y forge-std la calculan. El **salt**
(*sal*) es un valor de 32 bytes que eliges tú.

## 3. Cómo se escribe

En `src/Factory.sol`, una caja fuerte mínima y su fábrica:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

contract Vault {
    address public immutable OWNER;

    constructor(address owner) {
        OWNER = owner;
    }
}

contract Factory {
    function create(address owner) external returns (Vault) {
        return new Vault(owner);
    }

    function create2(address owner, bytes32 salt) external returns (Vault) {
        return new Vault{salt: salt}(owner);
    }

    function predict(address owner, bytes32 salt) external view returns (address) {
        bytes32 initCodeHash = keccak256(bytes.concat(type(Vault).creationCode, abi.encode(owner)));
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, initCodeHash));
        return address(uint160(uint256(hash)));
    }
}
```

- `new` devuelve el contrato creado, con su tipo. Si el constructor revierte, revierte
  también la función que lo llamó (o lo atrapas con `try`, teoría 04).
- `type(Vault).creationCode` es el código de creación sin argumentos. `bytes.concat` le
  pega los argumentos.
- `predict` aplica la fórmula de `CREATE2`. Aquí `abi.encodePacked` es seguro: todos los
  valores tienen tamaño fijo (1, 20, 32 y 32 bytes).

En un test, forge-std trae las dos fórmulas:

```solidity
function test_Create() public {
    address expected = vm.computeCreateAddress(address(factory), 1);
    assertEq(address(factory.create(alice)), expected);
    assertEq(address(factory.create(alice)), vm.computeCreateAddress(address(factory), 2));
}

function test_Create2() public {
    bytes32 salt = keccak256("alice-1");
    address predicted = factory.predict(alice, salt);
    assertEq(address(factory.create2(alice, salt)), predicted);
}
```

Y en anvil, con `cast`. Con anvil recién arrancado y la clave de la cuenta 0 en `PK`:

```bash
forge create src/Factory.sol:Factory --private-key "$PK" --broadcast
F=0x5FbDB2315678afecb367f032d93F642f64180aa3
ALICE=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
cast nonce $F
cast compute-address $F --nonce 1
```

```
1
0xa16E02E87b7454126E5E10d957A927A7F5B5d2be
```

Tras `cast send $F "create(address)" $ALICE --private-key "$PK"`, la caja está en esa
dirección: `cast call 0xa16E02E87b7454126E5E10d957A927A7F5B5d2be "OWNER()(address)"`
responde la dirección de alice, y `cast nonce $F` ya dice `2`. Para `CREATE2`:

```bash
SALT=$(cast keccak "alice-1")
cast call $F "predict(address,bytes32)(address)" $ALICE $SALT
cast compute-address $F --salt $SALT --init-code $(forge inspect Vault bytecode)$(cast abi-encode "f(address)" $ALICE | cut -c3-)
```

```
0xd489ac453DE15961146162C2a7Da35f3Da9d5588
0xd489ac453DE15961146162C2a7Da35f3Da9d5588
```

La fábrica y `cast` llegan a la misma dirección sin desplegar nada. Después,
`cast send $F "create2(address,bytes32)" $ALICE $SALT --private-key "$PK"` la despliega ahí,
y `cast call 0xd489ac453DE15961146162C2a7Da35f3Da9d5588 "OWNER()(address)"` responde la
dirección de alice.

## 4. Antipatrones y riesgos

- **El mismo salt dos veces.** Con el mismo salt y el mismo código de creación, la dirección
  ya está ocupada y la creación falla:

  ```
  Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted, data: "0x"
  ```

  Sin error con nombre, y en un test se ve que **consume todo el gas** que tenía. Comprueba
  antes `predicted.code.length > 0` y revierte con tu propio error.
- **Un salt que cualquiera puede usar.** Si la fábrica es pública y el salt lo elige quien
  llama, otro puede ver tu transacción pendiente y desplegar antes con tu mismo salt
  (*front-running*): ocupa la dirección y tu transacción falla. Mezcla en el salt a quien
  llama, `keccak256(abi.encode(msg.sender, salt))`: así cada cuenta solo puede ocupar sus
  propias direcciones.
- **Fondos enviados a una predicción equivocada.** Enviar ETH a una dirección que aún no
  existe funciona: el saldo la espera. Pero si el código de creación cambia (otro dueño,
  otra versión del contrato, otro compilador), la dirección cambia, y nadie podrá
  desplegar nunca en la que recibió el ETH. Predice con el mismo código que vas a desplegar.
- **Confiar en que una dirección tiene un código concreto.** Una dirección de `CREATE2`
  dice qué código de creación se usó, no qué hace el contrato después. Compruébalo como
  cualquier otro contrato (interfaz, ERC-165).

## 5. Trucos

- `vm.computeCreateAddress(deployer, nonce)` y
  `vm.computeCreate2Address(salt, initCodeHash, deployer)` en los tests.
- `cast compute-address` sin `--nonce` usa el nonce actual de la cuenta, preguntando al
  nodo.
- Un `salt` legible: `keccak256("sede-norte")` o `bytes32(uint256(1))`.

## ✅ Checklist

- [ ] Despliego un contrato desde otro con `new` y con `new …{salt: …}`.
- [ ] Calculo la dirección de los dos con `cast compute-address` y en Solidity.
- [ ] Explico por qué el salt debería incluir a quien llama.
- [ ] Compruebo que una dirección está libre antes de usar `CREATE2`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — try/catch](04-try-catch.md) | **Teoría 05 — CREATE y CREATE2** | [Ejercicio 01 — ABI y llamadas de bajo nivel →](../2-practicas/ejercicio-01-abi-y-llamadas/README.md) |
