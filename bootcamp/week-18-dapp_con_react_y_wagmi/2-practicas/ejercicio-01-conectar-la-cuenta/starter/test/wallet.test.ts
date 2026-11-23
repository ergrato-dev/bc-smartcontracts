import assert from "node:assert/strict";
import { test } from "node:test";
import { connect, disconnect, getConnection, mock } from "@wagmi/core";
import { foundry, sepolia } from "viem/chains";
import { connectWallet, connectionLabel, createAppConfig, ensureChain, followConnection } from "../src/wallet.ts";

// ¿Qué? El conector `mock` hace de wallet: dice tener la cuenta 1 de anvil y firma pidiendo
//   al nodo, sin ventana ni clave. Cada test crea su propia configuración.
const rpcUrl = process.env.RPC_URL!;
const account1 = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8";
const fresh = () => createAppConfig(rpcUrl, mock({ accounts: [account1] }));

test("Paso 1: la configuración tiene anvil, Sepolia y un conector", () => {
  const config = fresh();
  assert.deepEqual(config.chains.map((chain) => chain.id), [foundry.id, sepolia.id]);
  assert.equal(config.chains[0].rpcUrls.default.http[0], rpcUrl);
  assert.equal(config.connectors.length, 1);
  assert.equal(config.connectors[0].type, "mock");
  assert.equal(getConnection(config).status, "disconnected");
});

test("Paso 2: conectar devuelve la cuenta y la red", async () => {
  const config = fresh();
  const { accounts, chainId } = await connectWallet(config);
  assert.deepEqual(accounts, [account1]);
  assert.equal(chainId, foundry.id);
  assert.equal(getConnection(config).status, "connected");
  assert.equal(getConnection(config).address, account1);
});

test("Paso 3: la etiqueta de la conexión", async () => {
  const config = fresh();
  assert.equal(connectionLabel(config), "Sin conectar");
  await connect(config, { connector: config.connectors[0] });
  assert.equal(connectionLabel(config), `${account1} en Foundry`);
});

test("Paso 4: la wallet cambia de red solo si hace falta", async () => {
  const config = fresh();
  await connect(config, { connector: config.connectors[0] });
  await ensureChain(config, sepolia.id);
  assert.equal(getConnection(config).chainId, sepolia.id);
  await ensureChain(config, sepolia.id);
  assert.equal(getConnection(config).chainId, sepolia.id);
  await ensureChain(config, foundry.id);
  assert.equal(getConnection(config).chainId, foundry.id);
});

test("Paso 5: la página se entera de cada cambio", async () => {
  const config = fresh();
  const labels: string[] = [];
  const unwatch = followConnection(config, (label) => labels.push(label));
  try {
    await connect(config, { connector: config.connectors[0] });
    await disconnect(config);
    assert.ok(labels.includes(`${account1} en Foundry`), `recibido: ${JSON.stringify(labels)}`);
    assert.equal(labels.at(-1), "Sin conectar");
  } finally {
    unwatch();
  }
});
