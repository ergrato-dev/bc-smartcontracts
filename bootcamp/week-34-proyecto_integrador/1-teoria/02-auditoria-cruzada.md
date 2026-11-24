# Teoría 02 — Auditoría cruzada

## 🎯 Objetivos

- Explicar por qué quien escribe un contrato no es quien mejor lo audita.
- Seguir el ciclo de una auditoría externa: alcance, lectura, hipótesis, prueba de concepto,
  severidad, informe y respuesta.
- Leer código ajeno con un método: la tabla de funciones y las asimetrías entre ellas.
- Escribir una prueba de concepto que demuestra un hallazgo con números, y un test que descarta una
  sospecha.
- Asignar una severidad con impacto y probabilidad, y escribir un hallazgo que la autora pueda
  reproducir.

## Qué problema resuelve

En la semana 26 auditaste tu propio protocolo, y su informe lo dice en `## Limitaciones`: quien
escribe el código conoce sus intenciones, y por eso lee lo que quiso escribir en vez de lo que
escribió. Si olvidaste un `onlyOwner`, tus tests del dueño pasan igual; si olvidaste actualizar
algo antes de cambiar un saldo, tu test del caso normal también.

Una **auditoría cruzada** es la de otra persona: lee tu código sin tus intenciones, solo con lo que
el código y tu informe dicen. En la industria se hace igual, con empresas de auditoría y concursos
públicos (Code4rena, Sherlock, Cantina) en los que decenas de personas revisan el mismo commit.
Esta semana la haces con tu pareja: tú auditas su protocolo y ella el tuyo.

Las herramientas no la sustituyen. El pool del ejercicio 02 tiene tres hallazgos, y Slither, sin
contar OpenZeppelin ni los tests, no encuentra ninguno:

```bash
slither . --filter-paths 'test|openzeppelin'
```

```text
INFO:Slither:. analyzed (8 contracts with 101 detectors), 0 result(s) found
```

Slither ve patrones (semana 23); los tres hallazgos son lógica: quién puede llamar, en qué orden
se actualiza algo, cuándo se redondea.

## Cómo funciona

![El ciclo de una auditoría cruzada en siete pasos: acordar el alcance y el commit; entender el protocolo con su informe y sus tests; la tabla de funciones; hipótesis por clases y por asimetrías; una prueba de concepto por hipótesis, que la confirma como hallazgo o la descarta; la severidad por impacto y probabilidad; y el informe. La autora responde cada hallazgo como corregido, reconocido o en disputa, y el auditor revisa las correcciones](../0-assets/02-el-ciclo-de-una-auditoria.svg)

### El alcance y el commit

Una auditoría es de un **commit**, no de un repositorio: el hash de 40 caracteres fija exactamente
qué código se revisó. Si la autora sigue cambiando el código, tus hallazgos se refieren a una
versión que ya no existe, y sus correcciones, a otra que no viste. El alcance dice además qué
contratos entran y cuáles se dan por correctos (OpenZeppelin, el EntryPoint, el rollup).

### Entender antes de buscar

Lee primero lo que la autora dice que hace su protocolo: su informe (actores, activos, amenazas y
riesgos aceptados), sus tests y sus scripts. Ejecuta `bash test.sh` en su commit. Tu trabajo es
encontrar dónde el código no hace lo que el informe dice, o lo que el informe no dice.

### La tabla de funciones

Por cada función externa o pública que cambia estado, una línea:

| Función | Quién la llama | Qué cambia | Qué hace antes |
| ------- | -------------- | ---------- | -------------- |
| `stake` | Cualquiera | `totalStaked`, `balanceOf` | Nada |
| `withdraw` | Cualquiera | `totalStaked`, `balanceOf` | `_update` |
| `claim` | Cualquiera | `rewards` | `_update` |
| `setRewardRate` | Cualquiera | `rewardRate` | Nada |

Es la tabla del ejercicio 02, y ya da dos hallazgos. `setRewardRate` cambia la configuración y la
llama cualquiera. `stake` y `withdraw` cambian lo mismo, y solo una llama a `_update`: es una
**asimetría**. Dos funciones parecidas que se protegen distinto son el lugar donde más hallazgos
salen, porque la autora corrigió una y no se acordó de la otra.

