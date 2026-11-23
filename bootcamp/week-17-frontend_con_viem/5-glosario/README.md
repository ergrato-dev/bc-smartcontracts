# 📖 Glosario — Semana 17

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| **ABI legible** (*human-readable ABI*) | La ABI escrita como firmas de Solidity en texto, que `parseAbi` convierte en la ABI JSON | `"function balanceOf(address account) view returns (uint256)"` |
| **`as const`** | Marca de TypeScript que deja un valor con sus tipos literales; sin ella, viem no sabría qué devuelve cada función de una ABI generada | `export const registryAbi = [ … ] as const;` |
| **`bigint`** | Tipo de JavaScript para enteros de cualquier tamaño; se escribe con `n` al final. viem lo usa para todo `uint256` | `10n ** 18n` |
| **Cliente de cartera** (*wallet client*) | Cliente de viem con una cuenta que firma transacciones | `createWalletClient({ account, chain, transport })` |
| **Cliente público** (*public client*) | Cliente de viem que lee y simula, sin cuenta | `createPublicClient({ chain: foundry, transport: http(url) })` |
| **CORS** (*Cross-Origin Resource Sharing*) | Regla del navegador: una página solo habla con otro servidor (el nodo) si ese servidor lo permite | anvil lo permite por defecto |
| **Cuenta JSON-RPC** | Cuenta de viem de la que solo se da la dirección: firma el nodo o la wallet | `account: "0xf39F…2266"` en anvil |
| **Cuenta local** | Cuenta de viem con la clave en el programa: firma él mismo | `privateKeyToAccount("0x5de4…365a")` |
| **Lockfile** | Archivo que fija la versión y el hash de cada dependencia, también las indirectas | `pnpm-lock.yaml` con `--frozen-lockfile` |
| **Node** (Node.js) | Programa que ejecuta JavaScript fuera del navegador; desde la versión 24, también `.ts` quitando los tipos | `node leer.ts` |
| **Nodo de archivo** (*archive node*) | Nodo que guarda el estado de todos los bloques, no solo de los recientes; necesario para leer el pasado lejano | `readContract({ …, blockNumber: 1n })` |
| **pnpm** | Gestor de paquetes de Node que usa el bootcamp | `pnpm install --offline --frozen-lockfile` |
| **Promesa** (*Promise*) | Valor que llegará más tarde; `await` lo espera | `await client.getBlockNumber()` |
| **Recibo** (*receipt*) | Resultado de una transacción ya incluida en un bloque: estado, bloque, gas y logs | `receipt.status === "success"` |
| **Reorganización** (*reorg*) | Cambio de los últimos bloques de una red: los logs de esos bloques pueden desaparecer | log con `removed: true` |
| **Simulación** | Ejecutar una escritura en el nodo sin guardar nada ni pagar gas, para ver su resultado o su error | `simulateContract` |
| **Topic** | Cada una de las palabras indexadas de un log: el hash de la firma del evento y los campos `indexed` | `0xddf252ad…` es `Transfer` |
| **Transporte** (*transport*) | En viem, cómo llegan las peticiones JSON-RPC al nodo | `http("http://127.0.0.1:8545")` |
| **TypeScript** | JavaScript con tipos; `tsc` los comprueba sin ejecutar | `pnpm exec tsc` |
| **viem** | Biblioteca de TypeScript para hablar con nodos de Ethereum: leer, escribir, firmar y decodificar | `client.readContract(…)` |
| **Vite** | Servidor de desarrollo y empaquetador que entrega la página al navegador | `pnpm dev`, `pnpm build` |
| **`VITE_`** | Prefijo de las variables de entorno que Vite copia en el código de la página: siempre públicas | `VITE_REGISTRY=0xCf7E…0Fc9` |
| **XSS** (*cross-site scripting*) | Ataque que mete código en una página a través de texto pintado como HTML | etiqueta `<img src=x onerror=…>` con `innerHTML` |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | Semana 18 (próximamente) |
