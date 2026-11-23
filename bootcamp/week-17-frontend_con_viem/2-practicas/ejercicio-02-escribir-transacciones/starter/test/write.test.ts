import { test } from "node:test";
import assert from "node:assert/strict";
import { createPublicClient, http, parseEther } from "viem";
import type { Address } from "viem";
import { foundry } from "viem/chains";
import { tokenAbi } from "../src/abi.ts";
import { createWallet, nodeWallet, revertReason, simulateTransfer, transfer } from "../src/write.ts";

// ¿Qué? Tests del ejercicio 02. `test.sh` despliega el Token en su anvil y pasa la
//   dirección y la URL por variables de entorno. No lo modifiques.
const RPC_URL = process.env.RPC_URL ?? "http://127.0.0.1:8545";
const TOKEN = process.env.TOKEN as Address;
const client = createPublicClient({ chain: foundry, transport: http(RPC_URL) });
const balanceOf = (account: Address) =>
  client.readContract({ address: TOKEN, abi: tokenAbi, functionName: "balanceOf", args: [account] });

// Cuentas de prueba de anvil: sus claves son públicas y solo valen en anvil.
const ACCOUNT_0: Address = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
const ACCOUNT_1: Address = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8";
const KEY_1 = "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";
const ACCOUNT_2: Address = "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC";
const KEY_2 = "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a";
const ACCOUNT_5: Address = "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc";

test("Paso 1: la cartera firma con la cuenta 1", () => {
  const wallet = createWallet(RPC_URL, KEY_1);
  assert.equal(wallet.account.address, ACCOUNT_1);
  assert.equal(wallet.account.type, "local");
});

test("Paso 2: simular no envía nada", async () => {
  const wallet = createWallet(RPC_URL, KEY_1);
  const { result } = await simulateTransfer(client, wallet, TOKEN, ACCOUNT_5, parseEther("10"));
  assert.equal(result, true);
  assert.equal(await client.getTransactionCount({ address: ACCOUNT_1 }), 0);
  assert.equal(await balanceOf(ACCOUNT_5), 0n);
});

test("Paso 3: enviar y esperar el recibo", async () => {
  const wallet = createWallet(RPC_URL, KEY_1);
  const receipt = await transfer(client, wallet, TOKEN, ACCOUNT_5, parseEther("10"));
  assert.equal(receipt.status, "success");
  assert.equal(receipt.from.toLowerCase(), ACCOUNT_1.toLowerCase());
  assert.equal(await client.getTransactionCount({ address: ACCOUNT_1 }), 1);
  assert.equal(await balanceOf(ACCOUNT_5), parseEther("10"));
});

test("Paso 4: el error de Solidity, decodificado", async () => {
  const wallet = createWallet(RPC_URL, KEY_2);
  assert.deepEqual(await revertReason(client, wallet, TOKEN, ACCOUNT_5, parseEther("1000")), {
    name: "ERC20InsufficientBalance",
    args: [ACCOUNT_2, parseEther("50"), parseEther("1000")],
  });
  assert.equal(await revertReason(client, wallet, TOKEN, ACCOUNT_5, parseEther("1")), undefined);
});

test("Paso 5: firma el nodo", async () => {
  const wallet = nodeWallet(RPC_URL, ACCOUNT_0);
  assert.equal(wallet.account.type, "json-rpc");
  const before = await balanceOf(ACCOUNT_5);
  const receipt = await transfer(client, wallet, TOKEN, ACCOUNT_5, parseEther("1"));
  assert.equal(receipt.status, "success");
  assert.equal(await balanceOf(ACCOUNT_5), before + parseEther("1"));
});
