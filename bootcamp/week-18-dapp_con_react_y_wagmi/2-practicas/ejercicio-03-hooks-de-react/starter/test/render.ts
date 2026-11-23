// ¿Qué? Prepara un DOM falso (happy-dom) y monta hooks dentro de los proveedores de wagmi y
//   de TanStack Query, como hace `main.tsx` en una página.
// ¿Impacto? Este archivo se importa el primero: React necesita `window` y `document` antes
//   de montar nada.
import { GlobalRegistrator } from "@happy-dom/global-registrator";
GlobalRegistrator.register();

import { createElement, type ReactNode } from "react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { act, renderHook } from "@testing-library/react";
import { connect, mock, type Config } from "@wagmi/core";
import { WagmiProvider } from "wagmi";
import type { Address } from "viem";
import { createAppConfig } from "../src/config.ts";

export const rpcUrl = process.env.RPC_URL!;

// ¿Qué? Una configuración con la wallet `mock` de `account`, ya conectada, para usar sin React.
export async function wallet(account: Address): Promise<Config> {
  const config = createAppConfig(rpcUrl, mock({ accounts: [account] }));
  await connect(config, { connector: config.connectors[0] });
  return config;
}

// ¿Qué? Monta `hook` con la wallet `mock` de `account` y, si se pide, conecta después de
//   montar, como cuando la persona pulsa *Conectar*. Devuelve el resultado más reciente
//   (`result.current`) y `unmount`.
// ¿Impacto? Hay que llamar a `unmount` al terminar: desmontar para las escuchas y los
//   temporizadores, y sin eso el proceso no termina.
export async function mount<T>(account: Address, hook: () => T, connected = true) {
  const config = createAppConfig(rpcUrl, mock({ accounts: [account] }));
  const queryClient = new QueryClient();
  const wrapper = ({ children }: { children: ReactNode }) =>
    createElement(WagmiProvider, { config, reconnectOnMount: false }, createElement(QueryClientProvider, { client: queryClient }, children));
  const rendered = renderHook(hook, { wrapper });
  if (connected) await act(async () => void (await connect(config, { connector: config.connectors[0] })));
  return {
    result: rendered.result,
    unmount: () => {
      rendered.unmount();
      queryClient.clear();
    },
  };
}
