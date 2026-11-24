# Teoría 04 — Ataques a la gobernanza

## 🎯 Objetivos

- Ver por qué la DAO es el objetivo más valioso de un protocolo: quien la controla, lo controla
  todo.
- Reproducir el ataque con flash loan contra una votación que cuenta el saldo del momento.
- Distinguir los votos prestados en un instante de los prestados durante la foto.
- Reconocer los ataques sin bug: poca participación, propuestas con trampa y votos comprados.
- Revisar el despliegue de una DAO buscando puertas traseras.

## Qué problema resuelve

Cuando la DAO es la administradora de tu protocolo, una propuesta puede actualizar el código,
cambiar el hook, mover las tasas o darse cualquier rol. Atacar la DAO es más fácil que buscar un
bug en el registro: basta con conseguir que se apruebe una propuesta. Y el código de la
gobernanza puede hacer exactamente lo que dice y aun así perder el protocolo, como en los casos de
esta teoría.

Ninguna defensa es completa. Cada una (la foto, el quórum, el timelock, el guardián) cubre un
ataque y deja otros, y por eso se usan juntas.

## Cómo funciona

### Votos prestados en un instante

Es el ataque de Beanstalk (abril de 2022, [semana 22](../../week-22-vulnerabilidades_economicas/1-teoria/02-flash-loans.md)):
pedir prestados los tokens, votar y devolverlos en la misma transacción. Funciona si la votación
cuenta `balanceOf` o `getVotes` en el momento de votar. La foto de `ERC20Votes` (teoría 01) lo
cierra: los votos que cuentan son los de un bloque ya cerrado, anterior a la votación, y un flash
loan no sale de su transacción. El ejercicio 03 lo prueba contra el Governor de OpenZeppelin: un
millón de votos durante el préstamo, cero en la propuesta.

### Votos prestados durante la foto

La foto no impide pedir prestado **antes** de ella y devolver **después**. Si los tokens de
gobernanza se pueden pedir prestados en un protocolo de préstamos (semana 30), basta con tenerlos
en el bloque de la foto: el coste es el interés de unos días, no el precio de los tokens. El
`votingDelay` no lo evita, solo da tiempo a verlo venir.

Lo que lo limita: un quórum alto (hay que pedir prestado mucho), el timelock y el guardián (hay
tiempo de cancelar), y no dejar que los votos se muevan libremente. Algunas DAO solo dan votos a
tokens **bloqueados** durante un tiempo (*vote escrow*): quien quiere votar tiene que arriesgar su
capital meses, no días.

### Poca participación

Si casi nadie vota, casi nadie decide. En febrero de 2022, una cuenta reunió tokens suficientes de
Build Finance DAO para aprobar una propuesta que le daba el control del token y de la tesorería,
y se llevó unos 470 000 dólares. El código hizo lo que decía: el umbral para aprobar era bajo y la
mayoría no votó. Un quórum medido con la participación real, y un guardián que vigila, son la
defensa.

### Propuestas con trampa

El contrato ejecuta la `calldata`, no la descripción (teoría 02). Y si la `calldata` llama a otro
contrato, ejecuta el código que ese contrato tenga **en el momento de ejecutar**, no el que se
revisó al votar.

En mayo de 2023, un atacante presentó a la DAO de Tornado Cash una propuesta que parecía igual a
una anterior ya aprobada. La propuesta ejecutaba, con `delegatecall`, el código de un contrato del
atacante. Ese contrato tenía `selfdestruct`: tras la aprobación, lo destruyó y desplegó otro código
en la misma dirección (con `CREATE2` y una fábrica, semana 10). El código nuevo se dio
1,2 millones de votos, más que los 700 000 legítimos, y con ellos se llevó unos 483 000 TORN de la
gobernanza.

Desde la actualización Cancun de 2024 (EIP-6780), `selfdestruct` solo borra el código si se llama
en la misma transacción que creó el contrato: ese truco exacto ya no funciona en Ethereum. Pero la
idea sí: si una propuesta llama a un **proxy** (semana 15), su dueño puede cambiar la
implementación entre la votación y la ejecución. Lo que se vota tiene que ser código que nadie
pueda cambiar después.

### Votos comprados y ballenas

Ningún contrato impide que alguien pague a otros por delegarle sus votos, o que una cuenta con la
mayoría de los tokens (una **ballena**) apruebe lo que quiera. Contra eso solo sirven el timelock
(tiempo para irse), el guardián (tiempo para cancelar) y que las funciones peligrosas tengan
límites en el propio protocolo, voten lo que voten.

## Cómo se escribe

El ataque de Beanstalk contra una votación que cuenta el saldo. **Dónde**: en `src/NaiveDao.sol`
de un proyecto Foundry con OpenZeppelin, y el `GovToken` del ejercicio 03, que presta sus propios
tokens con ERC-3156 (`ERC20FlashMint`):

