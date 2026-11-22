# Teoría 02 — Un proyecto Foundry

## 🎯 Objetivos

- Nombrar las cuatro herramientas de Foundry y para qué sirve cada una.
- Reconocer la estructura de un proyecto: `foundry.toml`, `src/`, `test/`, `out/`.
- Compilar con `forge build` y encontrar el bytecode y la ABI en el artefacto.
- Inspeccionar un contrato compilado con `forge inspect`.

---

## 1. Qué problema resuelve

Para desarrollar un contrato necesitas compilarlo, probarlo, desplegarlo y llamarlo. Hacer
cada cosa con un programa distinto obliga a repetir configuración (qué compilador, dónde
están los archivos) y a pegar a mano bytecode y ABI de un lado a otro.

**Foundry** es un conjunto de herramientas que hacen todo eso sobre la misma carpeta y la
misma configuración. Ya usas dos:

| Herramienta | Para qué |
| ----------- | -------- |
| `forge` | Compilar, ejecutar tests y desplegar contratos |
| `cast` | Hablar con un nodo desde la terminal: leer, llamar, enviar transacciones |
| `anvil` | Nodo local de pruebas |
| `chisel` | Consola interactiva de Solidity (no se usa esta semana) |

Esta semana entra `forge`. Su documentación oficial está en
[getfoundry.sh](https://getfoundry.sh).

## 2. La estructura de un proyecto

Un proyecto Foundry es una carpeta con esta forma. Es la de los starters de los
ejercicios y la del proyecto:

```
mi-proyecto/
├── foundry.toml        # configuración
├── src/                # contratos (.sol)
│   └── Counter.sol
├── test/               # tests (.t.sol)
│   └── Counter.t.sol
├── out/                # lo compila forge build (no se versiona)
└── cache/              # caché de forge (no se versiona)
```

Las carpetas `out/` y `cache/` las genera `forge`: se pueden borrar y volver a generar.
En tu repositorio no se suben: el starter del proyecto trae un `.gitignore` que las excluye.

`forge init` crea esta estructura desde cero y descarga la biblioteca de tests
`forge-std` de GitHub. En el bootcamp no lo usas: `forge-std` ya está en la imagen y los
starters traen un `foundry.toml` preparado para encontrarla.

## 3. `foundry.toml`

**Abre** `foundry.toml` en cualquier starter de la semana:

```toml
[profile.default]
src = "src"
test = "test"
out = "out"
libs = ["/opt/lib"]
remappings = ["forge-std/=/opt/lib/forge-std/src/"]
solc_version = "0.8.38"
offline = true
```

| Clave | Qué hace |
| ----- | -------- |
| `src`, `test`, `out` | Carpetas de contratos, tests y salida |
| `libs` | Dónde buscar bibliotecas: la carpeta `/opt/lib` de la imagen |
| `remappings` | Traduce `import "forge-std/Test.sol"` a la ruta real del archivo |
| `solc_version` | El compilador que usa, el mismo que el `pragma` |
| `offline` | No descarga nada de internet: todo está en la imagen |

`[profile.default]` es el perfil que se usa si no pides otro. Un proyecto grande puede
tener varios (por ejemplo, uno para integración continua con más casos de fuzzing).

## 4. Compilar

**Dónde**: en el contenedor, dentro de la carpeta del proyecto.

```bash
forge build
```

**Salida** (en el starter del Ejercicio 03, que trae un `Counter` ya escrito):

```
Compiling 1 files with Solc 0.8.38
Solc 0.8.38 finished in 5.19ms
Compiler run successful!
```

El tiempo cambia de una máquina a otra. Si lo ejecutas otra vez sin tocar nada:

```
No files changed, compilation skipped
```

`forge` recuerda qué compiló (en `cache/`) y solo recompila lo que cambió.

## 5. El artefacto

Por cada contrato, `forge build` deja un **artefacto**: un JSON con todo lo que produjo el
compilador. Está en `out/<Archivo>.sol/<Contrato>.json`:

```bash
jq -r 'keys | join(" ")' out/Counter.sol/Counter.json
```

```
abi bytecode deployedBytecode id metadata methodIdentifiers rawMetadata
```

| Campo | Qué contiene |
| ----- | ------------ |
| `abi` | La ABI (Teoría 01) |
| `bytecode.object` | Código de creación: lo que va en la transacción de despliegue |
| `deployedBytecode.object` | Código desplegado: lo que queda en la cuenta del contrato |
| `methodIdentifiers` | Cada función con su selector |

```bash
jq -c .methodIdentifiers out/Counter.sol/Counter.json
```

```
{"get()":"6d4ce63c","increment()":"d09de08a","set(uint256)":"60fe47b1"}
```

Son los mismos que da `cast sig "increment()"`: el selector solo depende de la firma.

## 6. `forge inspect`

`forge inspect` lee el artefacto por ti y lo muestra en tabla:

```bash
forge inspect Counter abi
```

```
╭----------+------------------------------+------------╮
| Type     | Signature                    | Selector   |
+======================================================+
| function | get() view returns (uint256) | 0x6d4ce63c |
|----------+------------------------------+------------|
| function | increment() nonpayable       | 0xd09de08a |
|----------+------------------------------+------------|
| function | set(uint256) nonpayable      | 0x60fe47b1 |
╰----------+------------------------------+------------╯
```

`nonpayable` marca las funciones que pueden cambiar el estado (y que no aceptan ETH: eso
llega en la semana 07). Otros campos útiles: `forge inspect Counter bytecode`,
`forge inspect Counter storageLayout` (Teoría 03).

## 7. Antipatrones y riesgos

- **Subir `out/` y `cache/` al repositorio**: ensucian cada diff y pueden quedar
  desfasados respecto al código. Se generan; no se versionan.
- **Desplegar un artefacto viejo**: si cambias el `.sol` y despliegas sin recompilar con
  la herramienta, lo desplegado no es lo que lees. `forge create` y `forge test`
  recompilan solos; pegar bytecode a mano desde `out/` no.
- **Bibliotecas sin versión fija**: una biblioteca descargada de la rama principal puede
  cambiar mañana. En el bootcamp `forge-std` va fija en la imagen (`v1.17.0`); la semana
  11 enseña a fijar versiones con `forge install`.

## 8. Trucos

- `forge build --sizes` muestra el tamaño de cada contrato.
- `forge clean` borra lo compilado para empezar de cero.
- `forge config` imprime la configuración efectiva, útil cuando algo no encuentra un
  archivo.
- `forge --help` y `forge build --help` listan todas las opciones.

## ✅ Checklist

- [ ] Sé para qué sirven `forge`, `cast`, `anvil` y `chisel`.
- [ ] Reconozco las carpetas de un proyecto Foundry y cuáles no se versionan.
- [ ] Explico cada clave del `foundry.toml` del bootcamp.
- [ ] Encuentro bytecode, ABI y selectores en el artefacto.
- [ ] Uso `forge inspect` para ver la ABI.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 01 — Solidity y el compilador](01-solidity-y-el-compilador.md) | **Teoría 02 — Un proyecto Foundry** | [Teoría 03 — Estado y funciones →](03-estado-y-funciones.md) |
