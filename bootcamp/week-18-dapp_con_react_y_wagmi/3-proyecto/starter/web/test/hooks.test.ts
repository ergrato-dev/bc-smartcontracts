import { mount, wallet } from "./render.ts";
import assert from "node:assert/strict";
import { test } from "node:test";
import { act, waitFor } from "@testing-library/react";
import { simulateContract, switchChain, waitForTransactionReceipt, writeContract } from "@wagmi/core";
import { parseEther, UserRejectedRequestError, type Address } from "viem";
import { foundry, sepolia } from "viem/chains";
import { registryAbi } from "../src/abi.ts";
import { errorText, useActivity, useItems, usePoints, useRegister, useRetire, useStatus, useWallet } from "../src/hooks.ts";

// ¿Qué? Tests de `hooks.ts`. `test.sh` despliega el protocolo en su anvil y pasa la URL y
//   la dirección del registro por variables de entorno. Cada test monta hooks con una
//   wallet `mock` y espera (`waitFor`) a que su resultado cambie. No lo modifiques.
const REGISTRY = process.env.REGISTRY as Address;
const ACCOUNT_1: Address = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8";
const ACCOUNT_2: Address = "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC";

test("useWallet: conecta, detecta la red equivocada y vuelve a la de la página", async () => {
  const { config, result, unmount } = await mount(ACCOUNT_1, () => useWallet(), false);
  try {
    assert.equal(result.current.address, undefined);
    act(() => result.current.connect(config.connectors[0]));
    await waitFor(() => assert.equal(result.current.address, ACCOUNT_1));
    assert.equal(result.current.wrongChain, false);
    await act(async () => void (await switchChain(config, { chainId: sepolia.id })));
    assert.equal(result.current.wrongChain, true);
    act(() => result.current.switchToApp());
    await waitFor(() => assert.equal(result.current.wrongChain, false));
    assert.equal(config.state.chainId, foundry.id);
    act(() => result.current.disconnect());
    await waitFor(() => assert.equal(result.current.address, undefined));
  } finally {
    unmount();
  }
});

test("useStatus: el registro recién desplegado", async () => {
  const { result, unmount } = await mount(ACCOUNT_1, () => useStatus(REGISTRY), false);
  try {
    await waitFor(() =>
      assert.deepEqual(result.current, { version: 1n, capacity: 50n, remaining: 50n, fee: parseEther("0.01"), paused: false }),
    );
  } finally {
    unmount();
  }
});

test("useRegister: da de alta, devuelve el id y refresca el estado", async () => {
  const { result, unmount } = await mount(ACCOUNT_1, () => ({ register: useRegister(REGISTRY), status: useStatus(REGISTRY) }));
  try {
    await waitFor(() => assert.equal(result.current.status?.remaining, 50n));
    assert.equal(result.current.register.status, "lista");
    act(() => result.current.register.register("Primer recurso"));
    await waitFor(() => assert.equal(result.current.register.status, "confirmada"));
    assert.equal(result.current.register.id, 1n);
    await waitFor(() => assert.equal(result.current.status?.remaining, 49n));
  } finally {
    unmount();
  }
});

test("useItems: los recursos de la cuenta conectada; ninguno sin wallet", async () => {
  const off = await mount(ACCOUNT_1, () => useItems(REGISTRY), false);
  try {
    await new Promise((resolve) => setTimeout(resolve, 300));
    assert.equal(off.result.current, undefined);
  } finally {
    off.unmount();
  }
  const { result, unmount } = await mount(ACCOUNT_1, () => useItems(REGISTRY));
  try {
    await waitFor(() => assert.equal(result.current?.length, 1));
    const [item] = result.current!;
    assert.deepEqual([item.id, item.registrant, item.status, item.label], [1n, ACCOUNT_1, 1, "Primer recurso"]);
  } finally {
    unmount();
  }
});

test("usePoints: 10 puntos por el alta", async () => {
  const { result, unmount } = await mount(ACCOUNT_1, () => usePoints(REGISTRY));
  try {
    await waitFor(() => assert.match(result.current ?? "", /^10( |$)/));
  } finally {
    unmount();
  }
});

test("errorText: firma cancelada, error de Solidity y otro error", async () => {
  assert.equal(errorText(new UserRejectedRequestError(new Error("User rejected the request."))), "Cancelaste la firma en la wallet");
  assert.equal(errorText(new Error("otra cosa")), "otra cosa");
  const { result, unmount } = await mount(ACCOUNT_1, () => useRegister(REGISTRY));
  try {
    act(() => result.current.register(""));
    await waitFor(() => assert.equal(result.current.status, "fallida"));
    assert.equal(result.current.error, "InvalidLabel");
  } finally {
    unmount();
  }
});

test("useRetire: retira el recurso y la lista lo muestra retirado", async () => {
  const { result, unmount } = await mount(ACCOUNT_1, () => ({ retire: useRetire(REGISTRY), items: useItems(REGISTRY) }));
  try {
    await waitFor(() => assert.equal(result.current.items?.[0].status, 1));
    act(() => result.current.retire.retire(1n));
    await waitFor(() => assert.equal(result.current.retire.status, "confirmada"));
    await waitFor(() => assert.equal(result.current.items?.[0].status, 2));
  } finally {
    unmount();
  }
});

test("useActivity: el alta y la baja, en orden", async () => {
  const { result, unmount } = await mount(ACCOUNT_1, () => useActivity(REGISTRY, 0n), false);
  try {
    await waitFor(() => assert.equal(result.current?.length, 2));
    assert.deepEqual(
      result.current!.map((a) => [a.kind, a.id, a.registrant, a.label]),
      [
        ["registered", 1n, ACCOUNT_1, "Primer recurso"],
        ["retired", 1n, ACCOUNT_1, undefined],
      ],
    );
    assert.ok(result.current![0].block < result.current![1].block);
  } finally {
    unmount();
  }
});

test("useActivity: ve el alta que envía otra persona", async () => {
  const { result, unmount } = await mount(ACCOUNT_1, () => useActivity(REGISTRY, 0n), false);
  try {
    await waitFor(() => assert.equal(result.current?.length, 2));
    // ¿Qué? La cuenta 2 da de alta desde otra wallet, fuera de esta página.
    const other = await wallet(ACCOUNT_2);
    const { request } = await simulateContract(other, {
      address: REGISTRY,
      abi: registryAbi,
      functionName: "register",
      args: ["Segundo recurso"],
      value: parseEther("0.01"),
    });
    await waitForTransactionReceipt(other, { hash: await writeContract(other, request) });
    await waitFor(() => assert.equal(result.current?.length, 3), { timeout: 5000 });
    assert.deepEqual([result.current![2].kind, result.current![2].id, result.current![2].label], ["registered", 2n, "Segundo recurso"]);
  } finally {
    unmount();
  }
});
