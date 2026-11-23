# Teoría 04 — Verificación

## 🎯 Objetivos

- Explicar qué significa que un contrato esté **verificado** y por qué importa a quien lo usa.
- Enumerar lo que tiene que coincidir: código fuente, versión de solc, ajustes del compilador
  y argumentos del constructor.
- Reconocer en el bytecode desplegado los immutables y los metadatos de solc.
- Verificar con `forge script --verify` y con `forge verify-contract`, en Etherscan o Sourcify.
- Comprobar en local, antes de enviarlo, que el JSON de verificación recompila igual.

---

## 1. Qué problema resuelve

En la cadena solo hay bytecode (semana 03). Un explorador de bloques te enseña
`0x6080604052…` y nada más: ni el nombre de las funciones, ni qué hacen, ni quién puede
llamarlas. Para usar tu registro, alguien tendría que creerte que hace lo que dices.

**Verificar** un contrato es publicar su código fuente y demostrar que compila exactamente al
bytecode de esa dirección. Lo hace un **verificador**, un servicio que recompila tu código y lo
compara. Si coincide, el explorador muestra el código, la ABI y botones para leer y escribir
con tu wallet. Cualquiera puede leer las reglas antes de confiar su ETH, y el frontend de la
semana 17 puede tomar la ABI de ahí.

Hay tres verificadores habituales:

| Verificador | Qué es | Clave |
| ----------- | ------ | ----- |
| **Etherscan** | El explorador más usado (`sepolia.etherscan.io`) | Una clave de API gratuita, con cuenta |
| **Sourcify** | Repositorio abierto y público de contratos verificados | No |
| **Blockscout** | Explorador de código abierto | No |

## 2. Cómo funciona

Lo que envías al verificador es el **standard JSON input** de solc: el código fuente de todos
los archivos que intervienen y los ajustes (versión, optimizador, versión de la EVM,
remappings). Más los **argumentos del constructor**, que no están en el código desplegado: van
al final de la transacción que lo creó.

El verificador compila y compara con `cast code` de la dirección. Hay dos partes que no son
idénticas y que sabe tratar:

- **Los immutables.** En el compilado, su hueco va a cero; en la cadena, lleva el valor que
  escribió el constructor. En la Box, los 32 bytes desde la posición 157 son el dueño
  (ejercicio 03).
- **Los metadatos.** solc añade al final del bytecode un bloque codificado en CBOR (un formato
  binario compacto): el hash IPFS de un JSON con los ajustes y el hash de cada archivo, y la
  versión de solc. Sus dos últimos bytes dicen cuánto mide: `0033`, 51 bytes. Si el código
  coincide pero los metadatos no (cambiaste un comentario), Sourcify lo llama *partial match*;
  con todo idéntico, *exact match*.

![Envías el código fuente, la versión de solc, el optimizador, la EVM y los argumentos del constructor; el verificador recompila y compara con el código de la dirección: el código de las funciones byte a byte, los immutables aparte y los metadatos al final; si coincide, el explorador publica el código; si no, falla](../0-assets/03-verificacion.svg)

Por eso un ajuste distinto basta para fallar. La misma Box, compilada con el optimizador
encendido, mide 678 caracteres de hexadecimal en vez de 1260: otro bytecode del mismo `.sol`.
Verificas con los ajustes con los que desplegaste, y forge los toma de tu `foundry.toml`.

## 3. Cómo se escribe

### Al desplegar: `--verify`

**Dónde**: `foundry.toml`. La clave de Etherscan, como la URL, sale de `.env`:

```toml
[etherscan]
sepolia = { key = "${ETHERSCAN_API_KEY}" }
```

Y en `.env`, `ETHERSCAN_API_KEY=` con la clave que te da Etherscan al crear una cuenta (la
misma clave sirve para todas sus redes). Después, `--verify` al emitir:

```bash
forge script script/DeployProtocol.s.sol --rpc-url sepolia --account sepolia-dev --broadcast --slow --verify
```

Al terminar de emitir, forge verifica **todos** los contratos que creó el script, uno a uno,
con los argumentos de constructor que lee de las transacciones. El proxy incluido: es un
`ERC1967Proxy` de OpenZeppelin, y su código fuente va con él.

Sin cuenta en Etherscan, Sourcify: `--verify --verifier sourcify`. Si `ETHERSCAN_API_KEY` no
existe en el entorno, forge se para: `Error: environment variable `ETHERSCAN_API_KEY` not found`.
Con la línea vacía en `.env` (`ETHERSCAN_API_KEY=`) basta para Sourcify.

### Después: `forge verify-contract`

Para un contrato ya desplegado. Los argumentos del constructor se codifican con
`cast abi-encode` (semana 10):

```bash
forge verify-contract <dirección> src/Box.sol:Box --chain sepolia --verifier sourcify \
  --constructor-args $(cast abi-encode "constructor(address)" <dueño>)
```

Con una dirección en la que no hay contrato, así responde Sourcify:

```
Verifying on sourcify...
Submitting verification for [Box] 0x000000000000000000000000000000000000bEEF.
Submitted contract for verification:
	Verification Job ID: `97af7b65-e735-4023-83c7-1a22c4e4698b`
```

