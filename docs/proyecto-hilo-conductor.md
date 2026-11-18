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
| 04-10 | Lógica del protocolo | Reglas, errores, estructuras, eventos, pagos en ETH, herencia y llamadas entre contratos, con tests y fuzzing |
| 11-15 | Estándares | Token de fidelidad ERC-20, certificado o ticket ERC-721, roles, órdenes firmadas EIP-712 y versión actualizable |
| 16-20 | dApp completa | Despliegue verificado en Sepolia, frontend con wagmi, indexador FastAPI + PostgreSQL y precio desde un oráculo |
| 21-26 | Auditoría propia | Informe de auditoría del protocolo: Slither, invariantes, verificación formal y hallazgos corregidos |
| 27-33 | Avanzado | Partes críticas optimizadas en gas, vault o pool DeFi, gobernanza DAO, account abstraction y despliegue en L2 |
| 34 | Entrega | Protocolo completo, auditoría cruzada con otro aprendiz y presentación |

Las filas agrupadas se detallan al escribir cada semana.

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
