import { parseEventLogs } from "viem";
import type { Address, PublicClient, TransactionReceipt } from "viem";
import { tokenAbi } from "./abi.ts";

// ¿Qué? Eventos con viem: el historial de `Transfer`, filtrado por un campo `indexed`,
//   leído de un recibo y escuchado mientras llegan; y el estado de un bloque pasado.
// ¿Para qué? Una página muestra qué pasó, no solo cómo está ahora, y se actualiza sola.
// ¿Impacto? Los eventos viven en los recibos, no en el storage: ningún contrato puede leerlos.
//
// Cada paso: borra la línea del `throw` y descomenta las líneas que empiezan con `//> `.

// PASO 1: todos los `Transfer` del Token desde el bloque 0, con su bloque y sus argumentos.
export async function history(client: PublicClient, token: Address) {
  throw new Error("TODO: Paso 1");
  //> const logs = await client.getContractEvents({
  //>   address: token,
  //>   abi: tokenAbi,
  //>   eventName: "Transfer",
  //>   fromBlock: 0n,
  //> });
  //> return logs.map((log) => ({ block: log.blockNumber, ...log.args }));
}

// PASO 2: solo los `Transfer` que recibió `account`: el nodo filtra por el campo `to`.
export async function receivedBy(client: PublicClient, token: Address, account: Address) {
  throw new Error("TODO: Paso 2");
  //> const logs = await client.getContractEvents({
  //>   address: token,
  //>   abi: tokenAbi,
  //>   eventName: "Transfer",
  //>   args: { to: account },
  //>   fromBlock: 0n,
  //> });
  //> return logs.map((log) => log.args.value);
}

// PASO 3: el saldo de `account` tal como estaba al final del bloque `blockNumber`.
export async function balanceAt(client: PublicClient, token: Address, account: Address, blockNumber: bigint) {
  throw new Error("TODO: Paso 3");
  //> return client.readContract({
  //>   address: token,
  //>   abi: tokenAbi,
  //>   functionName: "balanceOf",
  //>   args: [account],
  //>   blockNumber,
  //> });
}

// PASO 4: los `Transfer` que emitió una transacción, sacados de su recibo.
export function transfersIn(receipt: TransactionReceipt) {
  throw new Error("TODO: Paso 4");
  //> const logs = parseEventLogs({ abi: tokenAbi, eventName: "Transfer", logs: receipt.logs });
  //> return logs.map((log) => log.args);
}

// PASO 5: llamar a `onTransfer` con cada `Transfer` nuevo. Devuelve la función que deja de escuchar.
export function watchTransfers(
  client: PublicClient,
  token: Address,
  onTransfer: (transfer: { from?: Address; to?: Address; value?: bigint }) => void,
): () => void {
  throw new Error("TODO: Paso 5");
  //> return client.watchContractEvent({
  //>   address: token,
  //>   abi: tokenAbi,
  //>   eventName: "Transfer",
  //>   pollingInterval: 100,
  //>   onLogs: (logs) => logs.forEach((log) => onTransfer(log.args)),
  //> });
}
