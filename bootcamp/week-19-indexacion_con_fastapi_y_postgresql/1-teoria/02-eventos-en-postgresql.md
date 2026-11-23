# Teoría 02 — Eventos en PostgreSQL

## 🎯 Objetivos

- Arrancar un PostgreSQL dentro del contenedor y hablar con él con `psql` y con psycopg.
- Diseñar tablas para eventos: tipos que caben, clave primaria y claves foráneas.
- Escribir de forma idempotente con `ON CONFLICT DO NOTHING`.
- Agrupar escrituras en una transacción de todo o nada.
- Pasar valores a una consulta sin abrir la puerta a la inyección SQL.

## 1. Qué problema resuelve

El indexador necesita guardar lo que lee para que la API lo consulte deprisa: filtrar por
cuenta, ordenar, contar, paginar. Eso es lo que hace una **base de datos relacional**: guarda
datos en **tablas** (filas y columnas con tipo) y los consulta con **SQL**. El bootcamp usa
**PostgreSQL**, que tiene un tipo numérico con hasta 131 072 dígitos, transacciones de verdad y
restricciones que la propia base de datos hace cumplir.

Tres cosas hacen que un indexador sea correcto, y las tres las resuelve el diseño de las tablas:

- **Ningún valor se recorta.** Un `uint256` tiene hasta 78 dígitos decimales.
- **Guardar dos veces lo mismo no duplica nada.** El indexador se para, se reinicia, repite un
  tramo: el resultado tiene que ser el mismo.
- **Nunca queda nada a medias.** Si el nodo deja de responder a mitad de un tramo, o se guarda el
  tramo entero o no se guarda nada.

## 2. Cómo funciona

- **Tipos.** `BIGINT` es un entero de 64 bits, hasta 9 223 372 036 854 775 807: sirve para
  números de bloque, no para importes. `NUMERIC(78, 0)` guarda enteros exactos de hasta 78
  dígitos: cabe cualquier `uint256`. `TEXT` guarda texto UTF-8. Las direcciones y los hashes se
  guardan como `TEXT` en minúsculas, para compararlos sin sorpresas.
- **Clave primaria** (*primary key*): la columna o columnas que identifican cada fila. Dos filas
  con la misma clave no pueden existir. Para un log, `(block_number, log_index)`.
- **Clave foránea** (*foreign key*): una columna que tiene que apuntar a una fila de otra tabla.
  Con `ON DELETE CASCADE`, borrar la fila apuntada borra las que la apuntan; con
  `ON DELETE SET NULL`, las deja con la columna vacía. Lo usarás para deshacer reorgs: borrar un
  bloque borra lo que pasó en él.
- **Transacción**: un grupo de sentencias que se aplica entero o no se aplica. Si una falla, la
  base de datos deshace las anteriores del grupo (*rollback*).
- **Autocommit**: con psycopg, la conexión en `autocommit=True` guarda cada sentencia al
  momento. `with conn.transaction():` abre una transacción hasta el final del bloque: si el
  bloque lanza una excepción, todo lo de dentro se deshace.
- **psycopg** es el conector de PostgreSQL para Python. `conn.execute(sql, valores)` envía la
  consulta y los valores **por separado**: los `%s` del SQL no se sustituyen como texto, los
  rellena el servidor.

## 3. Cómo se escribe

### Arrancar PostgreSQL en el contenedor

Dentro del contenedor (en cualquier starter de esta semana), sin servicio de sistema ni
contraseña:

```bash
export PGDATA=$(mktemp -d)
initdb --auth=trust --username=postgres >/dev/null
pg_ctl --options "-k /tmp -c listen_addresses=''" --log "$PGDATA/log" --wait start
```

```text
waiting for server to start.... done
server started
```

- `initdb` crea una base de datos vacía en una carpeta temporal del contenedor: al salir del
  contenedor desaparece.
- `-k /tmp` y `listen_addresses=''` hacen que solo acepte conexiones por un archivo de `/tmp`
  (un *socket*), nunca por la red. Con `--auth=trust` no pide contraseña: aceptable solo porque
  nada de fuera puede llegar.
