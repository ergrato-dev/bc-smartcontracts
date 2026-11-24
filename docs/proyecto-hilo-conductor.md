# 🧵 Proyecto hilo conductor

Durante 34 semanas construyes **un solo protocolo** on-chain, en el dominio que te
asigna el instructor (una red de talleres, un club deportivo, una cooperativa...). Cada
semana añade una capa; ninguna capa depende de una posterior. Al final tienes contratos
probados, auditados y desplegados en testnet y en una L2, una dApp que los usa y un
indexador con PostgreSQL: un proyecto de portfolio, no 34 ejercicios sueltos.

**El dominio lo asigna el instructor** en la semana 01. Dos aprendices de la misma
cohorte no comparten dominio, y copiar el protocolo de otro anula la entrega. Los
ejemplos del bootcamp usan biblioteca, tienda en línea y cine: esos tres no se asignan.

Nombre de tu repositorio: `bc-smartcontracts-<tu-dominio>` (por ejemplo
`bc-smartcontracts-taller`). Una rama por semana (`week-01` ... `week-34`); `main`
acumula.

## Capas por semana

| Semana | Capa que se añade | Qué existe al terminar |
| ------ | ----------------- | ---------------------- |
| 01 | Ficha criptográfica | Script que deriva la cuenta del protocolo, firma su ficha de presentación y verifica la firma |
| 02 | Primeras transacciones | Script que mueve ETH entre cuentas de anvil y lee nonce, gas y recibo de cada transacción |
| 03 | Contrato registro | Proyecto Foundry propio con el contrato que registra el recurso principal, desplegado en anvil |
| 04 | Registro configurable | Nombres `constant`, dueño y capacidad `immutable`, getters `public`, una función interna y NatSpec |
| 05 | Registro con reglas | Capacidad máxima, apertura y cierre por el dueño, altas por lotes, errores personalizados, modificadores y un `assert` |
| 06 | Registro de recursos | Un struct `Item` con estado (enum) y etiqueta, un mapping de ids, la lista de ids de cada cuenta y la retirada de recursos |
| 07 | Tasas y eventos | Alta con tasa en ETH, un evento por cada cambio de estado y la retirada segura de lo recaudado |
| 08 | Registro modular | Piezas reutilizables (dueño, apertura, validación), una interfaz pública y ERC-165 |
| 09 | Fuzzing | Siete propiedades con fuzzing, un test sobre un fork del despliegue y un `.gas-snapshot` |
| 10 | Registro conectado | Un hook que recibe cada alta sin poder bloquearla y un `multicall` |
| 11 | Token de fidelidad | Un ERC-20 que se gana con cada alta y paga un alta sin ETH |
| 12 | Certificado de recurso | Un ERC-721 por recurso con su mismo id y metadata del registro; quien lo tiene retira el recurso |
| 13 | Roles | Guardián que pausa, tesorería que retira las tasas y un timelock para la configuración |
| 14 | Órdenes firmadas | Altas firmadas con EIP-712 que envía otra cuenta, y pago con puntos por `permit` |
| 15 | Registro actualizable | El registro detrás de un proxy UUPS y una V2 que llega por actualización sin perder datos |
| 16 | Despliegue en Sepolia | Dos scripts probados que despliegan, verifican y actualizan en anvil y en Sepolia, con keystore |
| 17 | La página del protocolo | Una página con viem que lee el estado, da de alta y retira, explica los errores y sigue la actividad |
| 18 | La dApp del protocolo | La página en React y wagmi, firmada con la wallet de quien la usa, en anvil y en Sepolia |
| 19 | El indexador | Un indexador en Python que guarda altas y bajas en PostgreSQL, deshace reorgs y las sirve con FastAPI |
| 20 | Tasa en dólares | RegistryV3: la tasa en dólares, convertida a ETH con el price feed de Chainlink |
| 21 | Ataques clásicos | Cuatro atacantes con sus tests, el hallazgo H-01 corregido y el informe de auditoría abierto |
| 22 | Ataques económicos | Oráculos, flash loans, orden y redondeo revisados; H-02 corregido con la devolución del exceso |
| 23 | Análisis estático | Slither y forge lint como controles de `test.sh`, un detector propio y H-03 corregido |
| 24 | Invariantes | Invariantes con su handler en forge y Medusa, y mutantes que comprueban que atrapan fallos |
| 25 | Verificación formal | Specs de Halmos de las reglas de acceso y de cobro, con mutantes |
| 26 | Informe de auditoría | Modelo de amenazas con una prueba por amenaza y el informe completo, fijado en un commit |
| 27 | Mapa de storage | Un test que lee el storage del proxy slot a slot y detecta un layout movido |
| 28 | Assembly | La llamada al hook en assembly, que copia solo 4 bytes de su motivo de revert (H-05) |
| 29 | Optimización de gas | Un alta sin la escritura redundante, el optimizador decidido con números y el gas guardado y comprobado |
| 30 | Vault de puntos | Un vault ERC-4626 que recibe un bonus con cada alta y resiste el ataque de inflación |
| 31 | DAO | Votos con las shares del vault, un Governor, un timelock de dos días y el registro traspasado a la DAO (H-04) |
| 32 | Altas sin ETH | Una cuenta del protocolo por EIP-7702 y un paymaster de la DAO que paga la primera alta por ERC-4337 |
| 33 | Despliegue en una L2 | El registro en una L2 con un feed que mira el secuenciador y un ejecutor que solo obedece a la DAO de L1 |
| 34 | Entrega | Despliegues comprobados en L1 y en la L2, auditoría cruzada con otro aprendiz, README de portfolio, demo y `v1.0.0` |

## Reglas

- **Cada capa deja tests.** Los mínimos los nombra el `3-proyecto/README.md` de la
  semana; puedes añadir más.
- **`forge test` en verde** (o `bash test.sh` en las semanas 01-02) es el criterio de
  entrega de toda semana.
- **El starter de cada semana es autocontenido** y usa un recurso genérico `Item`. Tú
  trabajas en **tu** repositorio, con los nombres de **tu** dominio; el starter es la
  referencia de qué firmas se esperan.
- **Nunca dinero real ni claves reales.** Las cuentas de prueba de anvil son públicas;
  desde la semana 16, tu clave de testnet vive en un keystore cifrado, nunca en el repo.
- **Versionado**: antes de empezar una semana, `git switch -c week-NN` desde `main`. Al
  terminar, pull request `week-NN` → `main` en tu repositorio.