### Hipótesis

Con la tabla, recorre las clases de las semanas 21 y 22 (control de acceso, reentrancy, orden de
las operaciones, redondeo, oráculos, front-running) y escribe cada sospecha como una frase que se
puede comprobar: "si bob deposita tarde, cobra lo de antes". Y lee las **suposiciones**: qué
supone el código de sus dependencias (el feed devuelve un `startedAt` válido) y de sus roles (el
dueño no fija un ritmo imposible de pagar).

### La prueba de concepto

Una **prueba de concepto** (PoC, *proof of concept*) es un test que demuestra el hallazgo en el
commit auditado, sin cambiar su código. Convierte una opinión en un número: la autora la ejecuta,
ve el resultado y no hay nada que discutir sobre si el fallo existe. Después, invertida, es su test
de regresión (teoría 03).

Una sospecha se cierra igual: con un test que demuestra que **no** pasa. Así no acaba en el
informe, y si un cambio la hace posible mañana, el test lo dice.

### La severidad

La severidad combina dos cosas: el **impacto** (qué se pierde si ocurre) y la **probabilidad**
(qué hace falta para que ocurra: cualquiera, alguien con fondos, alguien con un rol, una red
concreta):

| Impacto \ Probabilidad | Alta | Media | Baja |
| ---------------------- | ---- | ----- | ---- |
| **Alto** (se roban o se bloquean fondos) | Crítica | Alta | Media |
| **Medio** (se pierden recompensas, se para un servicio) | Alta | Media | Baja |
| **Bajo** (cuesta gas, molesta) | Media | Baja | Baja |

**Informativa** queda para lo que no tiene impacto hoy: una suposición sin escribir, una buena
práctica que falta. La tabla es un punto de partida: la severidad se discute con la autora, y el
impacto y la probabilidad son los argumentos.

### El hallazgo

Cada hallazgo, con el mismo formato, para que la autora lo pueda reproducir sin preguntarte:

- **Título**: qué pasa, en una frase. "Cualquiera fija el ritmo y vacía el pool", no "Falta
  control de acceso".
- **Severidad**, con su impacto y su probabilidad.
- **Descripción**: dónde está (archivo y función) y por qué pasa.
- **Prueba de concepto**: el test, entero.
- **Recomendación**: cómo lo corregirías. La corrección la decide la autora.

### Hablar con la autora

La auditoría es de un commit, pero se hace con una persona. Tres reglas:

- **Las preguntas, por escrito** y en un solo sitio (el issue de la auditoría): "¿`setRewardRate`
  es solo del dueño a propósito?" Las respuestas pasan a ser parte del alcance.
- **No adelantes hallazgos** sueltos mientras auditas: la autora empezaría a corregir y tu commit
  dejaría de ser el suyo. Se entregan todos juntos, en el informe.
- **Habla del código, no de la persona**: "`stake` no llama a `_update`", no "se te olvidó". Un
  informe se lee mejor cuando no hay que defenderse de él.

## Cómo se escribe

El PoC de H-02 del ejercicio 02: bob deposita lo mismo que alice tras un día y cobra en el mismo
bloque.

**Dónde**: en `test/Audit.t.sol` del ejercicio 02, que despliega el pool con una recompensa por
segundo.

```solidity
function test_Paso2_PoC_LateStakerTakesHalfOfAlicesRewards() public {
    _stake(alice, 100e18);
    vm.warp(block.timestamp + 1 days);
    assertEq(pool.earned(alice), 86_400e18, "antes de bob, alice lleva un dia");
    _stake(bob, 100e18);
    vm.prank(bob);
    pool.claim();
    assertEq(rewardToken.balanceOf(bob), 43_200e18, "H-02: bob cobra medio dia que no estuvo");
    assertEq(pool.earned(alice), 43_200e18, "H-02: alice pierde la mitad");
}
```

**Ejecuta** `forge test --mt test_Paso2 -vv`.

**Salida**:

```text
Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 1.05ms (150.04µs CPU time)
```

Un PoC pasa cuando el fallo existe. Los tres `assertEq` son el hallazgo: antes de bob, alice lleva
86 400; bob cobra 43 200 sin haber estado; y a alice le quedan 43 200. Lo que dice el título,
medido.

