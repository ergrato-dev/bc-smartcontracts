# Instrucciones para agentes — bc-smartcontracts

Fuente de verdad de las convenciones del bootcamp. Léela **antes** de generar contenido.
No deduzcas el patrón mirando archivos sueltos.

## Contexto

| Dato | Valor |
| ---- | ----- |
| Nombre | bc-smartcontracts — Bootcamp Smart Contracts Zero to Advanced |
| Duración | 34 semanas × 14 h = 476 h |
| Modalidad | Autoestudio guiado, 100 % práctico |
| Nivel de entrada | Cero en blockchain. **Sí** se exige programación previa: variables, funciones, condicionales, bucles, clases, terminal y git básicos, en cualquier lenguaje |
| Nivel de salida | Avanzado: Solidity a fondo, EVM y Yul, estándares ERC, proxies, dApps full-stack, auditoría de seguridad (análisis estático, fuzzing de invariantes, verificación formal), DeFi, account abstraction y L2 |
| Fuera de alcance | Trading y especulación; cadenas no EVM (Solana, Cosmos); Vyper más allá de una mención |
| Stack | Solidity 0.8.38, Foundry 1.9 (forge, cast, anvil, chisel), forge-std, OpenZeppelin Contracts 5, Docker `ubuntu:24.04`; desde la fase 4: TypeScript + viem + wagmi (pnpm), FastAPI (uv) + PostgreSQL |

Versiones exactas y política para cambiarlas: [`docs/stack-versions.md`](../docs/stack-versions.md).

## Malla curricular

| Fase | Semana | Carpeta | Tema |
| ---- | ------ | ------- | ---- |
| 1 · Fundamentos de blockchain | 01 | `week-01-criptografia_y_blockchain` | Hash, claves, firmas, bloques y cadena; contenedor y `cast` |
| | 02 | `week-02-ethereum_cuentas_transacciones_y_gas` | Cuentas, nonce, transacciones, gas (EIP-1559), EVM, JSON-RPC, `anvil` |
| | 03 | `week-03-primer_contrato_con_foundry` | Proyecto Foundry, contrato mínimo, compilar, probar, desplegar en anvil, `cast call/send` |
| 2 · Solidity | 04 | `week-04-tipos_y_funciones` | Tipos de valor, variables de estado, visibilidad, `view`/`pure`, constructor, `constant`/`immutable` |
| | 05 | `week-05-control_y_errores` | `if`/bucles, `require`, `revert`, custom errors, `assert`, modificadores, overflow con checked math |
| | 06 | `week-06-estructuras_de_datos` | `struct`, `mapping`, arrays, `enum`, `storage`/`memory`/`calldata` |
| | 07 | `week-07-eventos_y_ether` | Eventos y logs, `payable`, `receive`/`fallback`, enviar ETH, unidades, `block`/`msg` |
| | 08 | `week-08-herencia_interfaces_y_librerias` | Herencia, `virtual`/`override`, `abstract`, interfaces, librerías |
| | 09 | `week-09-testing_con_foundry` | Cheatcodes, fuzz testing, forks, gas reports, cobertura |
| | 10 | `week-10-llamadas_entre_contratos` | ABI encoding, `call`/`staticcall`/`delegatecall`, `try`/`catch`, `CREATE`/`CREATE2` |
| 3 · Estándares y patrones | 11 | `week-11-erc20_y_openzeppelin` | ERC-20, OpenZeppelin, `forge install`, allowance |
| | 12 | `week-12-nfts_erc721_y_erc1155` | ERC-721, ERC-1155, metadata, `tokenURI` |
| | 13 | `week-13-control_de_acceso` | Ownable, AccessControl, Pausable, timelock, multisig |
| | 14 | `week-14-firmas_eip712_y_permit` | ECDSA, EIP-191, EIP-712, ERC-2612 permit, replay |
| | 15 | `week-15-contratos_actualizables` | Proxies, UUPS, transparent, storage layout, initializers |
| 4 · dApps full-stack | 16 | `week-16-despliegue_y_verificacion` | `forge script`, keystores, Sepolia, verificación, broadcast |
| | 17 | `week-17-frontend_con_viem` | TypeScript, viem, leer, escribir y escuchar eventos (pnpm, Vite) |
| | 18 | `week-18-dapp_con_react_y_wagmi` | React, wagmi, conectar wallet, estado de transacciones |
| | 19 | `week-19-indexacion_con_fastapi_y_postgresql` | Indexar eventos con FastAPI + uv + PostgreSQL, reorgs |
| | 20 | `week-20-oraculos_y_datos_offchain` | Chainlink price feeds y VRF, IPFS |
| 5 · Seguridad | 21 | `week-21-vulnerabilidades_clasicas` | Reentrancy, control de acceso, `tx.origin`, DoS, `unchecked` |
| | 22 | `week-22-vulnerabilidades_economicas` | Manipulación de oráculos, flash loans, front-running y MEV, redondeo |
| | 23 | `week-23-analisis_estatico` | Slither (uv), Aderyn, detectores propios |
| | 24 | `week-24-fuzzing_de_invariantes` | Invariant testing en Foundry, handlers, Medusa |
| | 25 | `week-25-verificacion_formal` | SMTChecker, Halmos, ejecución simbólica |
| | 26 | `week-26-auditoria` | Metodología, modelado de amenazas, informe, CTF local |
| 6 · EVM avanzada y ecosistema | 27 | `week-27-evm_por_dentro` | Opcodes, stack, memoria, storage slots, calldata |
| | 28 | `week-28-yul_e_inline_assembly` | Yul, assembly en Solidity, riesgos |
| | 29 | `week-29-optimizacion_de_gas` | Medir, empaquetar storage, patrones baratos, trade-offs |
| | 30 | `week-30-defi` | AMM de producto constante, vaults ERC-4626, préstamos |
| | 31 | `week-31-gobernanza_y_daos` | ERC20Votes, Governor, timelock |
| | 32 | `week-32-account_abstraction` | ERC-4337, EIP-7702, paymasters |
| | 33 | `week-33-l2_y_cross_chain` | Rollups, despliegue en L2, puentes y mensajería |
| | 34 | `week-34-proyecto_integrador` | Integración final y auditoría cruzada |

