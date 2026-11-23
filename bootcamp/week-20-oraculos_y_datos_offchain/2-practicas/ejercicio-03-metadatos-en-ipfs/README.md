# Ejercicio 03 — Metadatos en IPFS

> Al terminar tendrás la imagen de un certificado y su metadata ERC-721 en un nodo de IPFS
> propio: sabrás calcular el CID a mano, apuntar la metadata a la imagen por su CID y leer un
> archivo de una carpeta por su ruta, como hace un `tokenURI`.

**Duración estimada**: 1 h 30 min
**Prerrequisitos**: [Teoría 04 — IPFS y metadatos](../../1-teoria/04-ipfs-y-metadatos.md) leída.

## Contexto

Ejercicio de terminal, como los de las semanas 01 y 02: cada paso es una función de `pasos.sh`
y `test.sh` compara su salida con la esperada.

| Archivo | Qué es |
| ------- | ------ |
| `pasos.sh` | Los cinco pasos. Aquí trabajas |
| `certificado.svg` | La imagen del certificado. **No la modifiques**: otro byte es otro CID |
| `test.sh` | Los tests. **No lo modifiques** |

`test.sh` crea un repositorio de IPFS vacío en una carpeta temporal (`IPFS_PATH`) para cada
ejecución: no necesita red ni daemon, y no toca tu `~/.ipfs`.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-20-oraculos_y_datos_offchain/2-practicas/ejercicio-03-metadatos-en-ipfs/starter
docker run --rm -it -p 8080:8080 -v "$PWD":/workspace bc-smartcontracts-dev
bash test.sh
```

**Verifica**: los cinco pasos en ❌ con `obtenido: TODO: Paso N`, y `0 de 5 pasos correctos`.

Para probar un paso a mano, crea antes tu propio repositorio (una vez por contenedor):

```bash
export IPFS_PATH=$(mktemp -d)
ipfs init >/dev/null
bash pasos.sh 1
```

## Paso 1: El CID de la imagen

**Por qué**: el CID es lo que irá en la metadata. Se puede calcular sin guardar nada: depende
solo de los bytes.

```bash
ipfs add --only-hash --cid-version 1 --quiet certificado.svg
```

**Abre** `pasos.sh`, borra el `todo` de `step1` y descomenta su línea. Ejecuta `bash test.sh`.

**Verifica**: `✅ Paso 1`, con el CID `bafkreih7elkzkshno6aj22ct5xuv2sdgxmjyehakqpqegyc6hbeppri6zy`.

## Paso 2: El mismo CID, a mano

**Por qué**: un CID no es un número que da IPFS; es el sha256 del archivo con cuatro bytes
delante. Calcularlo tú lo demuestra.

```bash
local digest
digest=$(sha256sum certificado.svg | cut -d ' ' -f 1)
python3 -c 'import base64, sys; print("b" + base64.b32encode(bytes.fromhex("01551220" + sys.argv[1])).decode().lower().rstrip("="))' "$digest"
```

- `01551220`: versión 1, códec `raw`, hash sha2-256 y longitud de 32 bytes (teoría 04).
- `base32` en minúsculas y sin el relleno `=`, con la `b` delante que dice qué base es.

**Verifica**: `✅ Paso 2`, el mismo CID que el paso 1. Prueba a cambiar `01551220` por
`01701220` (códec `dag-pb`): sale `bafybeih7elkzkshno6aj22ct5xuv2sdgxmjyehakqpqegyc6hbeppri6zy`,
con el mismo hash. Guardada la imagen (`ipfs add --cid-version 1 certificado.svg`),
`ipfs cat` de ese CID falla con `Error: protobuf: (PBNode) invalid wireType, expected 2, got 4`:
el códec dice que los bytes son un bloque índice, y no lo son. Déjalo como estaba.

## Paso 3: La metadata

**Por qué**: el `tokenURI` de un ERC-721 devuelve este JSON. Su `image` apunta a la imagen por
su CID, así que nadie la puede cambiar sin cambiar la metadata.

```bash
jq -nc --arg id "${1:-1}" --arg image "ipfs://$(step1)" \
  '{name: "Certificado #\($id)", description: "Certificado de un recurso del protocolo", image: $image}'
