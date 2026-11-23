import { useState } from "react";
import { formatEther, type Address } from "viem";
import { useChains, useConnectors } from "wagmi";
import { useActivity, useItems, usePoints, useRegister, useRetire, useStatus, useWallet, type TxStatus } from "./hooks.ts";

// ¿Qué? La página: pinta lo que devuelven los hooks de hooks.ts y los llama desde los botones.
// ¿Impacto? JSX pinta todo `{texto}` como texto, nunca como HTML: una etiqueta con <script>
//   que venga de la cadena se ve tal cual. No uses `dangerouslySetInnerHTML` con datos de la
//   cadena.

const ITEM_STATUS = ["Ninguno", "Activo", "Retirado"];
const TX_TEXT: Record<TxStatus, string> = {
  lista: "",
  firmando: "Firma en tu wallet…",
  confirmando: "Esperando el bloque…",
  confirmada: "✅ Confirmada",
  fallida: "❌",
};

export function App({ registry, fromBlock }: { registry: Address; fromBlock: bigint }) {
  const [chain] = useChains();
  const wallet = useWallet();
  return (
    <main>
      <h1>Registro</h1>
      <p>
        Red: {chain.name} · Registro: {registry}
      </p>
      <Wallet />
      <Status registry={registry} />
      {wallet.address && !wallet.wrongChain && (
        <>
          <Register registry={registry} />
          <Items registry={registry} />
        </>
      )}
      <Activity registry={registry} fromBlock={fromBlock} />
    </main>
  );
}

function Wallet() {
  const wallet = useWallet();
  const connectors = useConnectors();
  const [chain] = useChains();
  if (!wallet.address) {
    return (
      <section>
        <p>Conecta una wallet para dar de alta y ver tus recursos.</p>
        {connectors.map((connector) => (
          <button key={connector.uid} onClick={() => wallet.connect(connector)}>
            Conectar {connector.name}
          </button>
        ))}
      </section>
    );
  }
  return (
    <section>
      <p>
        Cuenta: {wallet.address} <button onClick={wallet.disconnect}>Desconectar</button>
      </p>
      {wallet.wrongChain && (
        <p>
          ⚠️ Tu wallet está en otra red. <button onClick={wallet.switchToApp}>Cambiar a {chain.name}</button>
        </p>
      )}
    </section>
  );
}

function Status({ registry }: { registry: Address }) {
  const status = useStatus(registry);
  if (!status) return <p>Cargando el registro…</p>;
  return (
    <section>
      <h2>Estado</h2>
      <p>
        Versión {status.version.toString()} · {status.remaining.toString()} plazas libres de {status.capacity.toString()} · Tasa{" "}
        {formatEther(status.fee)} ETH{status.paused && " · EN PAUSA"}
      </p>
    </section>
  );
}

function Register({ registry }: { registry: Address }) {
  const [label, setLabel] = useState("");
  const { register, status, id, error } = useRegister(registry);
  const busy = status === "firmando" || status === "confirmando";
  return (
    <section>
      <h2>Alta</h2>
      <form
        onSubmit={(event) => {
          event.preventDefault();
          register(label);
        }}
      >
        <input value={label} onChange={(event) => setLabel(event.target.value)} placeholder="Etiqueta del recurso" />
        <button disabled={busy}>Dar de alta</button>
      </form>
      <p>
        {TX_TEXT[status]} {status === "confirmada" && id !== undefined && `Alta #${id}`} {error}
      </p>
    </section>
  );
}

function Items({ registry }: { registry: Address }) {
  const items = useItems(registry);
  const points = usePoints(registry);
  const { retire, status, error } = useRetire(registry);
  const busy = status === "firmando" || status === "confirmando";
  return (
    <section>
      <h2>Tus recursos · {points ?? "…"}</h2>
      <p>
        {TX_TEXT[status]} {error}
      </p>
      <ul>
        {items?.map((item) => (
          <li key={item.id.toString()}>
            #{item.id.toString()} {item.label} — {ITEM_STATUS[item.status]}{" "}
            {item.status === 1 && (
              <button disabled={busy} onClick={() => retire(item.id)}>
                Retirar
              </button>
            )}
          </li>
        ))}
      </ul>
    </section>
  );
}

function Activity({ registry, fromBlock }: { registry: Address; fromBlock: bigint }) {
  const activity = useActivity(registry, fromBlock);
  return (
    <section>
      <h2>Actividad</h2>
      <ol>
        {activity
          ?.toReversed()
          .map((a) => (
            <li key={`${a.block}-${a.kind}-${a.id}`}>
              Bloque {a.block.toString()}: {a.kind === "registered" ? `alta #${a.id} «${a.label}»` : `baja #${a.id}`} por {a.registrant}
            </li>
          ))}
      </ol>
    </section>
  );
}
