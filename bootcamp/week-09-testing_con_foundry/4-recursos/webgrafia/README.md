# 🌐 Webgrafía — Semana 09

| Recurso | Descripción |
| ------- | ----------- |
| [Foundry — Tests](https://getfoundry.sh/forge/tests/overview) y [Cheatcodes](https://getfoundry.sh/forge/tests/cheatcodes) | Oficial. Cómo ejecuta forge los tests, `setUp`, la salida y qué es un cheatcode (Teoría 01) |
| [Foundry — Referencia de cheatcodes](https://getfoundry.sh/reference/cheatcodes/overview) | Oficial. Todos los cheatcodes, uno por página: [`prank`](https://getfoundry.sh/reference/cheatcodes/prank), [`warp`](https://getfoundry.sh/reference/cheatcodes/warp), [`expectRevert`](https://getfoundry.sh/reference/cheatcodes/expect-revert), [`expectEmit`](https://getfoundry.sh/reference/cheatcodes/expect-emit), [`expectCall`](https://getfoundry.sh/reference/cheatcodes/expect-call), [`recordLogs`](https://getfoundry.sh/reference/cheatcodes/record-logs) (Teorías 01 y 02) |
| [Foundry — Fuzz Testing](https://getfoundry.sh/forge/fuzz-testing) | Oficial. Parámetros, configuración y cómo leer un contraejemplo (Teoría 03) |
| [Foundry — `assume`](https://getfoundry.sh/reference/cheatcodes/assume) y [`bound`](https://getfoundry.sh/reference/forge-std/bound) | Oficial. Las dos formas de restringir entradas y cuándo usar cada una (Teoría 03) |
| [Foundry — Fork Testing](https://getfoundry.sh/forge/fork-testing) | Oficial. `--fork-url`, forks desde el test y varios forks a la vez (Teoría 04) |
| [Foundry — `createSelectFork`](https://getfoundry.sh/reference/cheatcodes/create-select-fork) y [`rollFork`](https://getfoundry.sh/reference/cheatcodes/roll-fork) | Oficial. Las firmas con bloque y con hash de transacción (Teoría 04) |
| [Foundry — Gas Tracking](https://getfoundry.sh/forge/gas-tracking) y [Gas Snapshots](https://getfoundry.sh/reference/cheatcodes/gas-snapshots) | Oficial. Informe de gas, `forge snapshot` y los cheatcodes de gas (Teoría 05) |
| [Foundry — `forge snapshot`](https://getfoundry.sh/reference/forge/snapshot) y [`forge coverage`](https://getfoundry.sh/reference/forge/coverage) | Oficial. Todas las opciones de los dos comandos: `--diff`, `--check`, `--report` (Teoría 05 y proyecto) |
| [forge-std](https://github.com/foundry-rs/forge-std) | El código de `Test`, `Vm` y los ayudantes (`hoax`, `skip`, `bound`, `assumePayable`). Leerlo aclara qué es un cheatcode y qué es Solidity normal |
| [RareSkills — Foundry testing](https://www.rareskills.io/post/foundry-testing-solidity) | Guía larga con ejemplos de casi todos los cheatcodes de la semana |

Cada recurso oficial va primero porque es el que se mantiene al día con la versión. Los
ejemplos externos pueden usar `pragma ^0.8.x` o cheatcodes con otro nombre: en el bootcamp,
siempre `0.8.38` exacto y la forge-std de la imagen.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Videografía](../videografia/README.md) | **Webgrafía** | [Glosario →](../../5-glosario/README.md) |
