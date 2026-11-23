import { mount, wallet } from "./render.ts";
import assert from "node:assert/strict";
import { test } from "node:test";
import { act, waitFor } from "@testing-library/react";
import { readContract, simulateContract, waitForTransactionReceipt, writeContract } from "@wagmi/core";
import { parseEther, type Address } from "viem";
import { tokenAbi } from "../src/abi.ts";
import { txStatus, useIncomingTransfers, useMyBalance, useTokenInfo, useTransfer, type TxStatus } from "../src/hooks.ts";

// ¿Qué? `test.sh` despliega el Token: la cuenta 1 tiene 100 BCT y la 2, 50. Cada test monta
//   un hook con una wallet `mock` y espera (`waitFor`) a que su resultado cambie.
const token = process.env.TOKEN as Address;
const account1 = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8";
const account2 = "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC";
const account5 = "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc";

test("Paso 1: useTokenInfo empieza sin datos y después los trae", async () => {
  const { result, unmount } = await mount(account1, () => useTokenInfo(token), false);
  try {
    assert.equal(result.current, undefined);
    await waitFor(() => assert.deepEqual(result.current, { name: "Bootcamp Token", symbol: "BCT", decimals: 18 }));
  } finally {
    unmount();
  }
});

test("Paso 2: useMyBalance espera a la wallet y lee su saldo", async () => {
  const off = await mount(account1, () => useMyBalance(token), false);
  try {
    await new Promise((resolve) => setTimeout(resolve, 300));
    assert.equal(off.result.current, undefined);
  } finally {
    off.unmount();
  }
  const on = await mount(account2, () => useMyBalance(token));
  try {
    await waitFor(() => assert.equal(on.result.current, parseEther("50")));
  } finally {
    on.unmount();
  }
});

test("Paso 3: txStatus resume la firma y el recibo", () => {
  assert.equal(txStatus("idle", "pending"), "lista");
  assert.equal(txStatus("pending", "pending"), "firmando");
  assert.equal(txStatus("error", "pending"), "fallida");
  assert.equal(txStatus("success", "pending"), "confirmando");
  assert.equal(txStatus("success", "success"), "confirmada");
  assert.equal(txStatus("success", "error"), "fallida");
});

test("Paso 4: useTransfer pasa por cada estado y refresca el saldo", async () => {
  // ¿Qué? `seen` guarda el estado de cada render: en anvil todo pasa en milisegundos.
  const seen: TxStatus[] = [];
  const { result, unmount } = await mount(account1, () => {
    const transfer = useTransfer(token);
    if (seen.at(-1) !== transfer.status) seen.push(transfer.status);
    return { transfer, balance: useMyBalance(token) };
  });
  try {
    await waitFor(() => assert.equal(result.current.balance, parseEther("100")));
    act(() => result.current.transfer.send(account5, parseEther("10")));
    await waitFor(() => assert.equal(result.current.transfer.status, "confirmada"));
    assert.deepEqual(seen, ["lista", "firmando", "confirmando", "confirmada"]);
    await waitFor(() => assert.equal(result.current.balance, parseEther("90")));
  } finally {
    unmount();
  }
});

test("Paso 4: una transferencia sin saldo termina en fallida", async () => {
  const { result, unmount } = await mount(account2, () => useTransfer(token));
  try {
    act(() => result.current.send(account5, parseEther("1000")));
    await waitFor(() => assert.equal(result.current.status, "fallida"));
    assert.match(result.current.error?.message ?? "", /ERC20InsufficientBalance/);
  } finally {
    unmount();
  }
});

test("Paso 5: useIncomingTransfers ve llegar cada transferencia", async () => {
  const { result, unmount } = await mount(account5, () => useIncomingTransfers(token));
  try {
    // ¿Qué? La cuenta 2 envía a la 5 desde otra wallet, como haría otra persona.
    const sender = await wallet(account2);
    for (const amount of ["1", "2"]) {
      const { request } = await simulateContract(sender, { address: token, abi: tokenAbi, functionName: "transfer", args: [account5, parseEther(amount)] });
      await waitForTransactionReceipt(sender, { hash: await writeContract(sender, request) });
    }
    await waitFor(() => assert.deepEqual(result.current, [parseEther("1"), parseEther("2")]), { timeout: 5000 });
    assert.equal(await readContract(sender, { address: token, abi: tokenAbi, functionName: "balanceOf", args: [account5] }), parseEther("13"));
  } finally {
    unmount();
  }
});