- `psql -h /tmp -U postgres` abre la consola de SQL. `\dt` lista las tablas y `\q` sale.

Es lo que hace `test.sh` antes de los tests. Lo paras con `pg_ctl --mode fast stop`.

### Las tablas

Guarda esto en `/tmp/a.sql` y ejecútalo con `psql -h /tmp -U postgres -f /tmp/a.sql`:

```sql
CREATE TABLE blocks (
    number BIGINT PRIMARY KEY,
    hash TEXT NOT NULL
);
CREATE TABLE transfers (
    block_number BIGINT NOT NULL REFERENCES blocks (number) ON DELETE CASCADE,
    log_index INTEGER NOT NULL,
    sender TEXT NOT NULL,
    recipient TEXT NOT NULL,
    value NUMERIC(78, 0) NOT NULL,
    PRIMARY KEY (block_number, log_index)
);
INSERT INTO blocks VALUES (2, '0x97b4');
INSERT INTO transfers VALUES (2, 0, '0xf39f', '0x7099', 100000000000000000000);
INSERT INTO transfers VALUES (2, 0, '0xf39f', '0x7099', 100000000000000000000);
INSERT INTO transfers VALUES (2, 0, '0xf39f', '0x7099', 100000000000000000000) ON CONFLICT DO NOTHING;
INSERT INTO transfers VALUES (3, 0, '0xf39f', '0x3c44', 50000000000000000000);
SELECT * FROM transfers;
DELETE FROM blocks WHERE number = 2;
SELECT COUNT(*) FROM transfers;
```

```text
CREATE TABLE
CREATE TABLE
INSERT 0 1
INSERT 0 1
psql:/tmp/a.sql:15: ERROR:  duplicate key value violates unique constraint "transfers_pkey"
DETAIL:  Key (block_number, log_index)=(2, 0) already exists.
INSERT 0 0
psql:/tmp/a.sql:17: ERROR:  insert or update on table "transfers" violates foreign key constraint "transfers_block_number_fkey"
DETAIL:  Key (block_number)=(3) is not present in table "blocks".
 block_number | log_index | sender | recipient |         value
--------------+-----------+--------+-----------+-----------------------
            2 |         0 | 0xf39f | 0x7099    | 100000000000000000000
(1 row)

DELETE 1
 count
-------
     0
(1 row)
```

- `INSERT 0 1` es "una fila nueva". El segundo `INSERT` del mismo log falla con la clave
  primaria: así la base de datos te protege de contar dos veces una transferencia.
- Con `ON CONFLICT DO NOTHING`, el mismo `INSERT` da `INSERT 0 0`: ninguna fila nueva y ningún
  error. Es la escritura **idempotente**: repetirla deja lo mismo.
- La transferencia del bloque 3 no entra: el bloque 3 no está en `blocks`.
- Al borrar el bloque 2, su transferencia se borra con él (`ON DELETE CASCADE`).

### Desde Python, con valores aparte y en una transacción

Crea `demo_db.py` en el starter del ejercicio 02 y ejecútalo con `uv run python demo_db.py`:

```python
import psycopg

with psycopg.connect("host=/tmp user=postgres", autocommit=True) as conn:
    conn.execute("DROP TABLE IF EXISTS transfers")
    conn.execute("CREATE TABLE transfers (sender TEXT NOT NULL, value NUMERIC(78, 0) NOT NULL)")
    conn.execute("INSERT INTO transfers VALUES ('0xaa', 5), ('0xbb', 7), ('0xcc', %s)", [2**256 - 1])
    print(conn.execute("SELECT value FROM transfers WHERE sender = '0xcc'").fetchone())

    account = "x' OR '1'='1"
    # ❌ El texto se pega dentro del SQL
    print(conn.execute(f"SELECT COUNT(*) FROM transfers WHERE sender = '{account}'").fetchone())
    # ✅ El valor viaja aparte
    print(conn.execute("SELECT COUNT(*) FROM transfers WHERE sender = %s", [account]).fetchone())

    try:
        with conn.transaction():
            conn.execute("INSERT INTO transfers VALUES ('0xdd', 1)")
            conn.execute("INSERT INTO transfers VALUES (NULL, 1)")
    except psycopg.Error as e:
        print(type(e).__name__, "-", e.diag.message_primary)
    print(conn.execute("SELECT COUNT(*) FROM transfers").fetchone())
```

