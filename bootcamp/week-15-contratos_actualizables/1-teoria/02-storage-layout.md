# Teoría 02 — Storage layout

## 🎯 Objetivos

- Explicar por qué un proxy y su implementación comparten el mismo storage, slot a slot.
- Explicar dónde guarda un proxy EIP-1967 la implementación y el administrador, y por qué ahí.
- Aplicar las reglas para que una V2 sea compatible con el storage de la V1.
- Leer un layout con `forge inspect` y reconocer el storage con espacio de nombres (ERC-7201).

---

## 1. Qué problema resuelve

El **storage layout** (la disposición del storage) es qué variable ocupa cada slot. En la
semana 03 viste que el compilador asigna los slots en el orden en que declaras las variables,
desde el 0. En la semana 10, que el código ejecutado con `delegatecall` escribe en esos
números de slot sobre el storage de quien llama.

Detrás de un proxy hay dos layouts sobre **un solo storage**, el del proxy:

- El de la implementación, que escribe sus variables en los slots 0, 1, 2…
- El del propio proxy, que necesita guardar al menos la dirección de la implementación.

Y con cada actualización, un layout más: el de la V2 tiene que leer el storage que escribió
la V1. Dos fallos distintos, con la misma causa: dos códigos que no se ponen de acuerdo sobre
qué hay en cada slot.

## 2. Proxy frente a implementación

`NaiveProxy`, del ejercicio 01, guarda la implementación en su primera variable:

```solidity
contract NaiveProxy {
    address public implementation; // slot 0
    // ...
}

contract CounterV1 {
    uint256 public count; // slot 0
    // ...
}
```

`increment()` llega al proxy, se ejecuta el código de `CounterV1` con `delegatecall`, y
`count++` suma 1 al slot 0 del proxy. Ese slot era `implementation`: la dirección pasa a ser la
de `CounterV1` más 1, donde no hay código, y la siguiente llamada revierte con
`AddressEmptyCode`. El test `test_Given_NaiveProxyBreaksOnFirstWrite` lo comprueba.

### La solución de EIP-1967

**EIP-1967** fija unos slots para el proxy que ningún compilador usará nunca para una
variable: el keccak256 de un nombre, menos 1.

```bash
cast keccak "eip1967.proxy.implementation"
cast keccak "eip1967.proxy.admin"
```

```
0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbd
0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6104
```

Restando 1 salen los slots que usa OpenZeppelin (`ERC1967Utils`), terminados en `…bbc` y
`…6103`:

| Slot | Qué guarda |
| ---- | ---------- |
| `0x360894a1…382bbc` | La implementación |
| `0xb5312768…5d6103` | El administrador (en el proxy transparent, teoría 04) |

¿Por qué no basta un slot "muy alto"? Porque los mappings y los arrays dinámicos guardan sus
datos en slots calculados con keccak256 (semana 06), repartidos por todo el espacio de
2²⁵⁶ slots. Un keccak256 de un texto conocido es tan improbable de coincidir con otro como
cualquier otro hash. El "menos 1" hace que nadie conozca el texto que da ese hash: no hay
ninguna clave de mapping que caiga ahí.

Los slots fijos tienen otra ventaja: cualquiera encuentra la implementación de un proxy
EIP-1967 leyendo ese slot (`cast storage`, ejercicio 01), sin saber nada más del proxy. Así lo
hacen los exploradores de bloques.

## 3. V1 frente a V2

La V2 se ejecuta sobre el storage que dejó la V1. Para que lo lea bien, cada variable de la
V1 tiene que estar en el mismo slot y con el mismo tipo en la V2. Las reglas:

| ✅ Se puede | ❌ No se puede |
| ----------- | -------------- |
| Añadir variables **al final** | Añadir variables antes o entre las de la V1 |
| Añadir funciones, eventos y errores | Borrar una variable de la V1 |
| Cambiar el código de las funciones | Cambiar el orden de las variables de la V1 |
| Añadir constantes (no ocupan storage) | Cambiar el tipo de una variable (`uint128` por `uint256`) |
| | Cambiar el orden de la herencia, si las bases tienen variables |

![Tres columnas con el storage del mismo proxy: NotesV1 con count en el slot 0 y notes en el 1; NotesV2, compatible, repite los dos y añade authorOf en el slot 2; NotesV2Bad pone lastAuthor en el slot 0 y desplaza count y notes; abajo, los slots de EIP-1967 y ERC-7201, iguales en las tres](../0-assets/03-layout-v1-v2.svg)

