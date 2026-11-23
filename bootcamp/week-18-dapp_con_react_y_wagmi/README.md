# Semana 18 — dApp con React y wagmi

La página de la semana 17 firmaba con una cuenta desbloqueada de anvil y se refrescaba a mano.
Esta semana la conviertes en una **dApp**: una página que firma con la **wallet** de quien la
usa, así que funciona igual en anvil que en Sepolia sin que ninguna clave pase por tu código.
La escribes con **React**, que repinta la pantalla cuando cambia el estado, y **wagmi**, que
añade a viem hooks de React, una caché de lecturas y el estado de la wallet. Verás cómo
conectar una wallet, detectar que está en otra red y seguir cada transacción desde el clic
hasta el recibo.

## 🎯 Objetivos de aprendizaje

- Escribir componentes de React con props, estado y efectos, y pintar texto de la cadena sin
  XSS.
- Configurar wagmi (redes, transportes y conectores) y usar sus acciones y sus hooks.
- Leer con la caché de wagmi, esperar datos con `enabled` e invalidar tras escribir.
- Conectar una wallet por EIP-1193 y EIP-6963, seguir cuenta y red, y pedir el cambio de red.
- Llevar una transacción por sus estados (firmando, confirmando, confirmada, fallida) y explicar
  cada final a la persona.
- Probar hooks sin navegador con una wallet `mock` y `renderHook`.
- Reconocer los riesgos: claves de anvil fuera de anvil, red equivocada, doble envío, caché vieja
  y páginas que piden firmar otra cosa.

## 📋 Prerrequisitos

[Semana 17](../week-17-frontend_con_viem/README.md) terminada: tu página con viem en `week-17/`,
en `main`. Una wallet de navegador que puedas instalar en un perfil nuevo, solo para pruebas
([teoría 03](1-teoria/03-conectar-la-wallet.md#preparar-una-wallet-para-anvil)).

La imagen del bootcamp trae React, wagmi y las bibliotecas de test desde esta semana:
reconstrúyela antes de empezar (`docker build -t bc-smartcontracts-dev docker`).

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — De la página a React](1-teoria/01-de-la-pagina-a-react.md) | 45 min |
| 2 | [Teoría 02 — wagmi por dentro](1-teoria/02-wagmi-por-dentro.md) | 45 min |
| 3 | [Teoría 03 — Conectar la wallet](1-teoria/03-conectar-la-wallet.md) | 45 min |
| 4 | [Teoría 04 — Estado de una transacción](1-teoria/04-estado-de-una-transaccion.md) | 45 min |
| 5 | [Ejercicio 01 — Conectar la cuenta](2-practicas/ejercicio-01-conectar-la-cuenta/README.md) | 1 h 30 min |
| 6 | [Ejercicio 02 — Leer y escribir](2-practicas/ejercicio-02-leer-y-escribir/README.md) | 2 h |
| 7 | [Ejercicio 03 — Hooks de React](2-practicas/ejercicio-03-hooks-de-react/README.md) | 2 h 30 min |
| 8 | [Proyecto — La dApp del protocolo](3-proyecto/README.md) | 4 h |
| 9 | [Rúbrica de evaluación](rubrica-evaluacion.md) (autoevaluación) | 30 min |
| 10 | [Ebooks](4-recursos/ebooks-free/README.md), [videos](4-recursos/videografia/README.md), [webgrafía](4-recursos/webgrafia/README.md) y [glosario](5-glosario/README.md) | 30 min |

## ⏱️ Distribución del tiempo (14 h)

| Parte | Tiempo |
| ----- | ------ |
| Teoría | 3 h |
| Prácticas | 6 h |
| Proyecto | 4 h |
| Autoevaluación, recursos y glosario | 1 h |

## ✅ Cómo saber que terminaste

- Ejercicios 01 y 02: `bash test.sh` con 5 de 5 tests; ejercicio 03, con 6 de 6. Los tres con
  `✔ sin errores de tipos`.
- En tu repositorio, `bash test.sh` de `week-18/` pasa 9 de 9 tests, con `tsc` y `vite build`
  sin errores. Tu página conecta una wallet, da de alta y retira en anvil y en Sepolia, y avisa
  de la red equivocada. Hay un pull request `week-18` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 17](../week-17-frontend_con_viem/5-glosario/README.md) | **Semana 18 — dApp con React y wagmi** | [Teoría 01 — De la página a React →](1-teoria/01-de-la-pagina-a-react.md) |

← [Volver al índice del bootcamp](../README.md)
