import { test } from "node:test";
import assert from "node:assert/strict";
import type { Address } from "viem";
import { createClient, ethBalance, isContract, tokenBalance, tokenInfo } from "../src/read.ts";

// ¿Qué? Tests del ejercicio 01. `test.sh` despliega el Token en su anvil y pasa la
//   dirección y la URL por variables de entorno. No lo modifiques.
const RPC_URL = process.env.RPC_URL ?? "http://127.0.0.1:8545";
const TOKEN = process.env.TOKEN as Address;
const ACCOUNT_0: Address = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
const ACCOUNT_1: Address = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8";
const ACCOUNT_9: Address = "0xa0Ee7A142d267C1f36714E4a8F75612F20a79720";

test("Paso 1: el cliente habla con anvil", async () => {
  const client = createClient(RPC_URL);
  assert.equal(await client.getChainId(), 31337);
  assert.equal(await client.getBlockNumber(), 3n);
});

test("Paso 2: saldo de ETH", async () => {
  const client = createClient(RPC_URL);
  assert.equal(await ethBalance(client, ACCOUNT_9), "10000");
});

test("Paso 3: contrato o cuenta", async () => {
  const client = createClient(RPC_URL);
  assert.equal(await isContract(client, TOKEN), true);
  assert.equal(await isContract(client, ACCOUNT_1), false);
});

test("Paso 4: datos del Token", async () => {
  const client = createClient(RPC_URL);
  assert.deepEqual(await tokenInfo(client, TOKEN), {
    name: "Bootcamp Token",
    symbol: "BCT",
    decimals: 18,
    totalSupply: 1000n * 10n ** 18n,
  });
});

test("Paso 5: saldo de tokens", async () => {
  const client = createClient(RPC_URL);
  assert.equal(await tokenBalance(client, TOKEN, ACCOUNT_0), "850");
  assert.equal(await tokenBalance(client, TOKEN, ACCOUNT_1), "100");
});
