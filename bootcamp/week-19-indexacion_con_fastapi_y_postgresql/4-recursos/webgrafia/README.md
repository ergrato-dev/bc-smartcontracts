# 🌐 Webgrafía — Semana 19

| Recurso | Descripción |
| ------- | ----------- |
| [Ethereum JSON-RPC API](https://ethereum.org/developers/docs/apis/json-rpc/) | La referencia de `eth_blockNumber`, `eth_getBlockByNumber` y `eth_getLogs`, con sus parámetros y sus etiquetas de bloque (`safe`, `finalized`) |
| [Execution API: eth_getLogs](https://ethereum.github.io/execution-apis/api/methods/eth_getLogs) | La especificación formal de los métodos, con el formato exacto de cada campo de un log |
| [ethereum.org — Proof-of-stake: finalidad](https://ethereum.org/developers/docs/consensus-mechanisms/pos/#finality) | Qué es un bloque finalizado, cuántos epochs tarda y por qué no se puede revertir |
| [Contract ABI Specification](https://docs.soliditylang.org/en/latest/abi-spec.html) | Cómo se codifican los topics y el `data` de un evento, `string` incluido |
| [uv — documentación](https://docs.astral.sh/uv/) | Proyectos, `uv.lock`, `uv sync`, `uv run` y la opción `exclude-newer` |
| [psycopg 3 — Basic module usage](https://www.psycopg.org/psycopg3/docs/basic/usage.html) | Conexiones, `execute` con parámetros, filas como diccionario y transacciones |
| [psycopg 3 — Passing parameters to SQL queries](https://www.psycopg.org/psycopg3/docs/basic/params.html) | Por qué nunca se monta el SQL con el texto de los valores, con ejemplos de lo que sale mal |
| [PostgreSQL 16 — Numeric types](https://www.postgresql.org/docs/16/datatype-numeric.html) | Los límites de `BIGINT` y la precisión de `NUMERIC` |
| [PostgreSQL 16 — Foreign keys](https://www.postgresql.org/docs/16/ddl-constraints.html#DDL-CONSTRAINTS-FK) | `ON DELETE CASCADE` y `ON DELETE SET NULL`, que deshacen un reorg |
| [FastAPI — CORS](https://fastapi.tiangolo.com/tutorial/cors/) | Cómo configura FastAPI los orígenes permitidos y qué hace la petición previa |
| [MDN — CORS](https://developer.mozilla.org/es/docs/Web/HTTP/Guides/CORS) | Qué aplica el navegador y qué no: por qué CORS no protege datos |
| [OWASP — SQL Injection Prevention](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html) | Las defensas contra la inyección SQL, empezando por las consultas parametrizadas |

Vale la pena empezar por la referencia de JSON-RPC y la especificación ABI: todo lo que el
indexador lee de la cadena está ahí, sin bibliotecas en medio.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Videografía](../videografia/README.md) | **Webgrafía** | [Glosario →](../../5-glosario/README.md) |
