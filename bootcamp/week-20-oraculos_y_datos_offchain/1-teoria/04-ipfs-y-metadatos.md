# Teoría 04 — IPFS y metadatos

## 🎯 Objetivos

- Explicar la diferencia entre buscar un archivo por su ubicación y buscarlo por su contenido.
- Leer un CID: versión, códec y hash, y calcularlo a mano.
- Guardar archivos y carpetas en un nodo de IPFS propio, leerlos y saber cuándo desaparecen.
- Elegir entre `data:`, `ipfs://` y `https://` para el `tokenURI` de un NFT.

## 1. Qué problema resuelve

El `tokenURI` de tu certificado (semana 12) devuelve un JSON con su nombre y sus atributos,
construido en la propia cadena: `data:application/json;base64,...`. Funciona para unas pocas
líneas de texto, pero una imagen de verdad pesa kilobytes o megas, y guardarla en storage
cuesta una fortuna en gas (unos 20 000 de gas por cada 32 bytes nuevos).

La solución habitual es dejar en la cadena solo un **enlace** a la imagen. La pregunta es a
qué. Con `https://mi-servidor.com/certificado.png`:

- Si el servidor se apaga o el dominio caduca, el NFT se queda sin imagen.
- Quien controla el servidor puede cambiar la imagen cuando quiera, y el enlace no cambia: el
  NFT que compraste ya no es el que viste.

Un enlace que dice **dónde** está el archivo no dice nada de **qué** es.

## 2. Cómo funciona

### Direcciones por contenido

**IPFS** (InterPlanetary File System) es una red de nodos que guardan y sirven archivos, y que
los nombran por su contenido: el nombre de un archivo es (casi) su **hash**. Ese nombre es el
**CID** (Content IDentifier).

Dos consecuencias, las mismas que daba el hash en la semana 01:

- **El CID verifica el archivo.** Quien te lo sirve no puede darte otro: al recibirlo,
  calculas el hash y, si no coincide, lo descartas. No importa de qué nodo venga.
- **El contenido no se puede cambiar.** Cambia un byte y es otro CID. Un `tokenURI` con
  `ipfs://<CID>` apunta para siempre a los mismos bytes.

### Anatomía de un CID

```text
bafkreiath3uyskj7sjzwgajibrxrjse5kijabql5zxhmziym2idqkmzniq
```

Es una tira de bytes escrita en base32 (letras minúsculas y dígitos 2-7), con una `b` delante
que dice "base32". Los bytes son:

| Bytes | Valor | Qué dice |
| ----- | ----- | -------- |
| 1 | `0x01` | CID versión 1 |
| 1 | `0x55` | Códec `raw`: el contenido son los bytes del archivo tal cual |
| 1 | `0x12` | El hash es sha2-256 |
| 1 | `0x20` | El hash mide 32 bytes |
| 32 | sha256 del archivo | El hash en sí |

Por eso todos los CID de archivos pequeños empiezan por `bafkrei`: son los mismos cuatro bytes
de cabecera escritos en base32. El ejercicio 03 calcula uno a mano con `sha256sum` y Python y
comprueba que coincide con el de IPFS.

Verás también CID de la versión 0, que empiezan por `Qm`: son los antiguos, sin bytes de versión
ni de códec y en base58, que mezcla mayúsculas y minúsculas y no cabe en un nombre de dominio.
Usa siempre la versión 1 (`--cid-version 1`).

### Archivos grandes y carpetas

Un archivo de más de 256 KiB se parte en trozos; cada trozo tiene su CID y un bloque índice
lista los CID de los trozos. El CID del archivo es el del índice, con otro códec (`dag-pb`), y
empieza por `bafybei`. Una **carpeta** funciona igual: un bloque que lista nombres y CID. Con su
CID puedes pedir un archivo de dentro por su ruta: `<CID de la carpeta>/2.json`.

### Quién guarda los archivos

Que un archivo tenga CID no significa que esté en la red. Está en los nodos que lo guardan, y un
nodo solo guarda para siempre lo que tiene **fijado** (pinned). Lo demás lo borra la recolección
de basura (garbage collection) cuando necesita sitio. Si nadie fija tu imagen, desaparece, y
el CID sigue en tu contrato apuntando a nada.

Para que un archivo siga disponible hay tres formas, de menos a más cómoda:

1. Tu propio nodo, encendido y conectado a la red, con el archivo fijado.
2. Un **servicio de pinning**: una empresa que fija tus CID en sus nodos a cambio de una cuota.
3. Varios de ellos a la vez: el CID es el mismo en todos, y basta con que uno lo sirva.

### Gateways

Un navegador no habla IPFS. Un **gateway** es un servidor web que lo traduce: recibe
`https://<gateway>/ipfs/<CID>`, busca el contenido en la red y te lo devuelve. Wallets y
marketplaces convierten `ipfs://<CID>` en una URL de gateway para enseñar la imagen. Kubo, el
nodo que trae la imagen del bootcamp, trae el suyo en el puerto 8080.

## 3. Cómo se escribe

Todo en el contenedor. `ipfs` necesita un **repositorio** (la carpeta donde el nodo guarda sus
bloques y su configuración): `ipfs init` lo crea en `~/.ipfs`, o en la carpeta de la variable
`IPFS_PATH`.

```bash
export IPFS_PATH=$(mktemp -d)
ipfs init >/dev/null
printf 'hola\n' > hola.txt
printf 'Hola\n' > Hola.txt
```

### Calcular un CID y guardarlo

`--only-hash` calcula el CID sin guardar nada; `-Q` (`--quiet`) imprime solo el CID:

```bash
ipfs add --only-hash --cid-version 1 -Q hola.txt
ipfs add --only-hash --cid-version 1 -Q Hola.txt
```

```text
bafkreiath3uyskj7sjzwgajibrxrjse5kijabql5zxhmziym2idqkmzniq
bafkreic25k676y6sipw6bt3eaanjvzjznyjpalxlpctolwrp6vgoxhl2nm
```

Una mayúscula y es otro CID entero. Sin `--only-hash`, el archivo se guarda y se fija:

```bash
ipfs add --cid-version 1 hola.txt
ipfs cat bafkreiath3uyskj7sjzwgajibrxrjse5kijabql5zxhmziym2idqkmzniq
```

```text
added bafkreiath3uyskj7sjzwgajibrxrjse5kijabql5zxhmziym2idqkmzniq hola.txt
hola
```

Para leer las partes de un CID sin hacer la cuenta, `ipfs cid format` con `%P`:

```bash
ipfs cid format -f '%P' bafkreiath3uyskj7sjzwgajibrxrjse5kijabql5zxhmziym2idqkmzniq
```

```text
cidv1-raw-sha2-256-32
```

### Una carpeta de metadata

El estándar ERC-721 (semana 12) espera que `tokenURI(id)` devuelva un JSON con `name`,
`description` e `image`. Con OpenZeppelin, `tokenURI` concatena `_baseURI()` y el id: si
`_baseURI()` devuelve `ipfs://<CID de la carpeta>/`, el certificado 2 apunta a
`ipfs://<CID>/2`. Por eso las colecciones suben una carpeta con un JSON por token: o sin
extensión, o con `.json` y un `tokenURI` sobrescrito que la añade.

El ejercicio 03 crea `metadata/` con `1.json` y `2.json`. Subirla entera:

```bash
ipfs add -r --cid-version 1 metadata
```

```text
added bafkreiaab5qec4bwtvlhbyeglsyttwzknhqx73xrq5jzibx77uf6pre4ru metadata/1.json
added bafkreidv35oedmmw6wlvjp6sztzbo2fa26tsrybny4dqv4734iblqvpa3a metadata/2.json
added bafybeihcz6noexhgvqk2dlmdvzfmliwyejoygeclgiacwuwv2vt6yyuvzi metadata
```

La última línea es la carpeta (`bafybei`: un bloque que lista otros). Su contenido:

```bash
ipfs ls bafybeihcz6noexhgvqk2dlmdvzfmliwyejoygeclgiacwuwv2vt6yyuvzi
```

```text
bafkreiaab5qec4bwtvlhbyeglsyttwzknhqx73xrq5jzibx77uf6pre4ru 159 1.json
bafkreidv35oedmmw6wlvjp6sztzbo2fa26tsrybny4dqv4734iblqvpa3a 159 2.json
```

### Lo que no está fijado desaparece

Quita el pin de la carpeta y pasa la recolección de basura:

```bash
ipfs pin rm bafybeihcz6noexhgvqk2dlmdvzfmliwyejoygeclgiacwuwv2vt6yyuvzi
ipfs repo gc | tail -n 2
ipfs cat bafybeihcz6noexhgvqk2dlmdvzfmliwyejoygeclgiacwuwv2vt6yyuvzi/1.json --offline
```

```text
unpinned bafybeihcz6noexhgvqk2dlmdvzfmliwyejoygeclgiacwuwv2vt6yyuvzi
removed bafkreidv35oedmmw6wlvjp6sztzbo2fa26tsrybny4dqv4734iblqvpa3a
removed bafkreiaab5qec4bwtvlhbyeglsyttwzknhqx73xrq5jzibx77uf6pre4ru
Error: block was not found locally (offline): ipld: could not find bafybeihcz6noexhgvqk2dlmdvzfmliwyejoygeclgiacwuwv2vt6yyuvzi
```

El CID sigue siendo válido: si alguien vuelve a subir los mismos bytes, vuelve a funcionar.

### Tres formas de `tokenURI`

| Forma | Dónde viven los datos | Puede cambiar | Puede desaparecer |
| ----- | --------------------- | ------------- | ----------------- |
| `data:application/json;base64,...` | En la cadena | Solo si el contrato lo permite | No |
| `ipfs://<CID>` | En los nodos que lo fijan | No: otro contenido es otro CID | Sí, si nadie lo fija |
| `https://...` | En un servidor | Sí, cuando quiera su dueño | Sí |

Tu certificado combina las dos primeras sin problema: el JSON sigue en la cadena (refleja el
estado del recurso) y su campo `image` apunta a `ipfs://<CID>` de una imagen fija.

## 4. Antipatrones y riesgos

- **Un `https://` de tu servidor en el `tokenURI`.** El dueño del servidor decide qué ve cada
  poseedor y cuándo deja de verlo. Lo que se promete inmutable no puede depender de él.
- **Subir y no fijar.** Un `ipfs add` en tu portátil no publica nada: el archivo existe mientras
  tu nodo esté encendido y lo tenga. Sin pinning, la imagen se pierde.
- **Guardar en el contrato una URL de gateway** (`https://ipfs.io/ipfs/<CID>`). Ata el NFT a
  ese gateway. Guarda `ipfs://<CID>` y que cada aplicación elija el suyo.
- **Datos personales en IPFS.** Todo lo que subes es público y, una vez copiado por otros nodos,
  no se puede borrar. Nunca nombres, correos ni documentos de nadie.
- **Un `baseURI` que el dueño puede cambiar sin límite.** `setBaseURI` con `onlyOwner` vuelve a
  hacer mutable lo que IPFS hacía fijo. Si hace falta, que esté detrás del timelock y emita
  un evento.
- **SVG de terceros sin revisar.** Un SVG puede llevar `<script>`: un marketplace que lo pinte
  sin aislarlo ejecuta código ajeno. Una imagen tuya, sin scripts, no tiene ese problema.

## 5. Trucos

- `ipfs add --only-hash` te dice el CID antes de subir nada: puedes escribirlo en el despliegue
  y subir después, sabiendo que el CID será ese.
- El CID no depende del nodo, la hora ni la cuenta: dos personas que suben el mismo archivo con
  las mismas opciones obtienen el mismo CID. Es lo que permite fijarlo en varios servicios.
- `ipfs daemon --offline` arranca el gateway sin conectarse a la red: sirve lo que tienes en
  tu repositorio en `http://127.0.0.1:8080/ipfs/<CID>`.

## ✅ Checklist

- [ ] Sé por qué un enlace por contenido verifica el archivo y uno por ubicación no.
- [ ] Leo un CID v1: versión, códec, función hash, longitud y hash.
- [ ] Guardo archivos y carpetas con `ipfs add` y los leo con `ipfs cat` y `ipfs ls`.
- [ ] Sé que lo que no está fijado desaparece, y cómo mantenerlo disponible.
- [ ] Elijo entre `data:`, `ipfs://` y `https://` para un `tokenURI` según qué puede cambiar.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 03 — Aleatoriedad con VRF](03-aleatoriedad-con-vrf.md) | **Teoría 04 — IPFS y metadatos** | [Ejercicio 01 — Precio con Chainlink →](../2-practicas/ejercicio-01-precio-con-chainlink/README.md) |
