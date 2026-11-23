// ¿Qué? Los tipos de las variables de web/.env.local, para que TypeScript las conozca.
interface ImportMetaEnv {
  readonly VITE_CHAIN?: "anvil" | "sepolia";
  readonly VITE_RPC_URL?: string;
  readonly VITE_REGISTRY: `0x${string}`;
  readonly VITE_FROM_BLOCK?: string;
}
