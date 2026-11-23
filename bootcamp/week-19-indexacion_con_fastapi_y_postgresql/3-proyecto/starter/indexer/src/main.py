"""El indexador en marcha: sincroniza hasta la cabeza de la cadena y, después, cada pocos
segundos, hasta que lo paras con Ctrl+C.

Uso (dentro del contenedor, en indexer/):
    RPC_URL=... REGISTRY=0x... DATABASE_URL=... uv run python src/main.py
"""

import os
import time

import psycopg

from chain import head
from indexer import create_schema, sync

# ¿Qué? El bloque en el que desplegaste el Registry. Antes no hay nada que indexar.
# ¿Impacto? En Sepolia, empezar en 0 serían millones de bloques de logs vacíos.
START_BLOCK = int(os.environ.get("START_BLOCK", "0"))
# ¿Qué? Bloques que tienen que llegar encima de uno antes de indexarlo.
# ¿Impacto? Con 0 ves los datos al momento y deshaces más reorgs; con más, deshaces menos y
#   los datos llegan más tarde. En anvil no hay reorgs solos: 0.
CONFIRMATIONS = int(os.environ.get("CONFIRMATIONS", "0"))
INTERVAL_SECONDS = 2


def main() -> None:
    url, registry = os.environ["RPC_URL"], os.environ["REGISTRY"]
    with psycopg.connect(os.environ["DATABASE_URL"], autocommit=True) as conn:
        create_schema(conn)
        while True:
            new = sync(conn, url, registry, START_BLOCK, CONFIRMATIONS)
            last = conn.execute("SELECT MAX(number) FROM blocks").fetchone()[0]
            if new:
                print(f"Indexado hasta el bloque {last}: {new} eventos nuevos", flush=True)
            # Mientras vaya por detrás de la cadena, sigue sin esperar.
            if last is not None and last >= head(url) - CONFIRMATIONS:
                time.sleep(INTERVAL_SECONDS)


if __name__ == "__main__":
    main()
