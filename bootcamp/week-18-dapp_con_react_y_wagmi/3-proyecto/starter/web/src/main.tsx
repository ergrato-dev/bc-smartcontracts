import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { createConfig, http, injected, WagmiProvider } from "wagmi";
import type { Chain } from "viem";
import { foundry, sepolia } from "viem/chains";
import { App } from "./App.tsx";

// ¿Qué? La configuración de wagmi y los dos proveedores que envuelven la página.
// ¿Para qué? Cualquier componente de dentro puede usar los hooks de wagmi: todos comparten
//   la misma conexión y la misma caché de lecturas.
// ¿Impacto? La página solo acepta una red. Lee por `VITE_RPC_URL`; escribe por la wallet,
//   que usa su propio RPC. Las variables VITE_* van en el código de la página: nada secreto.
const env = import.meta.env;
const chain: Chain = env.VITE_CHAIN === "sepolia" ? sepolia : foundry;
const config = createConfig({
  chains: [chain],
  // ¿Qué? `injected` conecta con la wallet del navegador. wagmi añade además un conector
  //   por cada wallet que se anuncia en la página (EIP-6963).
  connectors: [injected()],
  transports: { [chain.id]: http(env.VITE_RPC_URL) },
});
const queryClient = new QueryClient();

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <App registry={env.VITE_REGISTRY} fromBlock={BigInt(env.VITE_FROM_BLOCK ?? "0")} />
      </QueryClientProvider>
    </WagmiProvider>
  </StrictMode>,
);
