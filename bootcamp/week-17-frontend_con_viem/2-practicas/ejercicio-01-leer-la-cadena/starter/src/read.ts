import { createPublicClient, formatEther, formatUnits, http } from "viem";
import type { Address, PublicClient } from "viem";
import { foundry } from "viem/chains";
import { tokenAbi } from "./abi.ts";

// ¿Qué? Lecturas de la cadena con viem: bloque, saldo en ETH, código y datos del Token.
// ¿Para qué? Todo lo que una página muestra antes de que nadie firme nada.
// ¿Impacto? Leer no gasta gas ni necesita cuenta: es una pregunta al nodo (`eth_call`).
//
// Cada paso: borra la línea del `throw` y descomenta las líneas que empiezan con `//> `.

// PASO 1: un cliente público para el nodo de `rpcUrl`.
export function createClient(rpcUrl: string): PublicClient {
  throw new Error("TODO: Paso 1");
  //> return createPublicClient({ chain: foundry, transport: http(rpcUrl) });
}

// PASO 2: el saldo de ETH de `account`, en ETH y como texto.
export async function ethBalance(client: PublicClient, account: Address): Promise<string> {
  throw new Error("TODO: Paso 2");
  //> const wei = await client.getBalance({ address: account });
  //> return formatEther(wei);
}

// PASO 3: si en `address` hay un contrato (código) o una cuenta normal.
export async function isContract(client: PublicClient, address: Address): Promise<boolean> {
  throw new Error("TODO: Paso 3");
  //> const code = await client.getCode({ address });
  //> return code !== undefined;
}

// PASO 4: nombre, símbolo, decimales y emisión total del Token, en paralelo.
export async function tokenInfo(client: PublicClient, token: Address) {
  throw new Error("TODO: Paso 4");
  //> const [name, symbol, decimals, totalSupply] = await Promise.all([
  //>   client.readContract({ address: token, abi: tokenAbi, functionName: "name" }),
  //>   client.readContract({ address: token, abi: tokenAbi, functionName: "symbol" }),
  //>   client.readContract({ address: token, abi: tokenAbi, functionName: "decimals" }),
  //>   client.readContract({ address: token, abi: tokenAbi, functionName: "totalSupply" }),
  //> ]);
  //> return { name, symbol, decimals, totalSupply };
}

// PASO 5: el saldo de tokens de `account`, con los decimales del Token y como texto.
export async function tokenBalance(client: PublicClient, token: Address, account: Address): Promise<string> {
  throw new Error("TODO: Paso 5");
  //> const [raw, decimals] = await Promise.all([
  //>   client.readContract({ address: token, abi: tokenAbi, functionName: "balanceOf", args: [account] }),
  //>   client.readContract({ address: token, abi: tokenAbi, functionName: "decimals" }),
  //> ]);
  //> return formatUnits(raw, decimals);
}
