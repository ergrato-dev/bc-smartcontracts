# 📖 Glosario — Semana 19

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| API HTTP | Conjunto de rutas fijas que un programa ofrece por HTTP y que responden, aquí, con JSON | `GET /items?limit=20` |
| Autocommit | Modo de una conexión en el que cada sentencia se guarda al momento, sin transacción explícita | `psycopg.connect(url, autocommit=True)` |
| Clave foránea (*foreign key*) | Columna que tiene que apuntar a una fila existente de otra tabla; decide qué pasa al borrar esa fila | `REFERENCES blocks (number) ON DELETE CASCADE` |
| Clave primaria (*primary key*) | Columna o columnas que identifican cada fila; no puede haber dos iguales | `PRIMARY KEY (block_number, log_index)` |
| Confirmaciones | Número de bloques que hay encima de uno; cuantos más, menos probable que un reorg lo alcance | `CONFIRMATIONS=3` en `main.py` |
| CORS (*Cross-Origin Resource Sharing*) | Regla del navegador: una página solo lee respuestas de otro origen si ese origen lo permite con una cabecera | `access-control-allow-origin: http://localhost:5173` |
| Cursor del indexador | El último bloque que el indexador ya guardó; la vuelta siguiente empieza en el siguiente | `SELECT MAX(number) FROM blocks` |
| Entorno virtual (*virtual environment*) | Carpeta con un Python y solo las dependencias de un proyecto, que crea `uv sync` | `.venv/` |
| FastAPI | Framework de Python para APIs HTTP que valida parámetros y respuestas a partir de sus tipos | `@app.get("/status")` |
| Finalizado (*finalized*) | Bloque que ya no puede revertirse sin que los validadores que lo votaron pierdan parte de su depósito; unos 13 minutos en Ethereum | `cast block finalized` |
| Idempotente | Operación que, repetida, deja el mismo resultado que hecha una vez | `INSERT ... ON CONFLICT DO NOTHING` |
| Indexador (*indexer*) | Programa que lee los eventos de la cadena una vez, en orden, y los guarda en una base de datos para consultarlos | `uv run python src/main.py` |
| Inyección SQL (*SQL injection*) | Ataque en el que un valor pegado dentro del SQL cambia la consulta | `f"... WHERE sender = '{account}'"` con `x' OR '1'='1` |
| Inyección de dependencias (*dependency injection*) | El framework crea lo que una función declara que necesita y se lo pasa | `conn: Annotated[Connection, Depends(get_conn)]` |
| JSON-RPC | Protocolo de los nodos de Ethereum: un `POST` con `method` y `params`, que responde `result` o `error` | `{"method": "eth_getLogs", "params": [...]}` |
| `NUMERIC(78, 0)` | Tipo de PostgreSQL para enteros exactos de hasta 78 dígitos: cabe cualquier `uint256` | `value NUMERIC(78, 0) NOT NULL` |
| Paginación (*pagination*) | Devolver una lista por trozos con un tamaño máximo y un desplazamiento | `LIMIT 20 OFFSET 40` |
| psycopg | Conector de PostgreSQL para Python; envía los valores aparte de la consulta | `conn.execute("... = %s", [account])` |
| Pydantic | Biblioteca de modelos de datos con tipos que usa FastAPI para validar y convertir en JSON | `class Item(BaseModel): id: str` |
| Reorganización (*reorg*) | Cambio de los últimos bloques de la cadena por otros: lo que había en ellos deja de existir | `evm_snapshot` + `evm_revert` en anvil |
| `safe` | Etiqueta del bloque más reciente que la mayoría de validadores ya ha votado; difícil de revertir | `cast block safe` |
| Transacción de base de datos | Grupo de sentencias que se aplica entero o no se aplica | `with conn.transaction():` |
| uv | Gestor de Python y de dependencias con lockfile, como pnpm en Node | `uv sync`, `uv run` |
| uvicorn | Servidor que ejecuta una aplicación de FastAPI | `uv run uvicorn api:app --port 8000` |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | Semana 20 (próximamente) |
