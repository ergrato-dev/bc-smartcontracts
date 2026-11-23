import { test } from "node:test";
import assert from "node:assert/strict";
import { createPublicClient, createWalletClient, http, parseEther, zeroAddress } from "viem";
import type { Address } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { foundry } from "viem/chains";
import { tokenAbi } from "../src/abi.ts";
import { balanceAt, history, receivedBy, transfersIn, watchTransfers } from "../src/events.ts";

// ¿Qué? Tests del ejercicio 03. `test.sh` despliega el Token en su anvil y pasa la
//   dirección y la URL por variables de entorno. No lo modifiques.
const RPC_URL = process.env.RPC_URL ?? "http://127.0.0.1:8545";
const TOKEN = process.env.TOKEN as Address;
const client = createPublicClient({ chain: foundry, transport: http(RPC_URL) });

// Cuentas de prueba de anvil: sus claves son públicas y solo valen en anvil.
const ACCOUNT_0: Address = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
const ACCOUNT_1: Address = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8";
const ACCOUNT_2: Address = "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC";
const ACCOUNT_5: Address = "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc";
const wallet = createWalletClient({
  account: privateKeyToAccount("0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"),
  chain: foundry,
  transport: http(RPC_URL),
});
async function send(to: Address, amount: bigint) {
  const hash = await wallet.writeContract({ address: TOKEN, abi: tokenAbi, functionName: "transfer", args: [to, amount] });
  return client.waitForTransactionReceipt({ hash });
}

test("Paso 1: el historial de Transfer", async () => {
  assert.deepEqual(await history(client, TOKEN), [
    { block: 1n, from: zeroAddress, to: ACCOUNT_0, value: parseEther("1000") },
    { block: 2n, from: ACCOUNT_0, to: ACCOUNT_1, value: parseEther("100") },
    { block: 3n, from: ACCOUNT_0, to: ACCOUNT_2, value: parseEther("50") },
  ]);
});

test("Paso 2: filtrar por un campo indexed", async () => {
  assert.deepEqual(await receivedBy(client, TOKEN, ACCOUNT_1), [parseEther("100")]);
  assert.deepEqual(await receivedBy(client, TOKEN, ACCOUNT_5), []);
});

test("Paso 3: el saldo en un bloque pasado", async () => {
  assert.equal(await balanceAt(client, TOKEN, ACCOUNT_1, 1n), 0n);
  assert.equal(await balanceAt(client, TOKEN, ACCOUNT_1, 2n), parseEther("100"));
});

test("Paso 4: los eventos de un recibo", async () => {
  const receipt = await send(ACCOUNT_5, parseEther("3"));
  assert.deepEqual(transfersIn(receipt), [{ from: ACCOUNT_1, to: ACCOUNT_5, value: parseEther("3") }]);
});

test("Paso 5: escuchar Transfer nuevos", async () => {
  let unwatch = () => {};
  const received = new Promise((resolve) => {
    unwatch = watchTransfers(client, TOKEN, resolve);
  });
  // `finally`: deja de escuchar aunque el test falle; si no, el proceso no termina.
  try {
    // Da tiempo a que el filtro quede creado en el nodo antes de enviar.
    await new Promise((resolve) => setTimeout(resolve, 300));
    await send(ACCOUNT_5, parseEther("2"));
    const transfer = await Promise.race([
      received,
      new Promise((_, reject) => setTimeout(() => reject(new Error("ningún Transfer en 5 s")), 5000)),
    ]);
    assert.deepEqual(transfer, { from: ACCOUNT_1, to: ACCOUNT_5, value: parseEther("2") });
  } finally {
    unwatch();
  }
});
