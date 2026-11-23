import {
  getConnection,
  readContract,
  readContracts,
  simulateContract,
  waitForTransactionReceipt,
  writeContract,
  type Config,
} from "@wagmi/core";
import { BaseError, ContractFunctionRevertedError, UserRejectedRequestError, type Address, type TransactionReceipt } from "viem";
import { tokenAbi } from "./abi.ts";

// Cada paso es una función. Borra la línea del `throw` y descomenta las líneas que empiezan
// con `//> ` (quita también el espacio que sigue a `//>`).

// PASO 1: nombre, símbolo y decimales del token, en una sola llamada.
// ¿Qué? `readContracts` hace varias lecturas a la vez. Con `allowFailure: false` devuelve
//   los valores tal cual y, si una falla, lanza el error.
export async function tokenInfo(config: Config, token: Address): Promise<{ name: string; symbol: string; decimals: number }> {
  throw new Error("TODO: Paso 1");
  //> const contract = { address: token, abi: tokenAbi } as const;
  //> const [name, symbol, decimals] = await readContracts(config, {
  //>   allowFailure: false,
  //>   contracts: [
  //>     { ...contract, functionName: "name" },
  //>     { ...contract, functionName: "symbol" },
  //>     { ...contract, functionName: "decimals" },
  //>   ],
  //> });
  //> return { name, symbol, decimals };
}

// PASO 2: el saldo de la cuenta conectada.
// ¿Qué? La cuenta no llega como argumento: la da la wallet.
// ¿Impacto? Sin wallet conectada no hay cuenta, y la función lo dice en lugar de leer el
//   saldo de `undefined`.
export async function myBalance(config: Config, token: Address): Promise<bigint> {
  throw new Error("TODO: Paso 2");
  //> const { address } = getConnection(config);
  //> if (!address) throw new Error("Conecta una wallet");
  //> return readContract(config, { address: token, abi: tokenAbi, functionName: "balanceOf", args: [address] });
}

// PASO 3: simular, enviar y esperar el recibo de una transferencia.
// ¿Qué? El mismo flujo que con viem, pero firma la wallet conectada: no hay `account`.
// ¿Impacto? Con `chainId`, el `request` lleva la red del contrato y `writeContract` comprueba
//   que la wallet sigue en ella. Sin `chainId`, la transacción saldría hacia la red en la que
//   esté la wallet, sea cual sea.
export async function send(config: Config, token: Address, to: Address, amount: bigint): Promise<TransactionReceipt> {
  throw new Error("TODO: Paso 3");
  //> const { request } = await simulateContract(config, { address: token, abi: tokenAbi, functionName: "transfer", args: [to, amount], chainId: config.chains[0].id });
  //> const hash = await writeContract(config, request);
  //> return waitForTransactionReceipt(config, { hash });
}

// PASO 4: un texto para la persona a partir de un error.
// ¿Qué? Tres casos: rechazó la firma en la wallet, el contrato revirtió con un custom error,
//   o algo más (el nodo no responde, por ejemplo).
// ¿Para qué? Rechazar no es un fallo: la página no debe mostrarlo como uno.
export function explain(err: unknown): string {
  throw new Error("TODO: Paso 4");
  //> if (!(err instanceof BaseError)) return "Error desconocido";
  //> if (err.walk((e) => e instanceof UserRejectedRequestError)) return "Cancelaste la firma en la wallet";
  //> const revert = err.walk((e) => e instanceof ContractFunctionRevertedError);
  //> if (revert instanceof ContractFunctionRevertedError && revert.data) return revert.data.errorName;
  //> return err.shortMessage;
}

// PASO 5: el paso 3, avisando de cada fase.
// ¿Qué? Llama a `onPhase` antes de simular, de pedir la firma y de esperar, y al tener el
//   recibo.
// ¿Para qué? Cada fase tarda (la firma, lo que la persona quiera; el bloque, segundos): la
//   página dice en cuál está para que nadie pulse dos veces.
export type Phase = "simulando" | "firmando" | "confirmando" | "confirmada";

export async function sendWithPhases(
  config: Config,
  token: Address,
  to: Address,
  amount: bigint,
  onPhase: (phase: Phase) => void,
): Promise<TransactionReceipt> {
  throw new Error("TODO: Paso 5");
  //> onPhase("simulando");
  //> const { request } = await simulateContract(config, { address: token, abi: tokenAbi, functionName: "transfer", args: [to, amount], chainId: config.chains[0].id });
  //> onPhase("firmando");
  //> const hash = await writeContract(config, request);
  //> onPhase("confirmando");
  //> const receipt = await waitForTransactionReceipt(config, { hash });
  //> onPhase("confirmada");
  //> return receipt;
}
