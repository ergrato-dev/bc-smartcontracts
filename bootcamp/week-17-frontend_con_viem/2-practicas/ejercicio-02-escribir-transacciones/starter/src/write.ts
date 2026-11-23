import { BaseError, ContractFunctionRevertedError, createWalletClient, http } from "viem";
import type { Account, Address, Chain, Hex, PublicClient, Transport, WalletClient } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { foundry } from "viem/chains";
import { tokenAbi } from "./abi.ts";

// ¿Qué? Escrituras con viem: una cuenta que firma, simular, enviar, esperar el recibo y
//   leer por qué revierte una llamada.
// ¿Para qué? Cambiar el estado de la cadena desde TypeScript, como hacía `cast send`.
// ¿Impacto? Cada escritura es una transacción firmada que paga gas: se simula antes.
//
// Cada paso: borra la línea del `throw` y descomenta las líneas que empiezan con `//> `.

type Wallet = WalletClient<Transport, Chain, Account>;

// PASO 1: un cliente de cartera que firma con la clave `privateKey`, aquí, en este proceso.
export function createWallet(rpcUrl: string, privateKey: Hex): Wallet {
  throw new Error("TODO: Paso 1");
  //> return createWalletClient({ account: privateKeyToAccount(privateKey), chain: foundry, transport: http(rpcUrl) });
}

// PASO 2: simular `transfer(to, amount)` desde la cuenta de `wallet`, sin enviar nada.
export async function simulateTransfer(client: PublicClient, wallet: Wallet, token: Address, to: Address, amount: bigint) {
  throw new Error("TODO: Paso 2");
  //> return client.simulateContract({
  //>   account: wallet.account,
  //>   address: token,
  //>   abi: tokenAbi,
  //>   functionName: "transfer",
  //>   args: [to, amount],
  //> });
}

// PASO 3: simular, enviar y esperar a que la transacción entre en un bloque.
export async function transfer(client: PublicClient, wallet: Wallet, token: Address, to: Address, amount: bigint) {
  throw new Error("TODO: Paso 3");
  //> const { request } = await simulateTransfer(client, wallet, token, to, amount);
  //> const hash = await wallet.writeContract(request);
  //> return client.waitForTransactionReceipt({ hash });
}

// PASO 4: el error de Solidity con el que revertiría `transfer`, o `undefined` si no revierte.
export async function revertReason(client: PublicClient, wallet: Wallet, token: Address, to: Address, amount: bigint) {
  throw new Error("TODO: Paso 4");
  //> try {
  //>   await simulateTransfer(client, wallet, token, to, amount);
  //>   return undefined;
  //> } catch (err) {
  //>   if (!(err instanceof BaseError)) throw err;
  //>   const revert = err.walk((e) => e instanceof ContractFunctionRevertedError);
  //>   if (!(revert instanceof ContractFunctionRevertedError)) throw err;
  //>   return { name: revert.data?.errorName, args: revert.data?.args };
  //> }
}

// PASO 5: un cliente de cartera sin clave: firma el nodo, con su cuenta `address` desbloqueada.
export function nodeWallet(rpcUrl: string, address: Address): Wallet {
  throw new Error("TODO: Paso 5");
  //> return createWalletClient({ account: address, chain: foundry, transport: http(rpcUrl) });
}
