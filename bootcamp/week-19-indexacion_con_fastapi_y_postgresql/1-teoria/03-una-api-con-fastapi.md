# Teoría 03 — Una API con FastAPI

## 🎯 Objetivos

- Escribir rutas de FastAPI con parámetros de ruta y de consulta validados.
- Describir la respuesta con modelos de Pydantic y saber por qué un `uint256` viaja como texto.
- Pasar a cada ruta su conexión a la base de datos con `Depends`.
- Arrancar la API con uvicorn, abrir su documentación y probarla con `TestClient`.
- Decidir qué páginas pueden leer la API desde el navegador (CORS).

## 1. Qué problema resuelve

La base de datos del indexador no se expone a internet: quien tuviera acceso a PostgreSQL podría
leer o borrar cualquier cosa. La página habla con una **API HTTP**: unas pocas rutas fijas, de
solo lectura, que hacen consultas que escribiste tú y devuelven **JSON**. Cada ruta decide qué
parámetros acepta, con qué límites, y qué forma tiene la respuesta.

**FastAPI** es un framework de Python para escribir esas APIs. Lees los tipos de los
parámetros de la función y FastAPI hace el resto: convierte, valida, rechaza lo que no encaja
y genera la documentación. **uvicorn** es el servidor que la ejecuta.

## 2. Cómo funciona

- Una **ruta** es una función con un decorador: `@app.get("/items/{item_id}")`. Lo que va entre
  llaves es un **parámetro de ruta**; el resto de parámetros de la función son **de consulta**
  (`/items?limit=20`).
- El tipo de cada parámetro es su contrato. `limit: int` acepta `20` y rechaza `veinte`. Con
  `Annotated[int, Query(ge=1, le=100)]` además exige un valor entre 1 y 100, y con
  `Path(pattern="^0x[0-9a-fA-F]{40}$")`, una dirección. Lo que no cumple recibe **422** sin que
  tu función llegue a ejecutarse.
- **Pydantic** es la biblioteca de modelos de datos que usa FastAPI. Una clase que hereda de
  `BaseModel` declara los campos de la respuesta; el tipo de retorno de la ruta (`-> Item`)
  dice a FastAPI que la valide y la convierta en JSON. Un campo que no está en el modelo no sale.
- **`Depends`** es la inyección de dependencias de FastAPI: declaras que una ruta necesita una
  conexión (`conn: Conn`), y FastAPI llama a la función que la crea antes de la ruta y la
  cierra después de responder.
- **`HTTPException(status_code=404, detail=...)`** corta la ruta con ese código. Una excepción
  cualquiera da **500** y el texto `Internal Server Error`: el detalle se queda en el log del
  servidor, no llega al cliente.
- **CORS** (*Cross-Origin Resource Sharing*): el navegador no deja que una página lea la
  respuesta de otro origen (otro dominio o puerto) salvo que esa respuesta lo permita con la
  cabecera `access-control-allow-origin`. Tu página corre en `http://localhost:5173` y la API en
  `http://localhost:8000`: son orígenes distintos.

## 3. Cómo se escribe

Crea `demo_api.py` en el starter del ejercicio 03:

```python
from typing import Annotated

from fastapi import FastAPI, Path
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI(title="Demo")
app.add_middleware(CORSMiddleware, allow_origins=["http://localhost:5173"], allow_methods=["GET"])


@app.get("/boom")
def boom() -> dict:
    raise RuntimeError("password=secreto")


class Balance(BaseModel):
    account: str
    balance: str


@app.get("/balances/{account}")
def balance(account: Annotated[str, Path(pattern="^0x[0-9a-fA-F]{40}$")]) -> Balance:
    return Balance(account=account.lower(), balance=str(100 * 10**18))
```

Para llegar a la API desde tu navegador, el contenedor tiene que publicar el puerto 8000.
Entra así y arranca uvicorn escuchando en todas las interfaces:

```bash
docker run --rm -it -p 8000:8000 -v "$PWD":/workspace bc-smartcontracts-dev
uv sync
uv run uvicorn demo_api:app --host 0.0.0.0 --port 8000
```

```text
INFO:     Started server process [48]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

`demo_api:app` es "el objeto `app` del módulo `demo_api`". Desde otra terminal de tu máquina:

```bash
curl -s localhost:8000/balances/0x70997970C51812dc3A010C7d01b50e0d17dc79C8
curl -s -w ' %{http_code}' localhost:8000/balances/hola
```

```text
{"account":"0x70997970c51812dc3a010c7d01b50e0d17dc79c8","balance":"100000000000000000000"}
{"detail":[{"type":"string_pattern_mismatch","loc":["path","account"],"msg":"String should match pattern '^0x[0-9a-fA-F]{40}$'","input":"hola","ctx":{"pattern":"^0x[0-9a-fA-F]{40}$"}}]} 422
```

- La primera respuesta sale del modelo `Balance`: los dos campos, en JSON.
- `hola` no cumple el patrón: 422, con el parámetro (`["path","account"]`) y el motivo. La
  función no se ejecutó.
- Abre `http://localhost:8000/docs`: FastAPI genera la documentación de cada ruta con sus
  parámetros y su modelo, y deja probarlas desde el navegador.