Los nombres de carpeta de las semanas sin escribir son provisionales: se fijan al
escribir la semana y se actualiza esta tabla.

**Progresión estricta.** Ninguna semana usa lo que se enseña después. Las semanas 01-02
no escriben Solidity (solo `cast` y `anvil`); antes de la 05 no hay `require` ni
modificadores; antes de la 06 no hay `mapping` ni `struct`; antes de la 07 no hay eventos
ni ETH; antes de la 09 los tests usan solo `assertEq`/`assertTrue`, `vm.prank` y
`vm.expectRevert` (presentados como "plantilla" mínima); antes de la 11 no hay
OpenZeppelin; antes de la 17 no hay JavaScript/TypeScript.

**Seguridad como eje, no como bloque.** Desde la semana 03 cada teoría que introduce una
construcción cierra con su sección de antipatrones y el riesgo de seguridad asociado. La
fase 5 profundiza; no presenta el tema por primera vez.

**Nunca dinero real.** Todo corre en `anvil` (local) o en testnets. Ninguna clave privada
real aparece en el repo: se usan las cuentas de prueba de anvil, y la semana 16 enseña
keystores cifrados.

## Distribución de una semana (14 h)

| Parte | Tiempo |
| ----- | ------ |
| `1-teoria/` | 3 h |
| `2-practicas/` | 6 h |
| `3-proyecto/` | 4 h |
| Autoevaluación, recursos, glosario | 1 h |

## Estructura de una semana

```
bootcamp/week-NN-slug_snake_case/
├── README.md                  # Descripción, objetivos, prerrequisitos, contenidos, tiempos, navegación
├── rubrica-evaluacion.md      # Conocimiento 30 / Desempeño 40 / Producto 30
├── 0-assets/                  # SVG, uno por diagrama, NN-nombre.svg
├── 1-teoria/                  # NN-nombre-con-guion.md
├── 2-practicas/
│   └── ejercicio-NN-nombre/
│       ├── README.md          # Pasos guiados
│       └── starter/           # Proyecto Foundry o de terminal: tests escritos y en rojo
├── 3-proyecto/
│   ├── README.md
│   └── starter/
├── 4-recursos/{ebooks-free,videografia,webgrafia}/README.md
└── 5-glosario/README.md
```

Plantilla de proyecto Foundry: [`docs/plantillas/starter-foundry/`](../docs/plantillas/starter-foundry/).
Su `foundry.toml` usa la forge-std de la imagen (`/opt/lib`); se copia entero.

## 1-teoria

- Número de archivos libre: los que pida el tema. Un archivo = un concepto.
- 200-300 líneas por archivo. Si se pasa, mezcla dos temas: se divide, no se recorta.
- Orden de cada archivo: `## 🎯 Objetivos` → **qué problema resuelve** → **cómo
  funciona** → **cómo se escribe** (Solidity, `cast`, ...) → **antipatrones y riesgos** →
  **trucos** → `## ✅ Checklist` → navegación.
- **Cero en blockchain de verdad**: cada término del dominio se define la primera vez
  ("hash", "nonce", "gas", "ABI", "storage"...). Lo que es programación general
  (variable, función, bucle, clase) se da por conocido.
