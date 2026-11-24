# Teoría 01 — El protocolo completo

## 🎯 Objetivos

- Ver tu protocolo como un sistema: qué contratos hay en cada cadena, quién administra cada uno y
  cómo se llaman entre ellos.
- Distinguir el código de un despliegue de su configuración: roles, direcciones y parámetros.
- Comprobar un despliegue con tres preguntas: quién manda, que nadie más mande y que todo esté
  conectado.
- Escribir un script que comprueba un despliegue solo con lecturas y ejecutarlo contra una red.
- Reconocer los errores de despliegue que no hacen fallar nada y que se pagan después.

## Qué problema resuelve

Durante 33 semanas has escrito y probado contratos. Pero lo que usan las personas no es el código:
es un **despliegue**, el código más su **configuración**. La configuración es todo lo que se
decide al desplegar y no está en el código fuente: quién tiene cada rol, a qué dirección apunta
cada contrato, cuánto espera el timelock, qué feed de precios se lee.

Un error de configuración no hace fallar ningún test del código, porque el código está bien:

- **Nomad (agosto de 2022).** Una actualización del puente inicializó la raíz de confianza a cero.
  Con ese valor, cualquier mensaje se daba por demostrado, y en unas horas cientos de cuentas
  copiaron la primera transacción de ataque: unos 190 millones de dólares. El código hacía lo que
  decía; el valor con el que se inicializó, no.
- **La biblioteca de Parity (noviembre de 2017).** El contrato que usaban todas las multifirmas
  se desplegó sin inicializar. Alguien llamó a su función de inicialización, se hizo dueño y lo
  destruyó: unos 513 000 ETH quedaron congelados en las multifirmas que dependían de él.

En tu protocolo, el error más probable es más pequeño y más silencioso: quien desplegó sigue de
administrador en una de las dos cadenas, o el registro de la L2 lee el feed de Chainlink sin
envolver. Las altas funcionan y nadie lo nota hasta que importa.

## Cómo funciona

### El mapa del protocolo

![El protocolo en dos cadenas. En L1, el registro detrás de su proxy, con los puntos como hook y el certificado; el vault guarda los puntos y da los votos al Governor, que propone al timelock; el timelock administra el registro y es dueño del paymaster; el guardián solo pausa. En la L2, el mismo registro administrado por el ejecutor, que solo obedece al timelock de L1 a través del mensajero, y el feed del secuenciador delante del de Chainlink. Las flechas rojas marcan lo que nadie debe conservar: quien desplegó sin ningún rol](../0-assets/01-el-protocolo-completo.svg)

Un mapa así responde tres cosas por cada contrato: quién lo administra, a quién llama y quién lo
llama. Es el punto de partida del informe de auditoría (semana 26) y también de la comprobación del
despliegue: cada flecha del mapa es algo que se puede leer con una llamada `view`.

### Tres preguntas

Para comprobar un despliegue, haz tres preguntas, en este orden:

1. **¿Quién manda?** Cada rol con poder (`DEFAULT_ADMIN_ROLE`, el dueño de un `Ownable`, el
   proponente de un timelock) lo tiene la cuenta esperada. Y quien desplegó no tiene ninguno: tras
   el traspaso (semana 31), su clave no debería poder nada.
2. **¿Manda alguien más?** `hasRole(rol, cuenta)` solo responde por la cuenta que preguntas. La
   cuenta de pruebas que diste de minter en testnet no la preguntas, porque no te acuerdas de ella.
   `AccessControlEnumerable` de OpenZeppelin cuenta los miembros de cada rol con
   `getRoleMemberCount`: si hay uno y es el esperado, no hay nadie más. Con `AccessControl` normal,
   la lista sale de los eventos `RoleGranted` y `RoleRevoked` (teoría 04).
3. **¿Está todo conectado?** Cada dirección guardada en un contrato es la del contrato que toca:
   el Governor vota con **este** vault, el registro de la L2 lee **este** feed, el ejecutor
   obedece a **este** timelock. Y cada parámetro está en su rango: el plazo del timelock, la
   versión del registro.

Cada respuesta incorrecta es un `revert` con un error que la nombra: `DeployerStillAdmin`,
`UnexpectedMembers`, `WrongWiring("registry.priceFeed", ...)`. Un script que imprime "OK" o "MAL"
lo lee una persona; un script que revierte lo lee también otro script, y para un despliegue.

### Comprobar en la simulación y contra la red

`forge script` ejecuta el script dos veces (semana 16). Primero lo **simula** en local, contra el
estado de la red; si todo va bien y hay `--broadcast`, envía las transacciones. Una comprobación
al final de `run()` corre en la simulación: si falla, el script revierte y no se envía nada.

Pero entre la simulación y los bloques reales pueden pasar cosas: otra transacción entra antes que
la tuya (alguien llama a tu `initialize` primero, como en Parity), una transacción de las tuyas
falla por gas, o te equivocas de red. Por eso la comprobación es un script **aparte**, que solo
lee, y que ejecutas otra vez contra la red cuando el despliegue ha terminado, con las direcciones
de `broadcast/`.

## Cómo se escribe

El ejercicio 01 despliega una tienda que paga en puntos y la traspasa a un timelock. Mira el
despliegue entero y su comprobación en anvil.

