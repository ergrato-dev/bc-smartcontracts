# Teoría 03 — Testnets y Sepolia

## 🎯 Objetivos

- Explicar qué es una testnet y en qué se parece y se diferencia de anvil y de mainnet.
- Conectarte a Sepolia con un proveedor RPC sin dejar la URL en el repo (`[rpc_endpoints]` y
  `.env`).
- Conseguir ETH de Sepolia y comprobar tu saldo.
- Simular un despliegue contra Sepolia antes de emitirlo, y leer su estimación.
- Saber qué cambia al emitir en una red pública: tiempo de bloque, confirmaciones y gas.

---

## 1. Qué problema resuelve

anvil es una cadena en tu máquina: solo la ves tú, mina al instante y desaparece al cerrarla.
Para que otros usen tu protocolo (el frontend de la semana 17, el indexador de la 19, otro
aprendiz que lo audita en la 34) los contratos tienen que estar en una red pública. Pero en
**mainnet**, la red principal de Ethereum, el ETH vale dinero de verdad y cada error cuesta.

Una **testnet** es una red pública de Ethereum en la que el ETH no vale nada. Funciona como
mainnet: nodos repartidos por el mundo, bloques cada 12 segundos, exploradores de bloques y las
mismas reglas de la EVM. El ETH de testnet se regala en los **faucets** (grifos): webs que te
envían un poco a tu dirección.

**Sepolia** es la testnet que ethereum.org recomienda para desplegar aplicaciones. Su
**chain id** es `11155111`. El chain id va dentro de cada transacción firmada (EIP-155), así
que una transacción de Sepolia no se puede reenviar en mainnet: es la protección contra la
repetición entre redes que viste con EIP-712 en la semana 14.

## 2. Cómo funciona

| | anvil | Sepolia | Mainnet |
| --- | --- | --- | --- |
| Quién la ve | Solo tú | Todo el mundo | Todo el mundo |
| Bloques | Al instante | Cada 12 s | Cada 12 s |
| ETH | 10.000 por cuenta, gratis | De un faucet, sin valor | Dinero real |
| Cuentas | Las 10 de anvil, públicas | La tuya, en un keystore | La tuya, en una wallet de hardware |
| Reglas de gas | Las de la versión de anvil | Las de la red, que se actualiza | Las de la red |

Para hablar con una red necesitas un **nodo** que te atienda por JSON-RPC (semana 02). No tienes
que montarlo: un **proveedor RPC** te da una URL. Los hay públicos, sin registro y con límites
de peticiones (`https://ethereum-sepolia-rpc.publicnode.com`), y con cuenta gratuita (Alchemy,
Infura...), cuya URL lleva tu clave de API: esa URL es un secreto pequeño, no va al repo.

**Las reglas de gas de una red pública cambian** con cada actualización de la red (un *hard
fork*), y anvil simula las de su propia versión. Hoy, 23 de noviembre de 2026, la misma
transferencia de ETH y el mismo despliegue de la Box del ejercicio 01:

| Estimación | anvil (Foundry 1.9) | Sepolia |
| ---------- | ------------------- | ------- |
| Transferencia de 1 wei | 21000 | 12000 |
| Desplegar la Box | 216383 | 1307043 |

Crear contratos en Sepolia cuesta ya varias veces más gas que en anvil. La estimación que vale
es la de la red a la que vas a enviar: por eso `forge script` se la pide al nodo (teoría 01).

## 3. Cómo se escribe

### La URL, fuera del repo

**Dónde**: `foundry.toml`, al final. Un **alias** por red:

```toml
[rpc_endpoints]
anvil = "http://127.0.0.1:8545"
sepolia = "${SEPOLIA_RPC_URL}"
```

`${SEPOLIA_RPC_URL}` se sustituye por la variable de entorno. Foundry lee al arrancar el
archivo `.env` de la carpeta del proyecto. **Dónde**: `.env`, que git ignora:

```bash
SEPOLIA_RPC_URL=https://ethereum-sepolia-rpc.publicnode.com
```

Desde entonces, en `forge` y `cast`, `--rpc-url sepolia` vale por la URL:

```bash
cast chain-id --rpc-url sepolia
cast block-number --rpc-url sepolia
cast gas-price --rpc-url sepolia
```

```
11155111
12193887
21
```

El número de bloque, el tuyo. El precio del gas, en wei: 21 wei, casi nada, porque Sepolia
tiene poco tráfico. En mainnet suele ir de décimas a decenas de gwei (1 gwei = 10⁹ wei).

### ETH de Sepolia

Tu cuenta `sepolia-dev` (teoría 02) empieza a cero:

```bash
cast balance $(cast wallet address --account sepolia-dev) --ether --rpc-url sepolia
```