```bash
forge verify-check 97af7b65-e735-4023-83c7-1a22c4e4698b --chain sepolia --verifier sourcify
```

```
Error: Checking verification result failed

Context:
- Verification job failed:
Error Code: `contract_not_deployed`
Message: `Chain #11155111 does not have a contract deployed at 0x000000000000000000000000000000000000bEEF.`
```

La verificación es un trabajo en cola: `verify-contract` lo envía y `verify-check` pregunta cómo
fue (o añade `--watch` para esperar). Con `--rpc-url sepolia --guess-constructor-args`, forge
saca los argumentos de la transacción de creación por ti.

### Consultar si un contrato está verificado

Sourcify tiene una API pública. WETH, el ETH envuelto como ERC-20, en Sepolia:

```bash
curl -s https://sourcify.dev/server/v2/contract/11155111/0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14
```

```
{"matchId":"1079487","creationMatch":"exact_match","runtimeMatch":"exact_match","verifiedAt":"2024-08-08T12:27:30Z","match":"exact_match","chainId":"11155111","address":"0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14"}
```

### Comprobar el JSON antes de enviarlo

`--show-standard-json-input` imprime lo que forge enviaría, sin enviar nada. Puedes compilarlo
tú con el mismo solc y comparar con tu artefacto. Es lo que hará el verificador:

```bash
forge verify-contract <dirección> src/Registry.sol:Registry --show-standard-json-input > /tmp/input.json
(cd /tmp && ~/.svm/0.8.38/solc-0.8.38 --standard-json input.json > output.json)
[ "0x$(jq -r '.contracts["src/Registry.sol"].Registry.evm.deployedBytecode.object' /tmp/output.json)" \
  = "$(jq -r .deployedBytecode.object out/Registry.sol/Registry.json)" ] && echo IGUALES || echo DISTINTOS
```

Con las bibliotecas en `/opt/lib`, como en las semanas 11 a 15, sale `DISTINTOS`, y solc dice
por qué:

```
Source "/opt/lib/openzeppelin-contracts/contracts/access/IAccessControl.sol" not found: File outside of allowed directories.
```

forge nombra los archivos de fuera del proyecto con rutas `../opt/lib/…`, pero los remappings
siguen apuntando a `/opt/lib/…`: el JSON no se basta a sí mismo y el verificador no lo
compilaría. Por eso, desde esta semana, el proyecto llega a las bibliotecas por `lib`, un
enlace simbólico a `/opt/lib` dentro del proyecto. Con `lib/…` en los remappings, la misma
comprobación da `IGUALES`.

### Proxies

Verificar el proxy publica el código del `ERC1967Proxy`, no el de tu registro. Verifica también
la implementación (`--verify` lo hace). Etherscan detecta el slot de EIP-1967 (semana 15): en la
pestaña del contrato, *Is this a proxy?* enlaza el proxy con su implementación, y aparecen
*Read as Proxy* y *Write as Proxy* con las funciones del registro. Tras una actualización, verifica
la implementación nueva.

## 4. Antipatrones y riesgos

- ❌ **"Verificado" como sinónimo de "seguro".** Verificado solo dice que el código publicado
  es el que corre. Ese código puede tener fallos, o una puerta trasera. Hay que leerlo.
- ❌ **Interactuar con un contrato sin verificar.** No sabes qué hace. Una dApp seria no te
  pide firmar contra un contrato que no puedes leer.
- ❌ **Cambiar `foundry.toml` entre desplegar y verificar.** Otro optimizador u otra EVM dan
  otro bytecode. Verifica desde el mismo commit del despliegue (márcalo con `git tag`).
- ❌ **Verificar solo el proxy.** Quien mira tu dirección ve un `fallback` y un `delegatecall`,
  y nada de tus reglas.
- ❌ **Bibliotecas fuera del proyecto.** El JSON que no se basta a sí mismo no verifica. Con
  `lib` dentro del proyecto, sí.

## 5. Trucos

- `forge verify-contract ... --watch` espera el resultado en vez de devolverte el ID.
- Si la verificación automática falla, `--show-standard-json-input > input.json` y sube el
  archivo a mano en la web del verificador, eligiendo "Standard JSON input".
- Blockscout consulta Sourcify: lo que verificas en Sourcify aparece también en Blockscout.
- En `broadcast/.../run-latest.json` tienes la transacción de creación de cada contrato, con sus
  argumentos: lo que pide `--constructor-args` está ahí.

## ✅ Checklist

- [ ] Explico qué demuestra un contrato verificado y qué no demuestra.
- [ ] Enumero lo que tiene que coincidir para que un contrato verifique.
- [ ] Sé dónde están los immutables, los metadatos y los argumentos del constructor.
- [ ] Verifico con `--verify` al desplegar y con `forge verify-contract` después.
- [ ] Explico por qué el proyecto usa `lib` y no `/opt/lib`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 03 — Testnets y Sepolia](03-testnets-y-sepolia.md) | **Teoría 04 — Verificación** | [Ejercicio 01 — Primer script →](../2-practicas/ejercicio-01-primer-script/README.md) |
