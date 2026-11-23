import { useEffect, useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { getContractEvents, readContract, simulateContract } from "@wagmi/core";
import {
  useChains,
  useConfig,
  useConnect,
  useConnection,
  useDisconnect,
  useReadContract,
  useReadContracts,
  useSwitchChain,
  useWaitForTransactionReceipt,
  useWatchContractEvent,
  useWriteContract,
  type Connector,
} from "wagmi";
import { BaseError, ContractFunctionRevertedError, parseEventLogs, UserRejectedRequestError, formatUnits } from "viem";
import type { Address, TransactionReceipt } from "viem";
import { loyaltyAbi, registryAbi } from "./abi.ts";

// ¿Qué? Todo lo que la página hace con la cadena y con la wallet, como hooks de React:
//   conectar, leer el registro, dar de alta y retirar, explicar los errores y seguir la
//   actividad.
// ¿Para qué? Separar la cadena de la interfaz: `App.tsx` solo pinta lo que devuelven estos
//   hooks, y los tests los prueban sin navegador.
// ¿Impacto? Es la única parte de la página que conoce la ABI: si cambia el contrato,
//   cambia aquí.

/** El estado del registro que muestra la cabecera. */
export type Status = { version: bigint; capacity: bigint; remaining: bigint; fee: bigint; paused: boolean };

/** Un recurso, tal como lo devuelve `getItem`. `status`: 0 ninguno, 1 activo, 2 retirado. */
export type Item = { id: bigint; registrant: Address; status: number; registeredAt: bigint; label: string };

/** Un alta o una baja del registro, sacada de su evento. */
export type Activity = { kind: "registered" | "retired"; id: bigint; registrant: Address; label?: string; block: bigint };

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

/** El estado de una transacción en una palabra (ejercicio 03, paso 3). */
export type TxStatus = "lista" | "firmando" | "confirmando" | "confirmada" | "fallida";
type QueryStatus = "idle" | "pending" | "success" | "error";

export function txStatus(write: QueryStatus, receipt: QueryStatus): TxStatus {
  if (write === "idle") return "lista";
  if (write === "pending") return "firmando";
  if (write === "error" || receipt === "error") return "fallida";
  return receipt === "success" ? "confirmada" : "confirmando";
}

/** Lo que `useWriteContract` acepta en `mutate`: el `request` de una simulación. */
type WriteRequest = Parameters<ReturnType<typeof useWriteContract>["mutate"]>[0];
type Simulation = () => Promise<{ request: object }>;

/** La wallet conectada, si está en la red de la página y cómo conectar, desconectar o cambiar de red. */
export function useWallet(): {
  address?: Address;
  wrongChain: boolean;
  connect: (connector: Connector) => void;
  disconnect: () => void;
  switchToApp: () => void;
} {
  // TODO: useConnection() da address, status y chainId; useChains()[0] es la red de la página.
  // TODO: wrongChain: conectada y en otra red. connect, disconnect y switchToApp llaman a `mutate`
  // TODO: de useConnect, useDisconnect y useSwitchChain.
  throw new Error("TODO: useWallet");
}

/** Versión, capacidad, plazas libres, tasa de alta y si está en pausa. */
export function useStatus(registry: Address): Status | undefined {
  // TODO: useReadContracts con allowFailure: false y las cinco lecturas (version, capacity,
  // TODO: remaining, REGISTRATION_FEE, paused); `undefined` mientras no haya datos.
  throw new Error("TODO: useStatus");
}

/** Los puntos de fidelidad de la cuenta conectada, con su símbolo: "10 RPT". */
export function usePoints(registry: Address): string | undefined {
  // TODO: useReadContract de `loyalty` en el registro; después, useReadContracts de balanceOf,
  // TODO: decimals y symbol en ese token, con `query: { enabled }` hasta tener token y cuenta.
  // TODO: Formato: `${formatUnits(raw, decimals)} ${symbol}`.trim().
  throw new Error("TODO: usePoints");
}

/** Los recursos de la cuenta conectada, con todos sus campos. */
export function useItems(registry: Address): Item[] | undefined {
  // TODO: useReadContract de idsOf(cuenta) con `enabled` hasta tener cuenta; después,
  // TODO: useReadContracts con un getItem por id, con `enabled` hasta tener los ids.
  throw new Error("TODO: useItems");
}

/** Un texto para la persona: firma cancelada, el error de Solidity o el resumen de viem. */
export function errorText(err: unknown): string {
  // TODO: como `explain` del ejercicio 02: UserRejectedRequestError da "Cancelaste la firma en la
  // TODO: wallet"; ContractFunctionRevertedError, su errorName; otro BaseError, su shortMessage;
  // TODO: otro Error, su message.
  throw new Error("TODO: errorText");
}

/**
 * Una escritura completa: `run` simula, pide la firma y espera el recibo. Al confirmarse,
 * invalida la caché para que todas las lecturas se repitan. Cada simulación lleva el
 * `chainId` de la página: así `mutate` se niega a firmar si la wallet está en otra red.
 */
// ponytail: invalida toda la caché; con muchas lecturas, invalida solo las del registro.
export function useTransaction(): {
  run: (simulate: Simulation) => void;
  status: TxStatus;
  receipt?: TransactionReceipt;
  error?: string;
} {
  // TODO: useWriteContract y useWaitForTransactionReceipt({ hash: write.data }), como useTransfer
  // TODO: del ejercicio 03. `run` borra el error anterior, llama a write.reset(), espera a `simulate`
  // TODO: y pasa su `request` a write.mutate (con `as WriteRequest`); si la simulación falla,
  // TODO: guarda el error. Con el recibo, queryClient.invalidateQueries(). `error` pasa por errorText.
  throw new Error("TODO: useTransaction");
}

/** Da de alta una etiqueta pagando la tasa que dice el contrato; `id` sale del evento. */
export function useRegister(registry: Address): { register: (label: string) => void; status: TxStatus; id?: bigint; error?: string } {
  // TODO: useConfig() y useTransaction(). `register` lee REGISTRATION_FEE con readContract y
  // TODO: simula `register` con ese `value` y `chainId: config.chains[0].id`.
  // TODO: `id`: parseEventLogs del recibo, evento ItemRegistered.
  throw new Error("TODO: useRegister");
}

/** Retira un recurso de la cuenta conectada. */
export function useRetire(registry: Address): { retire: (id: bigint) => void; status: TxStatus; error?: string } {
  // TODO: useConfig() y useTransaction(). `retire` simula `retire(id)` con el mismo `chainId`.
  throw new Error("TODO: useRetire");
}

/**
 * Altas y bajas desde `fromBlock`, de la más antigua a la más reciente. Cada evento nuevo
 * del registro vuelve a pedir la lista, también los que envía otra persona.
 */
// ponytail: repite la búsqueda entera con cada evento; con mucha actividad, añade los nuevos.
export function useActivity(registry: Address, fromBlock: bigint): Activity[] | undefined {
  // TODO: useQuery con queryKey ["activity", registry, fromBlock.toString()] y un queryFn que llama
  // TODO: a getContractEvents(config, …) y convierte cada log con toActivity. useWatchContractEvent
  // TODO: del registro, con pollingInterval 1000, invalida esa queryKey en cada tanda de eventos.
  throw new Error("TODO: useActivity");
}
