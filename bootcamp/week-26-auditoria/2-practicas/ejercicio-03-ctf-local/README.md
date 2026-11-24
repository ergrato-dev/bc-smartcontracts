# Ejercicio 03 — CTF local

> Al terminar habrás resuelto tres niveles de un CTF que corre entero en tu contenedor: una caja
> fuerte, un banco con cerrojo y un repartidor de vales firmados. En cada uno, leer un contrato
> que no conoces, encontrar por dónde se rompe y demostrarlo con un exploit.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 04 — Informe y divulgación](../../1-teoria/04-informe-y-divulgacion.md)
leída (la parte del CTF local) y los ejercicios 01 y 02 en verde.

## Contexto

Proyecto Foundry. Cada nivel es un archivo de `src/` con dos contratos: el blanco y un `Setup` que
lo despliega con 10 ETH y tiene `isSolved()`, la condición de victoria. Juegas como `player`, con
1 ETH. En los tres niveles ganas vaciando el blanco.

| Archivo | Qué es |
| ------- | ------ |
| `src/Level1.sol` | Nivel 1: `Safe`, una caja fuerte con dueño |
| `src/Level2.sol` | Nivel 2: `LockedBank`, un banco con cerrojo `nonReentrant` |
| `src/Level3.sol` | Nivel 3: `Vouchers`, un repartidor de vales firmados |
| `src/attackers/BankAttacker.sol` | Tu atacante del nivel 2. Paso 3 |
| `test/Solve.t.sol` | Un test por paso: tu exploit, pasos 1 a 4 |

**Cómo jugar.** Las líneas `//> ` de cada paso son la solución, como en todos los ejercicios del
bootcamp. En un CTF eso es un spoiler: **no las mires todavía**. Para cada nivel, lee el contrato
blanco entero, apunta qué no debería poder hacer `player`, y escribe tu exploit en el test, debajo
del `revert`, antes de mirar las líneas `//> `. Si te atascas, abre las pistas de una en una. Si tu
exploit es distinto del de las líneas `//> ` y el test pasa, también vale.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-26-auditoria/2-practicas/ejercicio-03-ctf-local/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `0 passed; 4 failed`, cada uno con su `TODO: Paso N`. El compilador avisa de código
inalcanzable y de variables sin usar: es lo que va detrás de cada `revert`.

## Paso 1: Nivel 1, la caja fuerte

**El nivel**: `Safe` guarda 10 ETH. Solo su dueño, `Level1Setup`, puede retirarlos. Tú solo tienes
`setup.SAFE()`.

**Por qué funciona el exploit**: lo explica la última pista. Ábrela cuando hayas escrito el tuyo o
te hayas rendido.

<details>
<summary>Pista 1</summary>

¿Cuántas veces se puede llamar a `initialize`? Lee qué hace con `initialized`.

</details>

<details>
<summary>Pista 2: la explicación</summary>

`initialize` comprueba `initialized`, pero nunca la pone a `true`. Cualquiera puede volver a
llamarla y hacerse dueño. Es el fallo de control de acceso de la semana 21 con la forma del
inicializador de la semana 15: por eso OpenZeppelin da el modificador `initializer` en vez de
dejar que cada uno escriba el suyo.

</details>

**Abre** `test/Solve.t.sol`, borra el `revert` de `test_Paso1_SolveSafe` y escribe tu exploit, o
descomenta sus líneas. Ejecuta `forge test --mt test_Paso1`.

**Verifica**: `test_Paso1_SolveSafe` en verde: `isSolved()` es `true` y `player` tiene 11 ETH.

## Paso 2: Nivel 2, preparar el ataque

**El nivel**: `LockedBank` guarda 10 ETH depositados por `Level2Setup`. `withdraw` lleva un cerrojo
`nonReentrant`, así que la reentrancy de la semana 21 contra `withdraw` no funciona. Pero hay otra
función.

<details>
<summary>Pista 1</summary>

¿En qué orden hace `withdraw` sus cosas? ¿Qué vale tu `balanceOf` mientras recibes el ETH?

