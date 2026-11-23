import { useEffect, useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { simulateContract } from "@wagmi/core";
import { useConfig, useConnection, useReadContract, useReadContracts, useWaitForTransactionReceipt, useWatchContractEvent, useWriteContract } from "wagmi";
import type { Address } from "viem";
import { tokenAbi } from "./abi.ts";

// Cada paso es una función. Borra la línea del `throw` y descomenta las líneas que empiezan
// con `//> ` (quita también el espacio que sigue a `//>`).
// Las funciones que empiezan por `use` son hooks: solo se llaman desde un componente de
// React (o desde otro hook), y React las vuelve a ejecutar cada vez que cambia su estado.

// PASO 1: nombre, símbolo y decimales del token.
// ¿Qué? `useReadContracts` lanza las tres lecturas y guarda el resultado en la caché.
// ¿Impacto? En el primer render todavía no hay datos: el hook devuelve `undefined` y la
//   página pinta "Cargando…". Cuando llegan, React vuelve a ejecutar el componente.
export function useTokenInfo(token: Address): { name: string; symbol: string; decimals: number } | undefined {
  throw new Error("TODO: Paso 1");
  //> const contract = { address: token, abi: tokenAbi } as const;
  //> const { data } = useReadContracts({
  //>   allowFailure: false,
  //>   contracts: [
  //>     { ...contract, functionName: "name" },
  //>     { ...contract, functionName: "symbol" },
  //>     { ...contract, functionName: "decimals" },
  //>   ],
  //> });
  //> return data && { name: data[0], symbol: data[1], decimals: data[2] };
}

// PASO 2: el saldo de la cuenta conectada.
// ¿Qué? `enabled: false` deja la lectura en espera mientras no haya cuenta.
// ¿Impacto? Sin `enabled`, wagmi pediría `balanceOf(undefined)` y el nodo devolvería un error.
export function useMyBalance(token: Address): bigint | undefined {
  throw new Error("TODO: Paso 2");
  //> const { address } = useConnection();
  //> const { data } = useReadContract({
  //>   address: token,
  //>   abi: tokenAbi,
  //>   functionName: "balanceOf",
  //>   args: address && [address],
  //>   query: { enabled: address !== undefined },
  //> });
  //> return data;
}

// PASO 3: el estado de una transferencia en una palabra, a partir de dos estados de wagmi.
// ¿Qué? `write` es el estado de la firma y el envío (`useWriteContract`); `receipt`, el de la
//   espera del recibo (`useWaitForTransactionReceipt`).
// ¿Para qué? La página pinta un texto y activa o desactiva el botón según esta palabra.
export type TxStatus = "lista" | "firmando" | "confirmando" | "confirmada" | "fallida";
type Status = "idle" | "pending" | "success" | "error";

export function txStatus(write: Status, receipt: Status): TxStatus {
  throw new Error("TODO: Paso 3");
  //> if (write === "idle") return "lista";
  //> if (write === "pending") return "firmando";
  //> if (write === "error" || receipt === "error") return "fallida";
  //> return receipt === "success" ? "confirmada" : "confirmando";
}

// PASO 4: enviar tokens desde un componente, con su estado, y refrescar los saldos al
//   confirmarse.
// ¿Qué? `send` simula y, si la simulación pasa, `mutate` pide la firma a la wallet. `data`
//   es el hash de la transacción y, en cuanto existe, `useWaitForTransactionReceipt` espera
//   su recibo.
// ¿Impacto? Sin simular, un revert llega del nodo como `custom error 0xe450d38c`, sin
//   nombre: solo la simulación lo decodifica con la ABI. Y las lecturas están en caché: sin
//   `invalidateQueries`, el saldo seguiría mostrando el valor de antes.
// ponytail: invalida toda la caché; con muchas lecturas, invalida solo las del token.
export function useTransfer(token: Address): { send: (to: Address, amount: bigint) => void; status: TxStatus; error: Error | null } {
  throw new Error("TODO: Paso 4");
  //> const config = useConfig();
  //> const queryClient = useQueryClient();
  //> const [simulateError, setSimulateError] = useState<Error | null>(null);
  //> const write = useWriteContract();
  //> const receipt = useWaitForTransactionReceipt({ hash: write.data });
  //> useEffect(() => {
  //>   if (receipt.isSuccess) queryClient.invalidateQueries();
  //> }, [receipt.isSuccess, queryClient]);
  //> function send(to: Address, amount: bigint) {
  //>   setSimulateError(null);
  //>   simulateContract(config, { address: token, abi: tokenAbi, functionName: "transfer", args: [to, amount], chainId: config.chains[0].id }).then(
  //>     ({ request }) => write.mutate(request),
  //>     setSimulateError,
  //>   );
  //> }
  //> const error = simulateError ?? write.error ?? receipt.error;
  //> return { send, status: error ? "fallida" : txStatus(write.status, receipt.status), error };
}

// PASO 5: los importes que recibe la cuenta conectada, en vivo.
// ¿Qué? `useWatchContractEvent` escucha mientras el componente está en pantalla y deja de
//   escuchar solo al quitarlo: no hay `unwatch` que llamar.
// ¿Impacto? `setReceived` con una función recibe la lista más reciente: con
//   `[...received, ...]` se perderían eventos que llegan en la misma tanda.
export function useIncomingTransfers(token: Address): bigint[] {
  throw new Error("TODO: Paso 5");
  //> const { address } = useConnection();
  //> const [received, setReceived] = useState<bigint[]>([]);
  //> useWatchContractEvent({
  //>   address: token,
  //>   abi: tokenAbi,
  //>   eventName: "Transfer",
  //>   args: { to: address },
  //>   enabled: address !== undefined,
  //>   pollingInterval: 100,
  //>   onLogs: (logs) => setReceived((list) => [...list, ...logs.map((log) => log.args.value ?? 0n)]),
  //> });
  //> return received;
}