Una sospecha se escribe igual, pero el test espera que el ataque falle. `withdraw` no comprueba
que `amount` sea como mucho el saldo; ¿puede el atacante retirar lo de alice?

```solidity
function test_Paso4_NoOneWithdrawsMoreThanTheirStake() public {
    _stake(alice, 100e18);
    _stake(attacker, 1e18);
    vm.prank(attacker);
    vm.expectRevert(stdError.arithmeticError);
    pool.withdraw(2e18);
    assertEq(stakingToken.balanceOf(address(pool)), 101e18, "el deposito de alice sigue en el pool");
}
```

**Ejecuta** `forge test --mt test_Paso4 -vv`.

**Salida**:

```text
Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 899.22µs (100.98µs CPU time)
```

La resta revierte con el error aritmético de Solidity 0.8: no es un hallazgo, y el test se queda
en el repositorio por si alguien añade un `unchecked`.

Con el PoC, el hallazgo se escribe en el formato de arriba:

```markdown
### C-02 — `stake` no apunta lo ganado: quien llega tarde cobra lo de antes

- **Severidad**: alta. Impacto medio (roba recompensas, no depósitos); probabilidad alta (basta con
  depositar).
- **Descripción**: `RewardPool.stake` cambia `balanceOf` y `totalStaked` sin llamar antes a
  `_update`. El `userRewardPerTokenPaid` de quien deposita queda en 0.
- **Prueba de concepto**: `test_Paso2_PoC_LateStakerTakesHalfOfAlicesRewards` (arriba).
- **Recomendación**: llamar a `_update(msg.sender)` al principio de `stake`, como en `withdraw`.
```

## Antipatrones y riesgos

- **Un hallazgo sin PoC.** "Podría haber reentrancy" obliga a la autora a demostrar que no. Si
  no puedes escribir el test, es una pregunta, no un hallazgo: hazla como pregunta.
- **Copiar la salida de una herramienta.** Cada resultado de Slither o de un fuzzer se comprueba a
  mano; los falsos positivos en un informe le quitan valor a los verdaderos.
- **Inflar la severidad.** Un "crítico" que no lo es hace que la autora deje de fiarse de los
  demás. Si hace falta un rol de confianza, la probabilidad baja; dilo.
- **Auditar otra versión.** Sin commit fijo, la autora corrige sobre un código y tú lees otro.
- **Arreglar el código de la autora.** Tu PoC va en un test, sin tocar su código. La corrección es
  suya: tú la revisas después.
- **Explotar en una red pública.** Un PoC corre en un test o en un fork local, nunca contra un
  despliegue real con fondos de otros, aunque sean de testnet. Y el informe no se publica sin
  acuerdo con la autora: es **divulgación responsable** (teoría 04).

## Trucos

- Empieza por donde se mueve el valor: las funciones que transfieren tokens o ETH, y las que
  cambian lo que esas funciones leen.
- Busca asimetrías: dos funciones que cambian lo mismo y se protegen distinto, o una función que
  hace en otro orden lo que hacen las demás.
- Lee el informe de la autora al revés: cada riesgo aceptado es una suposición; comprueba que el
  código no le permita más de lo que el informe acepta.
- Pon un límite de tiempo a cada hipótesis. Si en una hora no tienes PoC, apúntala como pregunta y
  sigue.
- Pregunta a la autora por escrito y guarda las respuestas: son parte del alcance.

## ✅ Checklist

- [ ] Sé por qué la autora no ve los fallos que ve otra persona, y por qué Slither tampoco.
- [ ] Sé fijar el alcance de una auditoría con un commit.
- [ ] Sé hacer la tabla de funciones y buscar asimetrías.
- [ ] Sé cómo hablar con la autora durante la auditoría.
- [ ] Sé escribir un PoC que demuestra un hallazgo con números, y un test que descarta una sospecha.
- [ ] Sé asignar una severidad con impacto y probabilidad.
- [ ] Sé escribir un hallazgo con título, severidad, descripción, PoC y recomendación.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 01 — El protocolo completo](01-el-protocolo-completo.md) | **Teoría 02 — Auditoría cruzada** | [Teoría 03 — Corregir hallazgos →](03-corregir-hallazgos.md) |