</details>

<details>
<summary>Pista 2</summary>

El cerrojo solo lo tiene `withdraw`. ¿Qué otra función lee `balanceOf`, y se puede llamar mientras
`withdraw` está a medias?

</details>

<details>
<summary>Pista 3: la explicación</summary>

`withdraw` envía el ETH **antes** de poner tu saldo a cero. Mientras tu `receive` se ejecuta, tu
saldo sigue entero, y `transfer` no tiene cerrojo: puedes pasarlo a otra cuenta tuya. Cuando
`withdraw` vuelve, pone a cero un saldo que ya no tienes. Es la reentrancy entre funciones de la
semana 21: el cerrojo protege una función; checks-effects-interactions protege el estado.

</details>

El ataque necesita dos contratos que se pasan el saldo, porque una cuenta normal (EOA) no ejecuta
código al recibir ETH. `BankAttacker` ya tiene `deposit`, `withdraw`, `collect` y un `partner`. En
este paso solo los despliegas, los presentas y depositas tu 1 ETH por uno de ellos.

**Abre** `test/Solve.t.sol` y resuelve `test_Paso2_SolveBankSetup`.

**Verifica**: `test_Paso2_SolveBankSetup` en verde: el banco apunta 1 ETH a nombre de `a`.

## Paso 3: Nivel 2, vaciar el banco

**Por qué**: cada vez que un atacante retira, en su `receive` pasa su saldo al otro. Al acabar el
`withdraw`, tiene 1 ETH de verdad y el otro tiene el saldo de 1 ETH. Se van turnando, y cada vuelta
saca 1 ETH del banco sin que el total de saldos baje.

Son dos cambios:

1. **Abre** `src/attackers/BankAttacker.sol` y escribe el `receive`, o descomenta su línea.
2. **Abre** `test/Solve.t.sol` y, en `test_Paso3_SolveBank`, escribe el bucle que alterna los
   `withdraw` hasta vaciar el banco y después recoge con `collect`, o descomenta sus líneas.

Haz los dos antes de ejecutar: con el bucle y sin el `receive`, el segundo atacante retira 0 una y
otra vez, y el test falla con `EvmError: OutOfGas`.

**Verifica**: `forge test --mt test_Paso3` en verde. Son once retiradas: diez del ETH del banco y
una de tu propio ETH. `player` tiene 11 ETH.

## Paso 4: Nivel 3, los vales

**El nivel**: `Vouchers` paga a quien presente un vale firmado por el repartidor. El test te da
tu vale: 1 ETH para `player`, firmado con EIP-191 (semana 14).

<details>
<summary>Pista 1</summary>

¿Qué apunta `claim` después de pagar un vale?

</details>

<details>
<summary>Pista 2: la explicación</summary>

Nada. `claim` comprueba la firma y paga, pero no recuerda qué vales se cobraron: el mismo vale
vale otra vez, y otra. Es el *replay* de la semana 14. La firma tendría que cubrir un nonce que el
contrato marque como usado, y, con EIP-712, la cadena y la dirección del contrato, para que el
vale tampoco valga en otro despliegue.

</details>

**Abre** `test/Solve.t.sol` y resuelve `test_Paso4_SolveVouchers`.

**Verifica**: `4 passed; 0 failed`. Diez cobros del mismo vale.

## Para pensar

- Escribe cada nivel como un hallazgo de la teoría 03: título, severidad e impacto. ¿Cuál tiene
  la probabilidad más alta?
- En el nivel 2, ¿bastaría con poner `nonReentrant` también en `transfer`? ¿Qué arreglo protege
  aunque mañana alguien añada una tercera función sin cerrojo?
- Ethernaut y Damn Vulnerable DeFi (en la webgrafía) tienen decenas de niveles con este mismo
  formato. Prueba uno: su `Setup` y su condición de victoria se leen igual.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Hallazgos con PoC](../ejercicio-02-hallazgos-con-poc/README.md) | **Ejercicio 03 — CTF local** | [Proyecto — Informe de auditoría final →](../../3-proyecto/README.md) |
