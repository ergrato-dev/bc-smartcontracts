# Ejercicio 03 — Escuchar eventos

> Al terminar habrás leído el historial de `Transfer` del Token, filtrado por destinatario,
> consultado un saldo en un bloque pasado, sacado los eventos de un recibo y escuchado
> transferencias nuevas mientras llegan.

**Duración estimada**: 2 h
**Prerrequisitos**: [Ejercicio 02](../ejercicio-02-escribir-transacciones/README.md) terminado;
[Teoría 04 — Eventos y logs](../../1-teoria/04-eventos-y-logs.md) leída.

## Contexto

Mismo formato que los ejercicios 01 y 02, sobre `src/events.ts`. El despliegue deja tres
`Transfer` en la cadena:

| Bloque | from | to | value |
| ------ | ---- | -- | ----- |
| 1 | `0x0000…0000` (emisión) | cuenta 0 | 1000 BCT |
| 2 | cuenta 0 | cuenta 1 | 100 BCT |
| 3 | cuenta 0 | cuenta 2 | 50 BCT |

Los tests de los pasos 4 y 5 envían más transferencias desde la cuenta 1, con su propio
cliente de cartera.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-17-frontend_con_viem/2-practicas/ejercicio-03-escuchar-eventos/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
bash test.sh
```

**Verifica**: cinco `✖`, uno con cada `Error: TODO: Paso N`, y `✔ sin errores de tipos`.

## Paso 1: El historial

**Por qué**: una página cuenta lo que pasó. Los eventos son ese registro, y leerlos no cuesta
gas.

```ts
const logs = await client.getContractEvents({
  address: token,
  abi: tokenAbi,
  eventName: "Transfer",
  fromBlock: 0n,
});
return logs.map((log) => ({ block: log.blockNumber, ...log.args }));
```

`address` limita la búsqueda a tu Token: un `Transfer` de otro contrato no cuenta.

**Verifica**: `✔ Paso 1` con los tres `Transfer` de la tabla, en orden de bloque.

## Paso 2: Filtrar por un campo indexed

**Por qué**: `to` es `indexed`, así que va en un topic y el nodo filtra por él. No traes todos
los logs para descartarlos tú.

```ts
const logs = await client.getContractEvents({
  address: token,
  abi: tokenAbi,
  eventName: "Transfer",
  args: { to: account },
  fromBlock: 0n,
});
return logs.map((log) => log.args.value);
```

Prueba a cambiar `to` por `value` en `args`: `tsc` lo rechaza, porque `value` no es `indexed`.
Déjalo como estaba.

**Verifica**: `✔ Paso 2`: la cuenta 1 recibió `[100000000000000000000n]` y la cuenta 5, `[]`.

## Paso 3: El pasado

**Por qué**: un evento dice qué pasó; el estado en un bloque pasado dice cómo estaba todo en
ese momento.

```ts
return client.readContract({
  address: token,
  abi: tokenAbi,
  functionName: "balanceOf",
  args: [account],
  blockNumber,
});
```

**Verifica**: `✔ Paso 3`: la cuenta 1 tenía `0n` en el bloque 1 y 100 BCT en el bloque 2.

## Paso 4: Los eventos de un recibo

**Por qué**: después de escribir, lo que interesa suele estar en un evento de esa
transacción. El recibo ya trae sus logs, sin otra petición.

```ts
const logs = parseEventLogs({ abi: tokenAbi, eventName: "Transfer", logs: receipt.logs });
return logs.map((log) => log.args);
```

**Verifica**: `✔ Paso 4`. El test envía 3 BCT de la cuenta 1 a la 5 y el recibo trae
`[{ from: cuenta 1, to: cuenta 5, value: 3000000000000000000n }]`.

## Paso 5: Escuchar

**Por qué**: la página se actualiza sola cuando alguien transfiere, sin recargar.

```ts
return client.watchContractEvent({
  address: token,
  abi: tokenAbi,
  eventName: "Transfer",
  pollingInterval: 100,
  onLogs: (logs) => logs.forEach((log) => onTransfer(log.args)),
});
```

`watchContractEvent` devuelve la función que deja de escuchar. El test la llama en un
`finally`: sin eso, viem seguiría preguntando al nodo cada 100 ms y el proceso no terminaría.

**Verifica**: `✔ Paso 5`, `ℹ pass 5` y `✔ sin errores de tipos`. El test empieza a escuchar,
envía 2 BCT y recibe ese `Transfer` en menos de 5 s.

## Qué aprendiste

- `getContractEvents` lee el historial; `args` filtra por campos `indexed` en el nodo.
- `blockNumber` en una lectura da el estado de un bloque pasado.
- `parseEventLogs` saca los eventos de un recibo.
- `watchContractEvent` avisa de los nuevos y devuelve con qué dejar de escuchar.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Escribir transacciones](../ejercicio-02-escribir-transacciones/README.md) | **Ejercicio 03 — Escuchar eventos** | [Proyecto — La página del protocolo →](../../3-proyecto/README.md) |