**Dónde**: en el contenedor, en el starter del ejercicio 01 con los cinco pasos resueltos. anvil
corre en segundo plano (`anvil --silent &`), y la clave es la cuenta 0 de anvil, pública.

```bash
K=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export PROPOSER=0x70997970C51812dc3A010C7d01b50e8d4c6F2B5d
forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --private-key $K --broadcast
```

**Salida** (recortada):

```text
Script ran successfully.
== Return ==
d: struct Deploy.Deployment Deployment({ points: 0x5FbDB2315678afecb367f032d93F642f64180aa3, shop: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512, timelock: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 })
...
ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.
Transactions saved to: /workspace/broadcast/Deploy.s.sol/31337/run-latest.json
```

`run()` ya ha comprobado el resultado en la simulación. Ahora, contra la red, sin `--broadcast`:

```bash
POINTS=0x5FbDB2315678afecb367f032d93F642f64180aa3 SHOP=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 \
TIMELOCK=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 DEPLOYER=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
  forge script script/CheckDeployment.s.sol --rpc-url http://127.0.0.1:8545
```

**Salida**:

```text
Script ran successfully.
== Logs ==
  Despliegue comprobado
```

Las mismas preguntas, una a una, con `cast call` (semana 02):

```bash
cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "hasRole(bytes32,address)(bool)" \
  0x0000000000000000000000000000000000000000000000000000000000000000 \
  0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url http://127.0.0.1:8545
cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "getRoleMemberCount(bytes32)(uint256)" \
  $(cast keccak "MINTER_ROLE") --rpc-url http://127.0.0.1:8545
```

**Salida**:

```text
false
1
```

Quien desplegó ya no administra los puntos (`DEFAULT_ADMIN_ROLE` es el hash cero), y hay un solo
minter.

Ahora un despliegue a medias: solo la fase 1, sin conectar ni traspasar. `--sig` ejecuta otra
función del script en vez de `run()`:

```bash
forge script script/Deploy.s.sol --sig "deployContracts(uint256,uint256,address)" \
  10000000000000000 172800 $PROPOSER --rpc-url http://127.0.0.1:8545 --private-key $K --broadcast
```

Devuelve `points: 0xa513E6E4b8f2a923D98304ec87F64353C4D5C853`, `shop:
0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6` y `timelock: 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318`,
y `ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.`: para `forge script`, todo ha ido bien. La
comprobación con esas tres direcciones dice otra cosa:

```text
Error: script failed: NotAdmin(0xa513E6E4b8f2a923D98304ec87F64353C4D5C853, 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318)
```

El timelock no administra los puntos: quien desplegó sigue siendo el único administrador.

## Antipatrones y riesgos

- **Dar por bueno un despliegue porque no falló.** `ONCHAIN EXECUTION COMPLETE & SUCCESSFUL`
  significa que las transacciones entraron, no que el resultado sea el que querías.
- **Traspasar en el orden equivocado.** Si quien despliega renuncia a `DEFAULT_ADMIN_ROLE` antes de
  dárselo al timelock, el contrato se queda sin administrador para siempre. Primero se da, después
  se renuncia.
- **Comprobar solo lo que esperas.** `hasRole(MINTER_ROLE, tienda)` es `true` aunque haya otro
  minter. Pregunta también por quien desplegó y cuenta los miembros si puedes.
- **Copiar direcciones de otra red.** El feed ETH/USD de Sepolia no existe en OP Sepolia, y en otra
  red puede haber otro contrato en esa misma dirección. Las direcciones de dependencias externas se
  comprueban contra la documentación de cada red, a mano, y se escriben en el informe.
- **Un administrador aparte en el timelock.** `TimelockController` acepta un `admin` en su
  constructor. Si es quien despliega, se da el rol de proponer y ejecutar, y el plazo no protege
  nada. `HandOverToDao` pasa `address(0)`.
- **Una comprobación sin tests.** Si nunca la has visto fallar, no sabes si comprueba algo. Cada
  pregunta necesita un test que estropee justo eso y espere su error, y un mutante que la quite.

## Trucos

- `forge script` sin `--broadcast` simula contra la red y no firma nada: es la forma segura de
  ejecutar una comprobación, incluso contra mainnet.
- `--sig "funcion(tipos)" args` ejecuta cualquier función pública del script: así un mismo archivo
  tiene `runL1()` y `runL2()`.
- Las direcciones de cada despliegue están en `broadcast/<script>/<chain id>/run-latest.json`.
  Guárdalas en el informe junto a la salida de la comprobación.
- Ejecuta la comprobación también **después** de cada propuesta de la DAO que toque roles: es un
  despliegue nuevo de la configuración.

## ✅ Checklist

- [ ] Sé distinguir el código de un despliegue de su configuración.
- [ ] Sé dibujar el mapa de mi protocolo: quién administra, a quién llama y quién lo llama.
- [ ] Sé hacer las tres preguntas y por qué `hasRole` no basta para la segunda.
- [ ] Sé por qué la comprobación va también en un script aparte, contra la red.
- [ ] Sé ejecutar un script sin `--broadcast` y con `--sig`.
- [ ] Sé qué errores de despliegue no hacen fallar nada.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Semana 34 — Integración final y auditoría cruzada](../README.md) | **Teoría 01 — El protocolo completo** | [Teoría 02 — Auditoría cruzada →](02-auditoria-cruzada.md) |