```

- `--arg` pasa valores a jq como texto: comillas o barras en el id no rompen el JSON.
- `-c` lo deja en una línea; `"\($id)"` mete el id en el texto.

**Verifica**: `✅ Paso 3`:

```text
{"name":"Certificado #1","description":"Certificado de un recurso del protocolo","image":"ipfs://bafkreih7elkzkshno6aj22ct5xuv2sdgxmjyehakqpqegyc6hbeppri6zy"}
```

## Paso 4: Una carpeta en tu nodo

**Por qué**: una colección sube una carpeta con un JSON por token; el contrato guarda solo el
CID de la carpeta.

```bash
rm -rf metadata && mkdir metadata
for id in 1 2; do step3 "$id" > "metadata/$id.json"; done
ipfs add --recursive --cid-version 1 --quiet metadata | tail -n 1
```

`ipfs add -r` imprime un CID por archivo y el de la carpeta al final. Sin `--only-hash`, los
guarda en el repositorio y los fija.

**Verifica**: `✅ Paso 4`, con `bafybeihcz6noexhgvqk2dlmdvzfmliwyejoygeclgiacwuwv2vt6yyuvzi`. Es
`bafybei` y no `bafkrei`: un bloque que lista otros, no un archivo.

## Paso 5: Leer por la ruta

**Por qué**: un `tokenURI` es `ipfs://<CID de la carpeta>/2.json`. El nodo resuelve la ruta: busca
`2.json` en la carpeta y devuelve su contenido.

```bash
ipfs cat "$(step4)/2.json"
```

**Verifica**: `5 de 5 pasos correctos`; el paso 5 imprime la metadata del certificado 2.

## Pruébalo con el gateway

En el contenedor del paso 0 (con `-p 8080:8080`) y tu `IPFS_PATH`, deja que el gateway escuche
fuera del contenedor y arráncalo sin red:

```bash
bash pasos.sh 4
ipfs add --cid-version 1 --quiet certificado.svg
ipfs config Addresses.Gateway /ip4/0.0.0.0/tcp/8080
ipfs daemon --offline > daemon.log 2>&1 &
sleep 3; curl -s http://127.0.0.1:8080/ipfs/bafybeihcz6noexhgvqk2dlmdvzfmliwyejoygeclgiacwuwv2vt6yyuvzi/1.json
```

```text
bafybeihcz6noexhgvqk2dlmdvzfmliwyejoygeclgiacwuwv2vt6yyuvzi
bafkreih7elkzkshno6aj22ct5xuv2sdgxmjyehakqpqegyc6hbeppri6zy
{"name":"Certificado #1","description":"Certificado de un recurso del protocolo","image":"ipfs://bafkreih7elkzkshno6aj22ct5xuv2sdgxmjyehakqpqegyc6hbeppri6zy"}
```

La segunda línea guarda la imagen: el paso 1 solo calculaba su CID. Abre en tu navegador
`http://127.0.0.1:8080/ipfs/bafkreih7elkzkshno6aj22ct5xuv2sdgxmjyehakqpqegyc6hbeppri6zy` y verás
el certificado. Sin ese `ipfs add`, el gateway responde `404 Not Found`: el CID existe, pero tu
nodo no tiene los bytes. Es tu nodo, sin red: en un gateway público no estará hasta que alguien
lo fije en un nodo conectado.

## Qué aprendiste

- Un CID v1 es el hash del contenido con su versión, su códec y su función hash delante.
- Con `--only-hash` sabes el CID antes de subir nada; un byte distinto es otro CID.
- La metadata apunta a la imagen por `ipfs://<CID>` y una carpeta agrupa la de toda la colección.
- Un nodo resuelve rutas dentro de una carpeta, que es lo que lee un `tokenURI`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Sorteo con VRF](../ejercicio-02-sorteo-con-vrf/README.md) | **Ejercicio 03 — Metadatos en IPFS** | [Proyecto — Tasa en dólares con un oráculo →](../../3-proyecto/README.md) |
