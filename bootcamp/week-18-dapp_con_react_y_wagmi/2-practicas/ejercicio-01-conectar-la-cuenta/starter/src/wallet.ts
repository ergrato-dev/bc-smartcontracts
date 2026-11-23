import {
  connect,
  createConfig,
  getConnection,
  http,
  switchChain,
  watchConnection,
  type Config,
  type CreateConnectorFn,
} from "@wagmi/core";
import type { Address } from "viem";
import { foundry, sepolia } from "viem/chains";

// Cada paso es una función. Borra la línea del `throw` y descomenta las líneas que empiezan
// con `//> ` (quita también el espacio que sigue a `//>`).

// PASO 1: la configuración de wagmi con dos redes (anvil y Sepolia) y un conector.
// ¿Qué? `createConfig` reúne las redes que la página acepta, cómo leer de cada una
//   (`transports`) y con qué wallets puede conectar (`connectors`).
// ¿Para qué? Todas las demás funciones de wagmi reciben esta configuración.
// ¿Impacto? El conector firma enviando las transacciones al RPC de `rpcUrls` de la red, no
//   al del transporte: por eso la red de anvil lleva aquí el `rpcUrl` del test.
export function createAppConfig(rpcUrl: string, connector: CreateConnectorFn): Config {
  throw new Error("TODO: Paso 1");
  //> const anvil = { ...foundry, rpcUrls: { default: { http: [rpcUrl] } } };
  //> return createConfig({
  //>   chains: [anvil, sepolia],
  //>   connectors: [connector],
  //>   transports: { [anvil.id]: http(rpcUrl), [sepolia.id]: http() },
  //> });
}

// PASO 2: conectar con el primer conector de la configuración.
// ¿Qué? Pide a la wallet sus cuentas y la red en la que está.
// ¿Impacto? Con una wallet real, aquí aparece su ventana y la persona puede decir que no.
export async function connectWallet(config: Config): Promise<{ accounts: readonly Address[]; chainId: number }> {
  throw new Error("TODO: Paso 2");
  //> return connect(config, { connector: config.connectors[0] });
}

// PASO 3: un texto con el estado de la conexión, para la cabecera de la página.
// ¿Qué? "Sin conectar", "<cuenta> en <red>" o "<cuenta> en una red no soportada".
// ¿Para qué? `chain` solo existe si la red de la wallet está en la configuración: si no,
//   la página no debe ofrecer escribir.
export function connectionLabel(config: Config): string {
  throw new Error("TODO: Paso 3");
  //> const { status, address, chain } = getConnection(config);
  //> if (status !== "connected") return "Sin conectar";
  //> if (!chain) return `${address} en una red no soportada`;
  //> return `${address} en ${chain.name}`;
}

// PASO 4: pedir a la wallet que cambie de red, solo si hace falta.
// ¿Para qué? Antes de escribir, la wallet debe estar en la red del contrato.
export async function ensureChain(config: Config, chainId: number): Promise<void> {
  throw new Error("TODO: Paso 4");
  //> if (getConnection(config).chainId === chainId) return;
  //> await switchChain(config, { chainId });
}

// PASO 5: avisar con la etiqueta del paso 3 cada vez que cambie la conexión.
// ¿Qué? Devuelve la función que deja de avisar.
// ¿Impacto? La persona cambia de cuenta o de red desde la wallet, no desde la página: la
//   página solo se entera escuchando.
export function followConnection(config: Config, onChange: (label: string) => void): () => void {
  throw new Error("TODO: Paso 5");
  //> return watchConnection(config, { onChange: () => onChange(connectionLabel(config)) });
}