La herencia también cuenta: el compilador pone primero las variables de las bases, de la más
lejana a la más cercana, y después las del contrato. `RegistryV2 is Registry` es seguro:
todas las variables de `Registry` van primero, y `maxPerAccount` detrás.

Lo que pasa si rompes una regla lo ves en el ejercicio 03 con `NotesV2Bad`, que declara
`address lastAuthor` delante de `count`:

```
-- NotesV1
0 count t_uint256
1 notes t_mapping(t_uint256,t_string_storage)
-- NotesV2Bad
0 lastAuthor t_address
1 count t_uint256
2 notes t_mapping(t_uint256,t_string_storage)
```

Tras actualizar a `NotesV2Bad`, `lastAuthor` lee el 2 de `count` como una dirección, `count`
lee el slot 1 (que en V1 era la raíz del mapping, siempre 0) y las notas se buscan en slots
vacíos. No revierte nada: el contrato sigue funcionando con datos falsos.

## 4. Storage con espacio de nombres (ERC-7201)

Con herencia y actualizaciones, el orden secuencial es frágil: si una base añade una variable
en una versión nueva, desplaza las del contrato que hereda. OpenZeppelin lo resuelve en sus
contratos upgradeable con **ERC-7201**: cada contrato guarda sus variables en un struct, en un
slot calculado a partir de un nombre (su **espacio de nombres**). Así lo declara
`OwnableUpgradeable`:

```solidity
/// @custom:storage-location erc7201:openzeppelin.storage.Ownable
struct OwnableStorage {
    address _owner;
}

// keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable")) - 1)) & ~bytes32(uint256(0xff))
bytes32 private constant OwnableStorageLocation = 0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;
```

Una función privada con unas líneas de `assembly` (semana 28) apunta el struct a ese slot.
`cast` calcula el slot de un nombre:

```bash
cast index-erc7201 openzeppelin.storage.Ownable
```

```
0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300
```

Es el número de 78 cifras que viste en `forge inspect` en el ejercicio 03 (en decimal). Por eso
`OwnableUpgradeable` no ocupa el slot 0 aunque vaya primero en la herencia: tus variables
siguen empezando en el 0, y las de OpenZeppelin están lejos, cada una en su sitio.

En tus contratos puedes seguir usando variables normales y la regla de añadir al final: es lo
que hace el proyecto. ERC-7201 interesa sobre todo cuando escribes bases que otros heredan.
En código antiguo (OpenZeppelin 4) verás otra solución: un array `uint256[50] private __gap`
al final de cada base, que reserva slots para variables futuras.

## 5. Antipatrones y riesgos

- ❌ **Actualizar sin comparar layouts.** El compilador no compara la V2 con la V1 desplegada:
  compila las dos sin quejarse. Compara `forge inspect <Contrato> storageLayout` de las dos
  versiones antes de cada actualización.
- ❌ **Insertar, borrar o reordenar variables.** Corrompe el estado sin revertir: es el peor
  fallo, porque nadie se entera hasta que los datos ya están mal.
- ❌ **"Reutilizar" una variable que ya no usas.** Si V2 no necesita una variable de V1, déjala
  donde está (puedes cambiarle el nombre a `__deprecatedX`): su slot sigue teniendo el valor
  viejo.
- ❌ **Cambiar el tipo "a uno compatible".** `uint128` y `uint256` no ocupan igual: dos
  `uint128` seguidos comparten un slot (semana 04), y un `uint256` no.

## 6. Trucos

- `forge inspect C storageLayout --json | jq -r '.storage[] | "\(.slot) \(.label)"'` da una
  línea por variable, fácil de comparar con `diff`.
- `cast storage <proxy> <slot>` lee cualquier slot de un contrato desplegado: el 0, el de la
  implementación de EIP-1967 o uno de ERC-7201.

## ✅ Checklist

- [ ] Explico por qué un proxy no puede guardar la implementación en el slot 0.
- [ ] Explico de dónde salen los slots de EIP-1967 y por qué el "menos 1".
- [ ] Sé qué cambios de variables admite una V2 y cuáles no.
- [ ] Comparo dos layouts con `forge inspect` y digo si son compatibles.
- [ ] Explico qué es ERC-7201 y por qué el dueño de `OwnableUpgradeable` no está en el slot 0.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 01 — Proxies y delegatecall](01-proxies-y-delegatecall.md) | **Teoría 02 — Storage layout** | [Teoría 03 — Initializers →](03-initializers.md) |
