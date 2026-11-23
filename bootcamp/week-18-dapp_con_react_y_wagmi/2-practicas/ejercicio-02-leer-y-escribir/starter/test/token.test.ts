import assert from "node:assert/strict";
import { test } from "node:test";
import { connect, mock, readContract, simulateContract, type Config } from "@wagmi/core";
import { parseEther, UserRejectedRequestError, type Address } from "viem";
import { tokenAbi } from "../src/abi.ts";
import { createAppConfig } from "../src/config.ts";
import { explain, myBalance, send, sendWithPhases, tokenInfo, type Phase } from "../src/token.ts";

// ¿Qué? `test.sh` despliega el Token: la cuenta 1 tiene 100 BCT y la 2, 50. El conector
//   `mock` hace de wallet de la cuenta que se le dé y firma pidiendo al nodo.
const rpcUrl = process.env.RPC_URL!;
const token = process.env.TOKEN as Address;
const account1 = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8";
const account2 = "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC";
const account5 = "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc";

async function connected(account: Address): Promise<Config> {
  const config = createAppConfig(rpcUrl, mock({ accounts: [account] }));
  await connect(config, { connector: config.connectors[0] });
  return config;
}

const balanceOf = (config: Config, account: Address) =>
  readContract(config, { address: token, abi: tokenAbi, functionName: "balanceOf", args: [account] });

test("Paso 1: nombre, símbolo y decimales", async () => {
  const config = createAppConfig(rpcUrl, mock({ accounts: [account1] }));
  assert.deepEqual(await tokenInfo(config, token), { name: "Bootcamp Token", symbol: "BCT", decimals: 18 });
});

test("Paso 2: el saldo de la cuenta conectada", async () => {
  const config = createAppConfig(rpcUrl, mock({ accounts: [account1] }));
  await assert.rejects(myBalance(config, token), /Conecta una wallet/);
  await connect(config, { connector: config.connectors[0] });
  assert.equal(await myBalance(config, token), parseEther("100"));
});

test("Paso 3: la wallet de la cuenta 1 envía 10 BCT a la cuenta 5", async () => {
  const config = await connected(account1);
  const receipt = await send(config, token, account5, parseEther("10"));
  assert.equal(receipt.status, "success");
  assert.equal(receipt.from, account1.toLowerCase());
  assert.equal(await balanceOf(config, account5), parseEther("10"));
});

test("Paso 4: un texto para cada error", async () => {
  assert.equal(explain(new UserRejectedRequestError(new Error("User rejected the request."))), "Cancelaste la firma en la wallet");

  const config = await connected(account2);
  const revert = await simulateContract(config, {
    address: token,
    abi: tokenAbi,
    functionName: "transfer",
    args: [account5, parseEther("1000")],
  }).catch((err: unknown) => err);
  assert.equal(explain(revert), "ERC20InsufficientBalance");

  const down = createAppConfig("http://127.0.0.1:1", mock({ accounts: [account1] }));
  const network = await balanceOf(down, account1).catch((err: unknown) => err);
  assert.equal(explain(network), "HTTP request failed.");

  assert.equal(explain(new Error("otra cosa")), "Error desconocido");
});

test("Paso 5: las fases de una transacción, en orden", async () => {
  const config = await connected(account1);
  const phases: Phase[] = [];
  const receipt = await sendWithPhases(config, token, account5, parseEther("2"), (phase) => phases.push(phase));
  assert.deepEqual(phases, ["simulando", "firmando", "confirmando", "confirmada"]);
  assert.equal(receipt.status, "success");
  assert.equal(await balanceOf(config, account5), parseEther("12"));
});
