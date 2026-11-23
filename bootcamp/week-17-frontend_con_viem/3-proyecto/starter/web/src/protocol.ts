import { BaseError, ContractFunctionRevertedError, createPublicClient, createWalletClient, formatUnits, http, parseEventLogs } from "viem";
import type { Account, Address, Chain, PublicClient, TransactionReceipt, Transport, WalletClient } from "viem";
import { loyaltyAbi, registryAbi } from "./abi.ts";

// ¿Qué? Todo lo que la página hace con la cadena: leer el estado del registro, dar de alta y
//   retirar recursos, explicar por qué falla una llamada y seguir la actividad.
// ¿Para qué? Separar la cadena de la interfaz: `main.ts` solo pinta lo que devuelve este
//   archivo, y los tests lo prueban sin navegador.
// ¿Impacto? Es la única parte de la página que conoce la ABI: si cambia el contrato,
//   cambia aquí.

// Ya resuelta: es el paso 5 del ejercicio 02. Las demás son tuyas: borra el `throw` y
// escribe la función siguiendo su `// TODO:`.

export type Wallet = WalletClient<Transport, Chain, Account>;

/** El estado del registro que muestra la cabecera. */
export type Status = { version: bigint; capacity: bigint; remaining: bigint; fee: bigint; paused: boolean };

/** Un recurso, tal como lo devuelve `getItem`. `status`: 0 ninguno, 1 activo, 2 retirado. */
export type Item = { id: bigint; registrant: Address; status: number; registeredAt: bigint; label: string };

/** Un alta o una baja del registro, sacada de su evento. */
export type Activity = {
  kind: "registered" | "retired";
  id: bigint;
  registrant: Address;
  label?: string;
  block: bigint;
};

/** Lo que `toActivity` necesita de un evento del registro, ya decodificado por viem. */
type RegistryLog = { eventName?: string; args?: unknown; blockNumber: bigint | null };

/** Convierte un evento del registro en `Activity`; `undefined` si no es un alta ni una baja. */
export function toActivity(log: RegistryLog): Activity | undefined {
  const args = log.args as { id: bigint; registrant: Address; label?: string };
  const block = log.blockNumber ?? 0n;
  if (log.eventName === "ItemRegistered") return { kind: "registered", ...args, block };
  if (log.eventName === "ItemRetired") return { kind: "retired", id: args.id, registrant: args.registrant, block };
  return undefined;
}

/**
 * Crea el cliente público y, si hay `account`, un cliente de cartera que firma con esa cuenta
 * del nodo (anvil la tiene desbloqueada). Sin `account`, la página solo lee.
 */
export function createClients(rpcUrl: string, chain: Chain, account?: Address) {
  const client: PublicClient = createPublicClient({ chain, transport: http(rpcUrl) });
  const wallet: Wallet | undefined = account
    ? createWalletClient({ account, chain, transport: http(rpcUrl) })
    : undefined;
  return { client, wallet };
}

/** Versión, capacidad, plazas libres, tasa de alta y si está en pausa. */
export async function readStatus(client: PublicClient, registry: Address): Promise<Status> {
  // TODO: cinco readContract en paralelo con Promise.all: version, capacity, remaining, REGISTRATION_FEE y paused.
  throw new Error("TODO: readStatus");
}

/** Los puntos de fidelidad de `account`, con su símbolo: "10.0 RPT". */
export async function pointsOf(client: PublicClient, registry: Address, account: Address): Promise<string> {
  // TODO: lee `loyalty()` del registro y, con esa dirección y `loyaltyAbi`, balanceOf, decimals y symbol. formatUnits y `.trim()` (con nombres vacíos, el símbolo es "").
  throw new Error("TODO: pointsOf");
}

/** Los recursos de `account`, con todos sus campos. */
export async function itemsOf(client: PublicClient, registry: Address, account: Address): Promise<Item[]> {
  // TODO: idsOf(account) y luego getItem(id) para cada id, en paralelo.
  throw new Error("TODO: itemsOf");
}

/** Da de alta `label` pagando la tasa, espera el recibo y devuelve el id del evento. */
export async function register(client: PublicClient, wallet: Wallet, registry: Address, label: string): Promise<bigint> {
  // TODO: lee REGISTRATION_FEE, simula `register` con `value: fee`, envía, espera el recibo y saca `id` del ItemRegistered con parseEventLogs.
  throw new Error("TODO: register");
}

/** Retira el recurso `id` y espera el recibo. */
export async function retire(client: PublicClient, wallet: Wallet, registry: Address, id: bigint): Promise<TransactionReceipt> {
  // TODO: simula `retire(id)`, envía y devuelve el recibo.
  throw new Error("TODO: retire");
}

/** El nombre del error de Solidity dentro de `err`, o `undefined` si no viene de un revert. */
export function errorName(err: unknown): string | undefined {
  // TODO: BaseError.walk hasta ContractFunctionRevertedError y devuelve `data?.errorName`. Ejercicio 02, paso 4.
  throw new Error("TODO: errorName");
}

/** Altas y bajas desde `fromBlock`, de la más antigua a la más reciente. */
export async function activity(client: PublicClient, registry: Address, fromBlock: bigint): Promise<Activity[]> {
  // TODO: getContractEvents sin `eventName` (todos los eventos del registro) desde `fromBlock`, pasados por toActivity y sin los `undefined`.
  throw new Error("TODO: activity");
}

/** Llama a `onActivity` con cada alta o baja nueva. Devuelve la función que deja de escuchar. */
export function watchActivity(client: PublicClient, registry: Address, onActivity: (a: Activity) => void): () => void {
  // TODO: watchContractEvent sin `eventName`, `pollingInterval: 1000`, y en onLogs cada log por toActivity.
  throw new Error("TODO: watchActivity");
}