Pide ETH en un faucet: busca "Sepolia faucet" en la web de tu proveedor RPC o en
[ethereum.org](https://ethereum.org/developers/docs/networks/#sepolia). Muchos piden algo para
frenar a los bots: iniciar sesión, tener un poco de ETH en mainnet o hacer trabajo en el
navegador durante unos minutos (*proof of work faucet*). Si ninguno te funciona, **pídelo al
instructor**. Con 0,05 ETH de Sepolia tienes de sobra para el proyecto.

### Simular antes de emitir

El mismo script, contra Sepolia y **sin `--broadcast`**:

```bash
forge script script/DeployProtocol.s.sol --rpc-url sepolia --account sepolia-dev
```

Con una cuenta de Sepolia cualquiera (aquí se simuló con `--sender`, que no firma nada):

```
Chain 11155111

Estimated max fee per gas: 0.000000036 gwei
Estimated base fee per gas: 0.000000017 gwei
Estimated max priority fee per gas: 0.000000002 gwei

Estimated total gas used for script: 87276485

Estimated amount required: 0.00000000314195346 ETH

SIMULATION COMPLETE. To broadcast these transactions, add --broadcast and wallet configuration(s) to the previous command. See forge script --help for more.
```

El mismo despliegue estimaba 12567383 de gas en anvil. Lo que manda es esta cifra. Y
`Estimated amount required` te dice si tu saldo alcanza.

### Emitir

```bash
forge script script/DeployProtocol.s.sol --rpc-url sepolia --account sepolia-dev --broadcast --slow
```

Ahora sí se envía. Diferencias con anvil:

- **Tarda**: cada transacción espera a entrar en un bloque, unos 12 segundos, y `--slow` espera
  cada recibo antes de la siguiente. Cinco transacciones, alrededor de un minuto.
- **Es para siempre**: no hay `kill %1`. Lo desplegado se queda en Sepolia.
- **El registro va a otra carpeta**: `broadcast/DeployProtocol.s.sol/11155111/run-latest.json`.
  Ese sí se versiona: es la lista de tus direcciones en Sepolia (el `.gitignore` del proyecto
  ignora solo las de `31337` y las simulaciones).

Cada transacción se ve en el **explorador de bloques**, una web que muestra el contenido de la
cadena: `https://sepolia.etherscan.io/tx/<hash>` o `https://sepolia.etherscan.io/address/<dirección>`.
Ahí verás el bytecode de tus contratos, pero no su código fuente: eso es la teoría 04.

## 4. Antipatrones y riesgos

- ❌ **Emitir sin haber simulado contra la red de verdad.** Que funcione en anvil no dice cuánto
  gas pide Sepolia ni si tu saldo alcanza.
- ❌ **La URL con clave de API en `foundry.toml`.** Va en `.env`; en `foundry.toml`, la
  variable. Y `cache/` guarda la URL de cada `forge script`: tampoco se sube.
- ❌ **Fiarte del resultado de una sola petición a un RPC público.** Puede ir retrasado unos
  bloques o cortar por límite de peticiones. Si algo no cuadra, repite o prueba otro
  proveedor.
- ❌ **Leer un recibo y darlo por definitivo.** Un bloque recién minado todavía puede
  reorganizarse (*reorg*), y la transacción vuelve a estar pendiente. La semana 19 lo trata a
  fondo; por ahora, espera unos bloques antes de usar una dirección en otro sitio.
- ❌ **Pensar que testnet cuesta lo mismo que mainnet.** El gas usado es parecido; el precio
  del gas, no. Una estimación en Sepolia no es un presupuesto para mainnet.
- ❌ **Mandar ETH de testnet a una cuenta de anvil.** Ya viste en la teoría 02 dónde acaba.

## 5. Trucos

- `cast chain-id --rpc-url sepolia` antes de emitir: confirma a qué red vas.
- `--chain sepolia` sirve para comandos que no necesitan RPC pero sí saber la red (verificar,
  teoría 04).
- `cast receipt <hash> --rpc-url sepolia` te da el recibo de una transacción, como en anvil.
- Tu cuenta `sepolia-dev` tiene la misma dirección en todas las redes. Si despliegas desde ella
  con el mismo nonce en otra red, tus contratos tienen las mismas direcciones (semana 33).

## ✅ Checklist

- [ ] Explico qué tiene una testnet de mainnet y qué de anvil.
- [ ] Tengo `[rpc_endpoints]` en `foundry.toml` y la URL en un `.env` que git ignora.
- [ ] `cast chain-id --rpc-url sepolia` da `11155111` y mi cuenta tiene ETH de Sepolia.
- [ ] Simulo contra Sepolia antes de emitir y sé leer la estimación.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 02 — Claves y keystores](02-claves-y-keystores.md) | **Teoría 03 — Testnets y Sepolia** | [Teoría 04 — Verificación →](04-verificacion.md) |
