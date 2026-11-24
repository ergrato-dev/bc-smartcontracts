# 🎬 Videografía — Semana 24

| Título | Canal | Duración | Enlace |
| ------ | ----- | -------- | ------ |
| Invariant Testing - Part 1 - Open Testing | Smart Contract Programmer | 8:00 | https://www.youtube.com/watch?v=JtzBi67hgLI |
| Invariant Testing - Part 2 - Handler Based Testing | Smart Contract Programmer | 12:55 | https://www.youtube.com/watch?v=RFOqce1rz7U |
| Invariant Testing - Part 3 - Actor Management | Smart Contract Programmer | 9:35 | https://www.youtube.com/watch?v=kPx4K8kRvUQ |
| Horsefacts Eth - Invariant Testing WETH with Foundry | [EthCC] Livestream 5 | 52:30 | https://www.youtube.com/watch?v=sJpL21yJpgs |
| Fuzzing Smart Contracts with MEDUSA | Bloqarl \| Zealynx | 9:19 | https://www.youtube.com/watch?v=I4MP-KXJE54 |
| Learn how to fuzz like a pro: Introduction to fuzzing | trailofbits | 1:03:25 | https://www.youtube.com/watch?v=QofNQxW_K08 |

Todos están en inglés, y casi todos son de versiones anteriores de Foundry: la salida que
enseñan no es la de la v1.9.0. Lo que explican sigue valiendo; los comandos y los números, compruébalos
en el contenedor.

- **La serie de Smart Contract Programmer** sigue el orden de las teorías 02 y 03: primero sin
  handler, con la tabla de llamadas y reverts; después con handler; y al final con varias
  cuentas, como los `actors` del ejercicio 02.
- **Invariant Testing WETH** es un taller largo que escribe invariantes y un handler para WETH
  desde cero, con variables fantasma. Es el mismo proceso que el proyecto, en otro contrato.
- **Fuzzing Smart Contracts with MEDUSA** monta Medusa desde la configuración de Echidna, el
  fuzzer anterior de Trail of Bits. Aquí no usas Echidna: quédate con la parte de `medusa.json`.
- **Introduction to fuzzing** es la primera sesión del curso de Trail of Bits, con Echidna. La
  primera mitad, sobre cómo elegir invariantes, vale igual para forge y Medusa.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ebooks gratuitos](../ebooks-free/README.md) | **Videografía** | [Webgrafía →](../webgrafia/README.md) |
