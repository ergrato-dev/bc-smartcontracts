import { test } from "node:test";
import assert from "node:assert/strict";
import { parseEther } from "viem";
import type { Address } from "viem";
import { foundry } from "viem/chains";
import { activity, createClients, errorName, itemsOf, pointsOf, readStatus, register, retire, watchActivity } from "../src/protocol.ts";
import type { Activity } from "../src/protocol.ts";

// ¿Qué? Tests de `protocol.ts`. `test.sh` despliega el protocolo en su anvil y pasa la URL
//   y la dirección del registro por variables de entorno. No lo modifiques.
const RPC_URL = process.env.RPC_URL ?? "http://127.0.0.1:8545";
const REGISTRY = process.env.REGISTRY as Address;
// La cuenta 1 de anvil: el nodo la tiene desbloqueada y firma por ella.
const ACCOUNT_1: Address = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8";
const { client, wallet } = createClients(RPC_URL, foundry, ACCOUNT_1);

test("createClients: sin cuenta solo lee; con cuenta, firma el nodo", () => {
  assert.equal(createClients(RPC_URL, foundry).wallet, undefined);
  assert.equal(wallet?.account.address, ACCOUNT_1);
  assert.equal(wallet?.account.type, "json-rpc");
});

test("readStatus: el registro recién desplegado", async () => {
  assert.deepEqual(await readStatus(client, REGISTRY), {
    version: 1n,
    capacity: 50n,
    remaining: 50n,
    fee: parseEther("0.01"),
    paused: false,
  });
});

test("register: da de alta y devuelve el id del evento", async () => {
  assert.equal(await register(client, wallet!, REGISTRY, "Primer recurso"), 1n);
  assert.equal((await readStatus(client, REGISTRY)).remaining, 49n);
});

test("itemsOf: los recursos de la cuenta, con sus campos", async () => {
  const [item] = await itemsOf(client, REGISTRY, ACCOUNT_1);
  assert.equal(item.id, 1n);
  assert.equal(item.registrant, ACCOUNT_1);
  assert.equal(item.status, 1);
  assert.equal(item.label, "Primer recurso");
});

test("pointsOf: 10 puntos por el alta", async () => {
  assert.match(await pointsOf(client, REGISTRY, ACCOUNT_1), /^10( |$)/);
});

test("errorName: el error de Solidity de una llamada que revierte", async () => {
  const err = await register(client, wallet!, REGISTRY, "").catch((e: unknown) => e);
  assert.equal(errorName(err), "InvalidLabel");
  assert.equal(errorName(new Error("otra cosa")), undefined);
});

test("retire: retira el recurso", async () => {
  const receipt = await retire(client, wallet!, REGISTRY, 1n);
  assert.equal(receipt.status, "success");
  const [item] = await itemsOf(client, REGISTRY, ACCOUNT_1);
  assert.equal(item.status, 2);
});

test("activity: el alta y la baja, en orden", async () => {
  const list = await activity(client, REGISTRY, 0n);
  assert.deepEqual(
    list.map((a) => [a.kind, a.id, a.registrant, a.label]),
    [
      ["registered", 1n, ACCOUNT_1, "Primer recurso"],
      ["retired", 1n, ACCOUNT_1, undefined],
    ],
  );
  assert.ok(list[0].block < list[1].block);
});

test("watchActivity: avisa de un alta nueva", async () => {
  let unwatch = () => {};
  const seen = new Promise<Activity>((resolve) => {
    unwatch = watchActivity(client, REGISTRY, resolve);
  });
  // `finally`: deja de escuchar aunque el test falle; si no, el proceso no termina.
  try {
    // Da tiempo a que el filtro quede creado en el nodo antes de enviar.
    await new Promise((resolve) => setTimeout(resolve, 300));
    await register(client, wallet!, REGISTRY, "Segundo recurso");
    const a = await Promise.race([
      seen,
      new Promise<never>((_, reject) => setTimeout(() => reject(new Error("ninguna actividad en 5 s")), 5000)),
    ]);
    assert.equal(a.kind, "registered");
    assert.equal(a.id, 2n);
    assert.equal(a.label, "Segundo recurso");
  } finally {
    unwatch();
  }
});
