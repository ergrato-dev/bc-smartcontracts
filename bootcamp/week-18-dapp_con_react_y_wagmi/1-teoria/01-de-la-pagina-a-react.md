# Teoría 01 — De la página a React

## 🎯 Objetivos

- Explicar qué problema de la página de la semana 17 resuelve React.
- Escribir componentes con JSX, pasarles datos con props y guardar estado con `useState`.
- Saber cuándo React vuelve a ejecutar un componente y por qué el estado se cambia con una
  función.
- Usar `useEffect` para lo que vive fuera de React, y limpiarlo.
- Pintar listas con `key` y texto de la cadena sin abrir la puerta a XSS.

## 1. Qué problema resuelve

Mira cómo se refresca la página de la semana 17 después de un alta (`main.ts`):

```ts
const id = await register(client, wallet!, registry, labelInput.value);
message.textContent = `✅ Alta #${id}`;
labelInput.value = "";
await refresh();
```

Y `refresh` vuelve a leer el estado, los recursos y los puntos, y rehace con
`replaceChildren` cada sección. Funciona, pero cada cambio obliga a recordar **qué partes de la
pantalla dependen de él**. Si mañana el estado muestra también tus puntos, tienes que acordarte
de refrescarlo después del alta, de la baja y de cada evento. Con una cuenta conectada que puede
cambiar en cualquier momento desde la wallet, la lista de "qué refrescar cuándo" crece sin
control.

**React** le da la vuelta: describes **cómo se ve la pantalla para un estado dado** y, cuando el
estado cambia, React vuelve a calcular la descripción y actualiza solo lo que cambió del DOM. Tú
no tocas el DOM.

## 2. Cómo funciona

- Un **componente** es una función que recibe datos y devuelve qué pintar. Su nombre empieza
  por mayúscula.
- **JSX** es la sintaxis parecida a HTML que va dentro del TypeScript: `<p>Hola, {nombre}</p>`.
  Lo que va entre llaves es una expresión de TypeScript. Los archivos con JSX acaban en `.tsx`.
- **Props**: los datos que un componente recibe de quien lo usa, como los atributos de HTML.
- **Estado**: datos que un componente recuerda entre ejecuciones. Se crean con `useState`.
- **Render**: cada ejecución del componente. React vuelve a ejecutar un componente cuando
  cambia su estado o sus props, compara el resultado con el anterior y aplica la diferencia al
  DOM.
- **Hook**: una función de React cuyo nombre empieza por `use` (`useState`, `useEffect` y,
  desde la teoría 02, los de wagmi). Solo se llama en el cuerpo de un componente o de otro
  hook, nunca dentro de un `if` ni de un bucle: React los reconoce por su orden.

Vite no entiende JSX por sí solo para React: el proyecto trae el plugin `@vitejs/plugin-react`
en `vite.config.ts`, y `tsconfig.json` lleva `"jsx": "react-jsx"` para que `tsc` lo compruebe.

## 3. Cómo se escribe

Para probar los ejemplos, en la carpeta `web/` de tu proyecto (cuando lo prepares con el README
del proyecto) crea dos archivos que borrarás al terminar:

```html
<!-- web/demo.html -->
<!doctype html>
<html lang="es">
  <body>
    <div id="root"></div>
    <script type="module" src="/src/demo.tsx"></script>
  </body>
</html>
```

```tsx
// web/src/demo.tsx
import { StrictMode, useEffect, useState } from "react";
import { createRoot } from "react-dom/client";

function Saludo({ nombre }: { nombre: string }) {
  return <p>Hola, {nombre}</p>;
}

function Contador() {
  const [veces, setVeces] = useState(0);
  return <button onClick={() => setVeces((v) => v + 1)}>Pulsado {veces} veces</button>;
}

function Etiquetas({ etiquetas }: { etiquetas: string[] }) {
  return (
    <ul>
      {etiquetas.map((etiqueta, i) => (
        <li key={i}>{etiqueta}</li>
      ))}
    </ul>
  );
}

function Reloj() {
  const [segundos, setSegundos] = useState(0);
  useEffect(() => {
    const id = setInterval(() => setSegundos((s) => s + 1), 1000);
    return () => clearInterval(id);
  }, []);
  return <p>Abierta hace {segundos} s</p>;
}

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <Saludo nombre="Ana" />
    <Contador />
    <Etiquetas etiquetas={["Primer recurso", "<img src=x onerror=alert(1)>"]} />
    <Reloj />
  </StrictMode>,
);
```

Dentro del contenedor, en `web/`, arranca `pnpm dev` y abre
`http://localhost:5173/demo.html`. Vite sirve cualquier `.html` de la carpeta, no solo
`index.html`. Tras pulsar el botón tres veces y esperar cuatro segundos, el DOM es:

```html
<div id="root">
  <p>Hola, Ana</p>
  <button>Pulsado 3 veces</button>
  <ul>
    <li>Primer recurso</li>
    <li>&lt;img src=x onerror=alert(1)&gt;</li>
  </ul>
  <p>Abierta hace 4 s</p>
</div>
```

Pieza a pieza:

### Props

`<Saludo nombre="Ana" />` llama a `Saludo` con `{ nombre: "Ana" }`. El tipo de las props se
escribe como el de cualquier parámetro. Un componente no cambia sus props: las decide quien lo
usa.

### Estado

`useState(0)` devuelve el valor actual y la función que lo cambia. Llamar a `setVeces` no cambia
`veces` en esta ejecución: pide a React otro render, y en ese render `veces` ya vale lo nuevo.

Por eso el estado nuevo se calcula con una función, `setVeces((v) => v + 1)`. Si escribes
`setVeces(veces + 1)` y el botón recibe tres clics seguidos antes de que React vuelva a pintar,
los tres calculan `0 + 1`: probado en Chromium, el botón dice `Pulsado 1 veces`. Con la función,
cada cambio parte del anterior y dice `Pulsado 3 veces`.

### Listas y `key`

`map` convierte cada elemento en JSX. `key` le dice a React qué elemento es cuál entre dos
renders. Aquí vale el índice porque la lista no cambia; en la página del proyecto, cada recurso
usa su `id`, que no cambia aunque la lista se reordene. Sin `key`, React avisa en la consola del
navegador.

### Efectos

`useEffect(fn, [])` ejecuta `fn` **después** de pintar, para lo que vive fuera de React: un
temporizador, una suscripción, una petición. La función que devuelve `fn` es la **limpieza**:
React la llama al quitar el componente. El array del final dice cuándo repetir el efecto: `[]`
es solo al montar; `[a, b]`, cada vez que cambie `a` o `b`.

`StrictMode` monta, desmonta y vuelve a montar cada componente en desarrollo, para que un efecto
sin limpieza se note. Sin el `clearInterval`, el reloj contaría de dos en dos.

### Texto de la cadena

`{etiqueta}` pinta texto: React escapa `<`, `>` y `&`. La etiqueta con `<img … onerror>` sale
tal cual, como en la semana 17 con `textContent`, pero sin tener que acordarte.

## 4. Antipatrones y riesgos

- **`dangerouslySetInnerHTML` con datos de la cadena.** Es el `innerHTML` de React, y su
  nombre avisa:

  ```tsx
  // ❌ Una etiqueta registrada por otra persona ejecuta código en tu página (XSS)
  <li dangerouslySetInnerHTML={{ __html: item.label }} />
  ```

  Las etiquetas del registro las escribe cualquiera. Pinta siempre `{item.label}`.
- **Enlaces con datos de la cadena.** En `<a href={item.label}>`, React bloquea las URL
  `javascript:`, pero no sabe adónde lleva el enlace: puede ser una copia de tu página que pide
  firmar otra cosa. No conviertas en enlace un texto de la cadena; si hace falta, acepta solo
  dominios que conozcas.
- **Cambiar el estado sin su función.** `veces = veces + 1` o `lista.push(x)` no avisan a React
  y la pantalla no cambia. Usa `setVeces` y una lista nueva: `setLista((l) => [...l, x])`.
- **Efectos sin limpieza.** Un temporizador o una escucha que no se paran siguen corriendo al
  quitar el componente: gastan peticiones al nodo y pueden escribir en un estado que ya no se ve.
- **Un hook dentro de un `if`.** `if (address) useReadContract(…)` cambia el orden de los
  hooks entre renders y React lanza un error. En la teoría 02 verás cómo esperar a tener datos
  sin `if`: `enabled`.

## 5. Trucos

- Las **React Developer Tools** del navegador muestran el árbol de componentes con sus props y
  su estado.
- Un componente por responsabilidad: `Wallet`, `Status`, `Register`, `Items` y `Activity` en el
  proyecto. Cada uno llama a los hooks que necesita y nada más.
- Si un valor se calcula a partir de otros (`busy` a partir de `status`), calcúlalo en el
  render: no necesita su propio `useState`.
- Al terminar de probar, borra `web/demo.html` y `web/src/demo.tsx`: no van en el commit.

## ✅ Checklist

- [ ] Sé por qué React evita el "qué refrescar cuándo" de la semana 17.
- [ ] Escribo un componente con props y estado, y sé cuándo se vuelve a ejecutar.
- [ ] Cambio el estado con una función cuando depende del anterior.
- [ ] Sé para qué es `useEffect` y por qué devuelve una limpieza.
- [ ] Pinto texto de la cadena con `{…}` y nunca con `dangerouslySetInnerHTML`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Semana 18 — dApp con React y wagmi](../README.md) | **Teoría 01 — De la página a React** | [Teoría 02 — wagmi por dentro →](02-wagmi-por-dentro.md) |
