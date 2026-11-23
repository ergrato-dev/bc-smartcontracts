import { formatEther, isAddress } from "viem";
import type { Address } from "viem";
import { foundry, sepolia } from "viem/chains";
import {
  activity,
  createClients,
  errorName,
  itemsOf,
  pointsOf,
  readStatus,
  register,
  retire,
  watchActivity,
} from "./protocol.ts";
import type { Activity } from "./protocol.ts";

// ¿Qué? La página: pinta lo que devuelve protocol.ts y llama a sus funciones desde los botones.
// ¿Para qué? Ver el registro, dar de alta, retirar y seguir la actividad sin `cast`.
// ¿Impacto? Las etiquetas vienen de la cadena y las escribe cualquiera: se pintan siempre con
//   `textContent`, nunca con `innerHTML`, o una etiqueta con <script> ejecutaría código aquí.
//
// La configuración llega de web/.env.local (variables VITE_*). Vite las copia en el código
// de la página: todo lo que pongas ahí lo puede leer cualquiera que la abra.
const env = import.meta.env;
const chain = env.VITE_CHAIN === "sepolia" ? sepolia : foundry;
const rpcUrl: string = env.VITE_RPC_URL ?? "http://127.0.0.1:8545";
const registry = env.VITE_REGISTRY as Address;
const account = isAddress(env.VITE_ACCOUNT ?? "") ? (env.VITE_ACCOUNT as Address) : undefined;
const fromBlock = BigInt(env.VITE_FROM_BLOCK ?? "0");

const { client, wallet } = createClients(rpcUrl, chain, account);
const STATUS = ["Ninguno", "Activo", "Retirado"];

/** Crea un elemento con texto; el texto nunca se interpreta como HTML. */
function el<K extends keyof HTMLElementTagNameMap>(tag: K, text = "", ...children: Node[]) {
  const node = document.createElement(tag);
  node.textContent = text;
  node.append(...children);
  return node;
}

const app = document.querySelector<HTMLElement>("#app")!;
const statusBox = el("section");
const itemsBox = el("section");
const activityList = el("ol");
const message = el("p");
const labelInput = el("input");
labelInput.placeholder = "Etiqueta del recurso";
const registerButton = el("button", "Dar de alta");

app.append(
  el("h1", "Registro"),
  el("p", `Red: ${chain.name} · Registro: ${registry}`),
  statusBox,
  ...(wallet ? [el("h2", "Alta"), el("form", "", labelInput, registerButton), message] : [el("p", "Sin VITE_ACCOUNT: solo lectura.")]),
  itemsBox,
  el("h2", "Actividad"),
  activityList,
);

/** Muestra el resultado de una escritura: el error de Solidity si revirtió. */
function report(err: unknown) {
  message.textContent = `❌ ${errorName(err) ?? (err instanceof Error ? err.message : String(err))}`;
}

async function refresh() {
  const s = await readStatus(client, registry);
  statusBox.replaceChildren(
    el("h2", "Estado"),
    el("p", `Versión ${s.version} · ${s.remaining} plazas libres de ${s.capacity} · Tasa ${formatEther(s.fee)} ETH${s.paused ? " · EN PAUSA" : ""}`),
  );
  if (!account) return;
  const items = await itemsOf(client, registry, account);
  const rows = items.map((item) => {
    const row = el("li", `#${item.id} ${item.label} — ${STATUS[item.status]} `);
    if (item.status === 1 && wallet) {
      const button = el("button", "Retirar");
      button.onclick = () => retire(client, wallet, registry, item.id).then(refresh, report);
      row.append(button);
    }
    return row;
  });
  itemsBox.replaceChildren(el("h2", `Tus recursos · ${await pointsOf(client, registry, account)}`), el("ul", "", ...rows));
}

function show(a: Activity) {
  const text = a.kind === "registered" ? `alta #${a.id} «${a.label}»` : `baja #${a.id}`;
  activityList.prepend(el("li", `Bloque ${a.block}: ${text} por ${a.registrant}`));
}

registerButton.onclick = async (event) => {
  event.preventDefault();
  message.textContent = "Enviando…";
  try {
    const id = await register(client, wallet!, registry, labelInput.value);
    message.textContent = `✅ Alta #${id}`;
    labelInput.value = "";
    await refresh();
  } catch (err) {
    report(err);
  }
};

(await activity(client, registry, fromBlock)).forEach(show);
watchActivity(client, registry, (a) => {
  show(a);
  refresh().catch(report);
});
await refresh();
