import { createConfig, http, type Config, type CreateConnectorFn } from "@wagmi/core";
import { foundry } from "viem/chains";

// ¿Qué? La configuración del ejercicio 01, solo con anvil. Viene resuelta.
// ¿Impacto? El conector firma enviando al RPC de `rpcUrls`: por eso lleva el `rpcUrl` del test.
export function createAppConfig(rpcUrl: string, connector: CreateConnectorFn): Config {
  const anvil = { ...foundry, rpcUrls: { default: { http: [rpcUrl] } } };
  return createConfig({ chains: [anvil], connectors: [connector], transports: { [anvil.id]: http(rpcUrl) } });
}
