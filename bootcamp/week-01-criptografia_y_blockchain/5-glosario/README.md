# 📖 Glosario — Semana 01

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| Avalancha, efecto (*avalanche effect*) | Propiedad de un hash: un cambio mínimo en la entrada cambia por completo la salida | `hola` y `Hola` tienen hashes sin parecido |
| Bloque (*block*) | Grupo ordenado de transacciones con una cabecera que incluye el hash del bloque anterior | El bloque 1 guarda el hash del bloque 0 |
| Blockchain | Registro replicado formado por bloques enlazados por sus hashes | Ethereum, Bitcoin |
| Byte | 8 bits: un número de 0 a 255; se escribe con dos dígitos hex | `0xff` = 255 |
| Checksum (EIP-55) | Mezcla de mayúsculas y minúsculas en una dirección que detecta errores al copiarla | `0xf39Fd6e5...` |
| Clave privada (*private key*) | Número secreto de 32 bytes que controla una cuenta | `0xac09...ff80` (de prueba) |
| Clave pública (*public key*) | 64 bytes calculados desde la clave privada; se puede compartir | `cast wallet public-key` |
| Consenso (*consensus*) | Reglas por las que los nodos acuerdan qué bloque va después | Prueba de participación |
| Contenedor (*container*) | Entorno aislado creado a partir de una imagen de Docker | `docker run --rm -it ... bc-smartcontracts-dev` |
| Dirección (*address*) | Últimos 20 bytes del keccak256 de la clave pública; identifica una cuenta | `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` |
| Doble gasto (*double spending*) | Intentar gastar el mismo saldo dos veces; se evita con un orden único de transacciones | Ana firma dos pagos de sus únicos 5 |
| EIP (*Ethereum Improvement Proposal*) | Documento que define un estándar o cambio de Ethereum | EIP-55, EIP-191 |
| EIP-191 | Estándar que antepone `\x19Ethereum Signed Message:\n<longitud>` a un mensaje antes de firmarlo | `cast hash-message "hola"` |
| EVM (*Ethereum Virtual Machine*) | Máquina que ejecuta los smart contracts en cada nodo | Cadenas EVM: Ethereum, Arbitrum, Base |
| Finalidad (*finality*) | Punto a partir del cual un bloque ya no se puede revertir | Unos 13 minutos en Ethereum |
| Firma digital (*digital signature*) | Dato que solo produce el dueño de una clave privada y que cualquiera verifica con la dirección | `cast wallet sign` |
| Foundry | Kit de herramientas para smart contracts: `forge`, `cast`, `anvil`, `chisel` | `forge --version` |
| Frase semilla (*mnemonic*) | 12 o 24 palabras (BIP-39) de las que se derivan muchas claves privadas | `test test ... junk` |
| Hash | Resultado de tamaño fijo de una función hash; huella de unos datos | `0x8aca...ae41` |
| Hexadecimal (*hex*) | Base 16 (`0-9`, `a-f`); el formato de bytes en Ethereum, con prefijo `0x` | `0x686f6c61` = `hola` |
| Imagen (*image*) | Plantilla de Docker con un sistema y herramientas instaladas | `bc-smartcontracts-dev` |
| Índice de derivación | Número que elige qué cuenta se deriva de una frase semilla | `--mnemonic-index 2` |
| keccak256 | Función hash de Ethereum; salida de 32 bytes | `cast keccak "hola"` |
| Nodo (*node*) | Ordenador que guarda una copia completa de la blockchain y verifica cada cambio | Un validador de Ethereum |
| Preimagen, resistencia a (*preimage resistance*) | Imposibilidad práctica de encontrar una entrada que produzca un hash dado | Del hash no se saca `hola` |
| Prueba de participación (*Proof of Stake*) | Consenso en el que los validadores depositan ETH como garantía | Ethereum desde 2022 |
| Prueba de trabajo (*Proof of Work*) | Consenso en el que se compite gastando cómputo | Bitcoin |
| `r`, `s`, `v` | Las tres partes de una firma de Ethereum (32 + 32 + 1 bytes) | `v = 0x1c` |
| Registro (*ledger*) | Lista ordenada de hechos aceptados como verdad | Un libro de cuentas |
| Reorganización (*reorg*) | Sustitución de bloques recientes por otra versión de la cadena | Antes de la finalidad |
| *Replay* | Reutilizar una firma válida para que algo ocurra dos veces | Cobrar dos veces con la misma autorización |
| *Salt* | Valor aleatorio secreto que se añade antes de hashear un dato predecible | `keccak256(salt + documento)` |
| secp256k1 | Curva elíptica que Ethereum y Bitcoin usan para las claves | Clave privada → clave pública |
| Slot | Intervalo de 12 segundos en el que un validador propone un bloque | Ethereum |
| Smart contract | Programa publicado en la blockchain que guarda estado y aplica reglas sin intermediarios | Un depósito en garantía |
| Transacción (*transaction*) | Orden firmada que se añade a la blockchain | "Mueve 5 de Ana a Luis" |
| UTF-8 | Codificación de texto a bytes; letras sin tilde 1 byte, `ñ` 2 | `cast from-utf8 "ñ"` → `0xc3b1` |
| Validador (*validator*) | Nodo que propone y vota bloques en prueba de participación | 32 ETH depositados |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | [Semana 02 — Ethereum: cuentas, transacciones y gas →](../../week-02-ethereum_cuentas_transacciones_y_gas/README.md) |