Y `curl -s localhost:8000/boom` responde `Internal Server Error` con código 500. El
`password=secreto` del error solo aparece en la terminal de uvicorn, en el *traceback*.

### Por qué el saldo es texto

JSON tiene un solo tipo de número, y JavaScript lo lee como `double`: enteros exactos solo hasta
2⁵³. En el contenedor:

```bash
node -e 'console.log(JSON.parse("{\"balance\": 100000000000000000001}").balance, JSON.parse("{\"balance\": \"100000000000000000001\"}").balance, BigInt("100000000000000000001"))'
```

```text
100000000000000000000 100000000000000000001 100000000000000000001n
```

Como número, el 1 del final se pierde sin error. Como texto llega entero, y la página lo
convierte con `BigInt(...)`, el tipo que usan viem y wagmi. Por eso todo `uint256` sale de la
API como `str`.

### CORS

Con la API en marcha, pide lo que pide el navegador antes de leer desde otra página (la
petición previa, o *preflight*, con `OPTIONS`):

```bash
curl -s -i -X OPTIONS localhost:8000/balances/x -H 'Origin: http://localhost:5173' -H 'Access-Control-Request-Method: GET'
curl -s -i -X OPTIONS localhost:8000/balances/x -H 'Origin: https://evil.example' -H 'Access-Control-Request-Method: GET'
```

La primera devuelve `HTTP/1.1 200 OK` con `access-control-allow-origin: http://localhost:5173`.
La segunda, `HTTP/1.1 400 Bad Request` y `Disallowed CORS origin`: el navegador de quien visite
`evil.example` no dejará que esa página lea tu API.

CORS lo aplica el **navegador**, no el servidor: un `GET` normal desde `evil.example` recibe
`200 OK`, pero sin la cabecera, y el navegador oculta la respuesta a la página. `curl` y
cualquier programa la leen igual. CORS no protege datos; decide qué páginas pueden usar tu API
desde el navegador de otra persona. Tu API es de solo lectura sobre datos públicos de la cadena:
nada que no esté ya en un explorador de bloques.

### Probar sin servidor

`TestClient` llama a la aplicación directamente, sin uvicorn ni puertos:

```python
from fastapi.testclient import TestClient

from demo_api import app

client = TestClient(app)
assert client.get("/balances/hola").status_code == 422
```

Es lo que usan los tests del ejercicio 03 y del proyecto.

## 4. Antipatrones y riesgos

- **Listas sin límite.** `/items` sin `limit` máximo devuelve la tabla entera: con unos miles
  de altas, cada petición tarda segundos y unas cuantas a la vez tumban la API. `le=100` y
  paginación con `offset`.
- **Números grandes en JSON.** Un `uint256` como número llega redondeado a JavaScript, sin
  error. Como texto.
- **Pasar a SQL lo que llega por la URL.** La validación de FastAPI reduce lo que entra (una
  dirección es `0x` y 40 caracteres hexadecimales), pero no sustituye a `%s`: las dos cosas.
  Y si el cliente elige el orden (`?sort=label`), compara con una lista de columnas permitidas:
  un nombre de columna no puede ir en `%s`.
- **`allow_origins=["*"]`.** Cualquier página puede usar tu API desde el navegador de quien la
  visite. Para una API pública de solo lectura puede valer; ponlo solo si lo decides, nunca
  porque "así funciona".
- **Errores con detalles.** Devolver `str(e)` en la respuesta enseña consultas, rutas y, a
  veces, credenciales. Que FastAPI responda 500 genérico y el detalle vaya al log.
- **Exponer PostgreSQL.** Publicar el puerto 5432 con una base de datos `trust` da a cualquiera
  de tu red acceso total. La API es la única puerta.

## 5. Trucos

- `uv run uvicorn api:app --app-dir src --reload` vuelve a cargar la API al guardar un archivo.
- La respuesta de `/docs` sale del esquema **OpenAPI** que FastAPI publica en `/openapi.json`:
  hay herramientas que generan con él un cliente tipado para TypeScript.
- Una ruta síncrona (`def`) se ejecuta en un hilo aparte: psycopg síncrono no bloquea al
  resto de peticiones.
- `response.json()` de `TestClient` devuelve el JSON ya convertido en diccionarios y listas de
  Python, listo para comparar con `==`.

## ✅ Checklist

- [ ] Escribo una ruta con parámetros de ruta y de consulta, con límites.
- [ ] Sé cuándo FastAPI responde 422, 404 y 500, y qué ve el cliente en cada caso.
- [ ] Describo la respuesta con un modelo de Pydantic y saco los `uint256` como texto.
- [ ] Paso la conexión con `Depends` y sé cuándo se cierra.
- [ ] Configuro CORS para mi página y sé qué protege y qué no.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 02 — Eventos en PostgreSQL](02-eventos-en-postgresql.md) | **Teoría 03 — Una API con FastAPI** | [Teoría 04 — Reorgs y confirmaciones →](04-reorgs-y-confirmaciones.md) |