```solidity
// ❌ Cuenta el saldo del momento de votar.
contract NaiveDao {
    IERC20 public immutable TOKEN;
    mapping(uint256 => uint256) public forVotes;
    mapping(uint256 => mapping(address => bool)) public voted;

    constructor(IERC20 token) {
        TOKEN = token;
    }

    function vote(uint256 id) external {
        require(!voted[id][msg.sender], "ya voto");
        voted[id][msg.sender] = true;
        forVotes[id] += TOKEN.balanceOf(msg.sender);
    }
}
```

**Dónde**: en `test/Naive.t.sol`, un prestatario que vota dentro del préstamo:

```solidity
contract Borrower is IERC3156FlashBorrower {
    function attack(GovToken token, NaiveDao dao) external {
        token.flashLoan(this, address(token), 1_000_000 ether, abi.encode(dao));
    }

    function onFlashLoan(address, address token, uint256 amount, uint256 fee, bytes calldata data)
        external
        returns (bytes32)
    {
        abi.decode(data, (NaiveDao)).vote(1);
        GovToken(token).approve(token, amount + fee);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}

contract NaiveTest is Test {
    function test_FlashLoanWinsTheVote() public {
        GovToken token = new GovToken();
        NaiveDao dao = new NaiveDao(token);
        Borrower attacker = new Borrower();
        attacker.attack(token, dao);
        console.log("votos a favor", dao.forVotes(1) / 1 ether);
        console.log("saldo final  ", token.balanceOf(address(attacker)));
    }
}
```

**Ejecuta**: `forge test -vv --mt test_FlashLoanWinsTheVote`

```text
[PASS] test_FlashLoanWinsTheVote() (gas: 4578525)
Logs:
  votos a favor 1000000
  saldo final   0
```

Un millón de votos a favor sin tener un solo token al acabar la transacción. `ERC20FlashMint`
emite lo prestado y lo quema al devolverlo, con el `approve` del prestatario; la comisión es 0. El
mismo ataque contra un Governor con `ERC20Votes` es `test_FlashLoanVotesCountZero` del ejercicio 03.

## Antipatrones y riesgos

- **Votos del momento.** `balanceOf`, `getVotes` o `totalSupply` actuales en una votación: es el
  ejemplo de arriba. Siempre `getPastVotes` y `getPastTotalSupply` de la foto.
- **Un token de gobernanza que cualquiera presta.** Si tu token se puede pedir prestado en un
  mercado, la foto no basta: mide el quórum y el plazo pensando en cuánto costaría tener los votos
  unos días.
- **Ejecutar código que cambia.** Una propuesta que llama a un proxy, o a un contrato que alguien
  puede actualizar, ejecuta lo que haya al final del plazo. Revisa a quién llama cada `target` y
  quién puede cambiarlo.
- **Puertas traseras en el despliegue.** Un administrador del timelock sin renunciar, otro
  proponente, el Governor desplegado detrás de un proxy que actualiza una sola clave: la votación
  funciona y sobra. Es la primera revisión de cualquier DAO (trucos).
- **Un protocolo sin límites propios.** Si la DAO puede poner la comisión a cualquier valor o
  mover toda la tesorería en una propuesta, quien la controle una vez se lo lleva todo. Un tope
  en el contrato gobernado (una comisión máxima, un pago máximo por propuesta) limita el daño de
  una votación mala.

## Trucos

- Revisar una DAO desplegada, en este orden: quién tiene `DEFAULT_ADMIN_ROLE` y `PROPOSER_ROLE` en
  el timelock (`hasRole`), cuánto es `getMinDelay`, de quién son los roles y los fondos de lo
  gobernado, y si el Governor o el token se pueden actualizar. Son los tests del ejercicio 03 y del
  proyecto.
- Antes de votar una propuesta, decodifica su `calldata` con
  `cast calldata-decode "pay(address,uint256)" <calldata>` y mira el código de cada `target` con
  `cast code`: si es un proxy, mira también quién puede cambiar su implementación.
- El modelo de amenazas de la semana 26 se aplica a la DAO como a cualquier contrato: actores
  (holders, delegados, guardián, quien presta tokens), activos (los roles del registro) y una
  amenaza por ataque de esta teoría. Es lo que añades a tu informe en el proyecto.

## ✅ Checklist

- [ ] Sé por qué controlar la DAO es controlar el protocolo.
- [ ] Sé por qué un flash loan no vota contra `ERC20Votes` y un préstamo de varios días sí.
- [ ] Sé qué pasó en Build Finance y en Tornado Cash, y qué los habría frenado.
- [ ] Sé por qué una propuesta que llama a un proxy no ejecuta lo que se revisó.
- [ ] Sé revisar el despliegue de una DAO buscando quién tiene poder sin votar.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 03 — El timelock de la DAO](03-el-timelock-de-la-dao.md) | **Teoría 04 — Ataques a la gobernanza** | [Ejercicio 01 — Votos con checkpoints →](../2-practicas/ejercicio-01-votos-con-checkpoints/README.md) |