- **Paso a paso, nunca asumir**: todo ejemplo dice dónde se escribe, qué comando lo
  ejecuta y qué salida exacta produce.
- **Todo fragmento compila y se ejecuta** con la toolchain de `docs/stack-versions.md`,
  en el contenedor. Hashes, direcciones, gas y errores se copian de la salida real, nunca
  de memoria. Lo que NO se hace se marca `// ❌` con el error o warning exacto.
- Enlaza la fuente oficial: [docs.soliditylang.org](https://docs.soliditylang.org),
  [getfoundry.sh](https://getfoundry.sh), [ethereum.org](https://ethereum.org/developers/docs/),
  los EIP en [eips.ethereum.org](https://eips.ethereum.org).

## 2-practicas

Ejercicios **guiados**: el aprendiz sigue pasos, cada uno con su porqué, su código y
su verificación. Sin `solution/`: el código marcado en el starter es la solución.

Dos tipos de starter, que `scripts/compilar-starters.sh` reconoce solos:

**Foundry** (trae `foundry.toml`; tests en `test/*.t.sol`):

```solidity
// PASO 2: devolver el saludo.
// Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
function greet() external pure returns (string memory) {
    revert("TODO: Paso 2");
    //> return "Hola";
}
```

- `revert("TODO: Paso N");` va solo en su línea. El test del paso falla con ese mensaje.
- Las líneas de solución empiezan con `//> `. Los comentarios explicativos usan `//`.
- El starter compila (se toleran warnings de parámetros sin usar); resuelto, pasa
  `forge test --deny warnings`.

**Terminal** (semanas 01-02 y pasos de `cast`; trae `pasos.sh` y `test.sh`):

```bash
# PASO 2: calcular el hash keccak256 del texto "hola".
# Borra la línea todo y descomenta las líneas que empiezan con `#> `.
step2() {
  todo "Paso 2"
  #> cast keccak "hola"
}
```

- `todo` (definido en `pasos.sh`) imprime `TODO: Paso N` y sale con error.
- `test.sh` ejecuta cada paso y compara la salida con la esperada.

Para ambos: los **tests van escritos** y son el contrato del ejercicio. Cada paso del
README: `## Paso N: título` → **Por qué** → código → **Abre** el archivo → **Verifica**
con el comando exacto y la salida esperada (qué tests pasan, cuáles siguen en rojo y
por qué).

## 3-proyecto

Cada semana añade una capa al **mismo protocolo** del aprendiz (hilo conductor:
[`docs/proyecto-hilo-conductor.md`](../docs/proyecto-hilo-conductor.md)). El starter
usa `// TODO:` con la firma esperada y una pista, sobre un recurso genérico `Item` que
el aprendiz adapta a su dominio. **El dominio lo asigna el instructor**; el catálogo no
vive en este repo.

El README del proyecto incluye: capa que se añade y por qué ahora, requisitos
verificables, cómo verificar (`forge test`, salida esperada), criterios de calidad no
automatizables y ejemplos de adaptación para tres dominios genéricos (biblioteca,
tienda en línea, cine — los que el instructor no asigna).

La solución de referencia del proyecto **no va en este repo**: vive en el repo privado
`ergrato-dev/bc-instructor`, en `bc-smartcontracts/week-NN-slug/3-proyecto/` (el
proyecto completo, mismo árbol que el starter).

## 4-recursos y 5-glosario

- `ebooks-free/`: tabla `Título | Formato | Descripción | Enlace`. Solo gratuitos y legales.
- `videografia/`: tabla `Título | Canal | Duración | Enlace`. Mínimo 3; español si hay de calidad.
- `webgrafia/`: tabla `Recurso | Descripción`. Documentación oficial primero.
- Cada recurso lleva una línea de por qué vale la pena. Enlaces comprobados.
- Glosario: tabla `Término | Definición | Ejemplo`, A-Z, términos **nuevos** de la
  semana, término en español con el inglés entre paréntesis cuando exista.

## Convenciones de código

- **Nomenclatura técnica en inglés**: contratos, funciones, variables, archivos `.sol`,
  scripts, commits. Strings que ve el usuario y comentarios: español.
- Estilo oficial de Solidity (4 espacios, `PascalCase` para contratos, eventos, errores y
  structs; `camelCase` para funciones y variables; `SCREAMING_SNAKE_CASE` para
  `constant`/`immutable`; `forge fmt` como árbitro). Tests: `test_Nombre`,
  `testFuzz_Nombre`, `test_RevertWhen_Condicion`.
- `pragma solidity 0.8.38;` exacto, nunca `^`, y `// SPDX-License-Identifier: MIT`.
- Comentarios de documentación: **¿Qué? ¿Para qué? ¿Impacto?** donde aporten (contratos,
  `foundry.toml`, Dockerfiles, scripts, decisiones no obvias). NatSpec (`@notice`,
  `@dev`, `@param`) desde la semana 04 en funciones públicas. Nunca repitas un
  comentario que ya dijo lo mismo más arriba; nunca comentes lo que el código ya dice.
- Herramientas: **Docker** con base `ubuntu:24.04`; **PostgreSQL** como única base de
  datos relacional (nunca MySQL); **pnpm** para todo lo de Node (nunca npm, ni `npx`:
  `pnpm dlx`); **uv** para todo lo de Python (nunca pip).

## Escritura

- Español neutro con **tuteo**: tú, tienes, puedes, haz, mira. **Nunca voseo**
  (vos, tenés, podés, hacé, mirá).
- Directo y sin relleno. El porqué antes del cómo.
- Un término inglés se escribe en inglés cuando es nombre técnico (`gas`, `nonce`,
  `storage`); la primera vez lleva su explicación en español.

## Navegación

Todo `.md` dentro de `bootcamp/` termina con una tabla de navegación:

```markdown
---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 01 — Hash](01-hash.md) | **Teoría 02 — Claves** | [Teoría 03 — Firmas →](03-firmas.md) |
```

Orden de lectura dentro de una semana: README → teorías → ejercicios → proyecto →
rúbrica → recursos (ebooks, videos, web) → glosario → README de la semana siguiente.
En los extremos se usa `—`. El README de la semana añade debajo de la tabla
`← [Volver al índice del bootcamp](../README.md)`.

Índice `bootcamp/README.md`: una semana publicada enlaza número y título
(`| [01](week-01-slug/README.md) | [Tema](week-01-slug/README.md) | ✅ |`); una sin
publicar, sin enlace y con ⬜.

## Diagramas SVG

Los que pida el contenido, ni uno más ni uno menos. Un diagrama entra cuando muestra lo
que el texto no puede (un flujo con ramas, capas, memoria, una secuencia en el tiempo);
sobra si es una lista con cajas o repite el bloque de código de al lado.

- `viewBox` obligatorio, sin `width`/`height` en la raíz; `role="img"`, `aria-label` y
  `<title>` como primer hijo.
- `<rect>` de fondo `#0d1117` que cubre el `viewBox`. **Sin degradados**, sin
  `foreignObject`, sin fuentes externas, texto ≥ 12 px.
- Prosa: `font-family="Inter, system-ui, -apple-system, 'Segoe UI', sans-serif"`.
  Código y hex: `ui-monospace, SFMono-Regular, Menlo, monospace`.
- Cada SVG se enlaza desde la teoría donde aparece su concepto
  (`![texto alternativo que describe lo que muestra](../0-assets/NN-nombre.svg)`).
  Nunca ASCII art, nunca capturas, nunca Mermaid.

| Rol | Hex |
| --- | --- |
| Lienzo | `#0d1117` |
| Superficie | `#161b22` |
| Borde | `#30363d` |
| Texto principal | `#f0f6fc` |
| Texto secundario | `#8b949e` |
| Acento Ethereum (elemento principal) | `#627eea` / claro `#8fa4f0` |
| Azul (flujo, entrada) | `#58a6ff` |
| Verde (éxito) | `#3fb950` |
| Amarillo (aviso, gas) | `#e3b341` |
| Rojo (error, ataque) | `#f85149` |
| Naranja (EVM, bytes) | `#f0883e` |

## Rúbrica

Tres evidencias, **mínimo 70 % en cada una**: 🧠 Conocimiento 30 % (10 preguntas que
piden el porqué, con respuestas plegadas), 💪 Desempeño 40 % (ejercicios, verificados
por sus tests), 📦 Producto 30 % (proyecto: tests + calidad). Bandas: Sobresaliente
90-100, Notable 80-89, Aprobado 70-79.

## Checklist de publicación de una semana

- [ ] Tests de ejercicios y proyecto escritos antes del contenido
- [ ] `./scripts/compilar-starters.sh week-NN` en verde (starters fallan; resueltos pasan)
- [ ] `./scripts/verificar-enlaces.sh` en verde
- [ ] Sin voseo, sin `npm`/`pip`/MySQL, sin `solution/`, sin `docs/dominios.md`, sin claves reales
- [ ] Solución del proyecto en `bc-instructor/bc-smartcontracts/week-NN-slug/3-proyecto/`
- [ ] Índice `bootcamp/README.md` actualizado (✅ + enlaces)
- [ ] Commit `feat(week-NN): ...` y push
