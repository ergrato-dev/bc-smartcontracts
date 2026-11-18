# 🛠️ Preparar el entorno

Necesitas **Docker** y **git**. Nada más: Foundry, el compilador de Solidity y la
biblioteca de tests viven dentro de un contenedor con las versiones exactas del bootcamp
([`stack-versions.md`](stack-versions.md)). Así, si un ejercicio funciona en tu máquina,
funciona en la corrección.

La semana 01 explica cada pieza paso a paso. Aquí está la referencia rápida.

## 1. Instalar Docker

- **Linux (Ubuntu/Debian)**: sigue la guía oficial
  [docs.docker.com/engine/install/ubuntu](https://docs.docker.com/engine/install/ubuntu/)
  y añade tu usuario al grupo `docker` (`sudo usermod -aG docker $USER`, cierra sesión
  y vuelve a entrar).
- **Windows**: instala WSL2 con Ubuntu 24.04 y Docker Desktop con integración WSL2.
  Trabaja siempre dentro de la terminal de Ubuntu, nunca en `C:\`.
- **macOS**: Docker Desktop.

Comprueba:

```bash
docker run --rm hello-world
```

Debe imprimir `Hello from Docker!`.

## 2. Clonar el bootcamp y construir la imagen

```bash
git clone https://github.com/ergrato-dev/bc-smartcontracts.git
cd bc-smartcontracts
docker build -t bc-smartcontracts-dev docker
```

Tarda unos minutos la primera vez. Comprueba:

```bash
docker run --rm bc-smartcontracts-dev forge --version
```

La primera línea debe ser `forge Version: 1.9.0`.

## 3. Trabajar dentro del contenedor

Desde la carpeta en la que vas a trabajar:

```bash
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
```

| Opción | ¿Qué hace? | ¿Para qué? |
| ------ | ---------- | ---------- |
| `--rm` | Borra el contenedor al salir | No acumular contenedores parados |
| `-it` | Terminal interactiva | Escribir comandos dentro |
| `-v "$PWD":/workspace` | Monta tu carpeta actual dentro | Editas con tu editor fuera; compilas dentro |

Dentro, el prompt es `ubuntu@...:/workspace$`. Para salir: `exit`.

Atajo recomendado (añádelo a tu `~/.bashrc` o `~/.zshrc`):

```bash
alias scdev='docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev'
```

Desde la semana 02 hace falta una blockchain local (`anvil`) corriendo a la vez que tu
terminal de trabajo. La semana 02 explica cómo levantarla en su propio contenedor.

## 4. Editor

Cualquier editor sirve. Recomendado: **VS Code** con la extensión *Solidity* de Nomic
Foundation (resaltado, errores en vivo, ir a la definición). Compilar y probar se hace
siempre con `forge` dentro del contenedor: es lo que cuenta en la evaluación.

## Problemas frecuentes

| Síntoma | Causa | Arreglo |
| ------- | ----- | ------- |
| `permission denied while trying to connect to the Docker daemon` | Tu usuario no está en el grupo `docker` | `sudo usermod -aG docker $USER` y vuelve a iniciar sesión |
| `Permission denied` al crear `out/` o `cache/` | La carpeta es de `root` en tu máquina | `sudo chown -R $USER: .` en tu carpeta de trabajo |
| `Source "forge-std/Test.sol" not found` | Compilaste fuera del contenedor | forge-std vive en la imagen: compila dentro |
| Archivos con dueño `root` | Lanzaste el contenedor con `--user root` | No uses `--user`; la imagen ya usa `ubuntu` (UID 1000) |
