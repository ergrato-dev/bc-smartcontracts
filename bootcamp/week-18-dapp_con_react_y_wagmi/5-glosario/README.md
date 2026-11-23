# 📖 Glosario — Semana 18

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| **Acción** (de wagmi) | Función de `@wagmi/core` que recibe la configuración; funciona sin React | `readContract(config, { … })` |
| **Caché de consultas** | Donde TanStack Query guarda el resultado de cada lectura, bajo su clave | dos componentes que leen el mismo saldo hacen una petición |
| **Clave de consulta** (*queryKey*) | Lo que identifica una lectura en la caché: acción, contrato, función, argumentos y red | `['readContract', { functionName: 'balanceOf', … }]` |
| **Componente** | Función de React que recibe props y devuelve qué pintar; su nombre empieza por mayúscula | `function Status({ registry }) { … }` |
| **Conector** (*connector*) | Pieza de wagmi que habla con una wallet concreta | `injected()`, `mock({ accounts })` |
| **Efecto** | Código que React ejecuta después de pintar, para lo que vive fuera de React; devuelve su limpieza | `useEffect(() => { … return () => clearInterval(id); }, [])` |
| **EIP-1193** | Estándar del proveedor de una wallet: `request` y eventos | `window.ethereum.request({ method: "eth_chainId" })` |
| **EIP-6963** | Estándar con el que varias wallets se anuncian en la misma página | un botón *Conectar* por cada wallet instalada |
| **`enabled`** | Opción de una lectura que la deja en espera mientras es `false` | `query: { enabled: address !== undefined }` |
| **Estado** (de React) | Dato que un componente recuerda entre renders | `const [veces, setVeces] = useState(0)` |
| **Hook** | Función de React cuyo nombre empieza por `use`; solo se llama en un componente o en otro hook, siempre en el mismo orden | `useReadContract`, `useState` |
| **Invalidar** | Marcar consultas de la caché como viejas para que se repitan | `queryClient.invalidateQueries()` |
| **JSX** | Sintaxis parecida a HTML dentro de TypeScript; escapa el texto entre llaves | `<p>Hola, {nombre}</p>` |
| **Mempool** | Cola de transacciones firmadas que un nodo conoce y aún no están en un bloque | estado "confirmando" |
| **Mutación** | En TanStack Query, una operación que cambia algo y se lanza con `mutate` | `useWriteContract`, `useConnect` |
| **Props** | Datos que un componente recibe de quien lo usa | `<Saludo nombre="Ana" />` |
| **Proveedor** (de React) | Componente que pone un valor al alcance de todos los de dentro; no confundir con el proveedor de una wallet | `<WagmiProvider config={config}>` |
| **Proveedor** (de wallet) | Objeto con el que la página habla con la wallet (EIP-1193) | `window.ethereum` |
| **Red equivocada** | La wallet conectada está en una red distinta de la del contrato de la página | `chainId !== appChain.id` |
| **Render** | Cada ejecución de un componente; React compara el resultado con el anterior y actualiza el DOM | cambia el estado y el texto se repinta |
| **`renderHook`** | Función de Testing Library que monta un hook en un componente de prueba | `renderHook(() => useStatus(registry), { wrapper })` |
| **`UserRejectedRequestError`** | Error de viem cuando la persona rechaza en la wallet; código 4001 | "Cancelaste la firma en la wallet" |
| **wagmi** | Biblioteca de hooks de React para Ethereum, sobre viem, con caché y estado de la wallet | `useWriteContract()` |
| **Wallet** | Programa que guarda las claves, enseña qué se va a firmar y firma si la persona acepta | una extensión del navegador |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | Semana 19 (próximamente) |