```text
(Decimal('115792089237316195423570985008687907853269984665640564039457584007913129639935'),)
(3,)
(0,)
NotNullViolation - null value in column "sender" of relation "transfers" violates not-null constraint
(3,)
```

- El `uint256` más grande entra y sale exacto. psycopg lo devuelve como `Decimal`; `int(...)`
  lo convierte en entero de Python.
- Con la f-string, el texto `x' OR '1'='1` cierra la comilla y añade una condición que siempre
  se cumple: la consulta cuenta las 3 filas. Con `%s`, el servidor busca una cuenta que se
  llama literalmente así: 0.
- Dentro de la transacción, el primer `INSERT` funcionó y el segundo falló. Al salir con la
  excepción, psycopg deshizo los dos: siguen siendo 3 filas, no 4.

## 4. Antipatrones y riesgos

- **SQL con f-strings o `+`.** Es **inyección SQL**: quien controla el texto controla la
  consulta. Las etiquetas del registro y las direcciones de la URL las escribe cualquiera. Todo
  valor va con `%s` (o `%(nombre)s`); en f-string solo van nombres que escribiste tú.
- **`BIGINT` o `float` para importes.** `BIGINT` rechaza un `uint256` grande:

  ```sql
  -- ❌ ERROR:  bigint out of range
  INSERT INTO t VALUES (115792089237316195423570985008687907853269984665640564039457584007913129639935);
  ```

  Y un `float` lo redondea sin avisar: los saldos dejan de cuadrar. `NUMERIC(78, 0)`.
- **Insertar sin clave primaria.** Sin ella, el tramo repetido tras un reinicio duplica filas y
  los saldos salen dobles. La clave de un log es `(block_number, log_index)`.
- **Guardar a medias.** Sin transacción, un fallo a mitad de tramo deja unas filas sí y otras
  no, y el cursor no sabe dónde seguir. El tramo entero, cursor incluido, va en una
  transacción.
- **Confiar en el texto de un evento.** PostgreSQL no admite el byte 0x00 en `TEXT`, y
  cualquiera puede registrar una etiqueta con ese byte. Guardarla tal cual lanza
  `psycopg.DataError: PostgreSQL text fields cannot contain NUL (0x00) bytes`: el indexador
  falla en ese bloque en cada vuelta y no avanza más. Limpia el texto antes de guardarlo.

## 5. Trucos

- `\d transfers` en `psql` enseña las columnas, la clave primaria y las claves foráneas de una
  tabla.
- Un filtro que se usa mucho (`WHERE registrant = ...`) va más rápido con un índice:
  `CREATE INDEX ON items (registrant)`. Con pocos miles de filas no se nota; con millones, sí.
- `SUM(value) FILTER (WHERE recipient = %s)` suma solo las filas que cumplen la condición: dos
  sumas distintas en una consulta.
- `COALESCE(x, 0)` cambia un `NULL` por 0: `SUM` de ninguna fila da `NULL`, no 0.

## ✅ Checklist

- [ ] Arranco PostgreSQL en el contenedor y me conecto con `psql` y con psycopg.
- [ ] Elijo `NUMERIC(78, 0)` para un `uint256` y sé qué pasa con `BIGINT`.
- [ ] Sé qué protege la clave primaria de un log y qué hace `ON CONFLICT DO NOTHING`.
- [ ] Uso `ON DELETE CASCADE` y sé qué borra.
- [ ] Agrupo un tramo en `with conn.transaction():` y sé qué se deshace si falla.
- [ ] Paso cada valor con `%s`, nunca dentro del texto del SQL.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 01 — Por qué indexar](01-por-que-indexar.md) | **Teoría 02 — Eventos en PostgreSQL** | [Teoría 03 — Una API con FastAPI →](03-una-api-con-fastapi.md) |
