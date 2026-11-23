# Teoría 05 — La página con Vite

## 🎯 Objetivos

- Servir una página TypeScript con Vite desde el contenedor y abrirla en tu navegador.
- Configurar la página con variables `VITE_` y saber que son públicas.
- Pintar texto que viene de la cadena sin abrir la puerta a código ajeno.
- Apuntar la misma página a anvil o, solo para leer, a Sepolia.

## 1. Qué problema resuelve

Hasta la teoría 04, todo corre en Node. El navegador no ejecuta TypeScript ni sabe encontrar
`viem` en `node_modules`. Hace falta algo que convierta tu código en JavaScript que el navegador
entienda y que se lo entregue. Eso es **Vite**: en desarrollo, un servidor que traduce cada
archivo cuando el navegador lo pide y recarga la página cuando lo guardas; al terminar,
`vite build`, que lo empaqueta todo en `dist/` para publicarlo.

## 2. Cómo funciona

El proyecto tiene una carpeta `web/` con:

| Archivo | Qué es |
| ------- | ------ |
| `index.html` | La página. Carga `/src/main.ts` con `<script type="module">` |
| `src/main.ts` | La interfaz: crea los elementos y responde a los botones |
| `src/protocol.ts` | Lo que habla con la cadena: lo que escribes esta semana |
| `src/abi.ts`, `src/registry-abi.ts` | Las ABI |
| `.env.local` | La configuración: red, URL del nodo, dirección del registro |

El navegador está en tu máquina y Vite y anvil en el contenedor. Por eso el contenedor publica
dos puertos: el 5173, donde Vite sirve la página, y el 8545, donde la página habla con anvil. El
JSON-RPC lo hace **el navegador**, no Vite: la URL del nodo tiene que funcionar desde tu
máquina.

## 3. Cómo se escribe

### Arrancar

Desde la carpeta del proyecto (la de `contracts/` y `web/`):

```bash
docker run --rm -it -p 8545:8545 -p 5173:5173 -v "$PWD":/workspace bc-smartcontracts-dev
anvil --silent &
```

El README del proyecto despliega el protocolo y escribe `web/.env.local`. Después:

```bash
cd web
pnpm install --offline --frozen-lockfile
pnpm dev
```

`pnpm dev` es `vite --host 0.0.0.0`: sin `--host`, Vite solo escucharía dentro del contenedor y
tu navegador no llegaría. Abre `http://localhost:5173`.

anvil acepta peticiones de una página de otro origen: el navegador las bloquearía si el nodo
no lo permitiera (**CORS**), y anvil lo permite por defecto.

### Configuración con VITE_

```bash
# web/.env.local
VITE_RPC_URL=http://127.0.0.1:8545
VITE_REGISTRY=0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
VITE_ACCOUNT=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
```

En el código, `import.meta.env.VITE_REGISTRY`. Vite solo pasa a la página las variables que
empiezan por `VITE_`, y las **copia como texto en el JavaScript** que entrega. Cualquiera que
abra la página las ve con las herramientas del navegador, y en `dist/` quedan escritas. Una
variable `VITE_` es pública siempre: URL del nodo y direcciones, sí; claves, nunca.

`.env.local` va en `.gitignore`: cada uno tiene su anvil y su despliegue.

### Pintar lo que viene de la cadena

Cualquiera puede registrar un recurso con la etiqueta que quiera. Si la página hiciera

```ts
row.innerHTML = `#${item.id} ${item.label}`; // ❌
```

una etiqueta `<img src=x onerror="…">` ejecutaría código en la página de quien la mira, con
acceso a todo lo que la página puede hacer. Es un **XSS** (*cross-site scripting*). `main.ts`
crea los elementos y les da el texto con `textContent`, que nunca se interpreta como HTML. Con
un alta de etiqueta `<b>hola</b>`, la página muestra los caracteres tal cual:

```
#1 <b>hola</b> — Activo
```

### La misma página en Sepolia

Tu registro de la semana 16 está en Sepolia y es público: la página puede leerlo con un RPC
público, sin cuenta.

```bash
# web/.env.local para Sepolia: solo lectura
VITE_CHAIN=sepolia
VITE_RPC_URL=https://ethereum-sepolia-rpc.publicnode.com
VITE_REGISTRY=<tu proxy en Sepolia>
VITE_FROM_BLOCK=<bloque de tu despliegue>
```

Sin `VITE_ACCOUNT`, `main.ts` no crea cartera y oculta el formulario. Escribir en Sepolia
necesita que firme alguien que tenga la clave: la wallet del navegador, en la semana 18.

### Construir

```bash
pnpm build
```

`pnpm build` es `tsc && vite build`: revisa los tipos y escribe `dist/`, una página estática
(HTML y JavaScript) que puede servir cualquier servidor web.

## 4. Antipatrones y riesgos

- **Una clave en `VITE_`.** Queda escrita en el JavaScript que descarga cualquiera.
- **`innerHTML` con datos de la cadena.** Etiquetas, nombres y URI de metadatos los escribe
  cualquiera. Siempre `textContent`.
- **Una URL de RPC con clave de API en `VITE_RPC_URL`.** Muchos proveedores dan una URL con tu
  clave dentro. En la página es pública: quien la copie gasta tu cuota. Para una página pública
  usa un RPC público o uno restringido a tu dominio en el panel del proveedor.
- **Fiarse de la página.** Un usuario puede saltarse la página entera. La página explica las
  reglas; el contrato las impone.
- **Mezclar red y dirección.** `VITE_CHAIN=sepolia` con la dirección de anvil da
  `returned no data`. Muestra siempre la red y la dirección en la página, como hace `main.ts`.

## 5. Trucos

- Vite recarga la página al guardar un archivo. Si cambias `.env.local` y la página no lo
  refleja, reinicia `pnpm dev`.
- Las herramientas del navegador (F12), pestaña Red, muestran cada petición JSON-RPC: método,
  parámetros y respuesta.
- Si reinicias anvil, las altas desaparecen pero el navegador conserva la página: recárgala.

## ✅ Checklist

- [ ] Sirvo la página con `pnpm dev` desde el contenedor y sé qué dos puertos publicar.
- [ ] Explico por qué una variable `VITE_` es pública y qué no va nunca en ella.
- [ ] Pinto texto de la cadena con `textContent` y sé qué pasa con `innerHTML`.
- [ ] Apunto la página a Sepolia en solo lectura.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — Eventos y logs](04-eventos-y-logs.md) | **Teoría 05 — La página con Vite** | [Ejercicio 01 — Leer la cadena →](../2-practicas/ejercicio-01-leer-la-cadena/README.md) |
