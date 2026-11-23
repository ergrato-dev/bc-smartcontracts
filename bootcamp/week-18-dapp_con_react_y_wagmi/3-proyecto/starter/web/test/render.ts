// ¿Qué? Prepara un DOM falso (happy-dom) y monta hooks dentro de los proveedores de wagmi y
//   de TanStack Query, como hace `main.tsx` en la página. No lo modifiques.
// ¿Impacto? Este archivo se importa el primero: React necesita `window` y `document` antes
//   de montar nada.
import { GlobalRegistrator } from "@happy-dom/global-registrator";
GlobalRegistrator.register();

import { createElement, type ReactNode } from "react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { act, renderHook } from "@testing-library/react";
import { connect, createConfig, http, mock, type Config } from "@wagmi/core";
import { WagmiProvider } from "wagmi";
import type { Address } from "viem";
import { foundry, sepolia } from "viem/chains";

export const rpcUrl = process.env.RPC_URL!;

// ¿Qué? La configuración de la página con una wallet `mock` de `account` en lugar de la del
//   navegador. La primera red, anvil, es la de la página; Sepolia está para probar una
//   wallet en otra red.
// ¿Impacto? `mock` firma enviando al RPC de `rpcUrls`: por eso anvil lleva el del test.
export function testConfig(account: Address): Config {
  const anvil = { ...foundry, rpcUrls: { default: { http: [rpcUrl] } } };
  return createConfig({
    chains: [anvil, sepolia],
    connectors: [mock({ accounts: [account] })],
    transports: { [anvil.id]: http(rpcUrl), [sepolia.id]: http("http://127.0.0.1:1") },
  });
}

// ¿Qué? Una wallet ya conectada, para enviar transacciones sin React (otra persona).
export async function wallet(account: Address): Promise<Config> {
  const config = testConfig(account);
  await connect(config, { connector: config.connectors[0] });
  return config;
}

// ¿Qué? Monta `hook` con la wallet `mock` de `account` y, si se pide, la conecta después de
//   montar. Devuelve la configuración, el resultado más reciente (`result.current`) y
//   `unmount`, que hay que llamar al terminar: sin desmontar, el proceso no termina.
export async function mount<T>(account: Address, hook: () => T, connected = true) {
  const config = testConfig(account);
  const queryClient = new QueryClient();
  const wrapper = ({ children }: { children: ReactNode }) =>
    createElement(WagmiProvider, { config, reconnectOnMount: false }, createElement(QueryClientProvider, { client: queryClient }, children));
  const rendered = renderHook(hook, { wrapper });
  if (connected) await act(async () => void (await connect(config, { connector: config.connectors[0] })));
  return {
    config,
    result: rendered.result,
    unmount: () => {
      rendered.unmount();
      queryClient.clear();
    },
  };
}
