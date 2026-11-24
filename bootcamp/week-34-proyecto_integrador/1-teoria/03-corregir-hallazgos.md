# Teoría 03 — Corregir hallazgos

## 🎯 Objetivos

- Recibir un informe de auditoría: reproducir cada hallazgo antes de discutirlo o corregirlo.
- Responder cada hallazgo con un estado: corregido, reconocido o en disputa, con su porqué.
- Corregir la causa y no el síntoma, y buscar la misma clase de fallo en el resto del código.
- Convertir cada prueba de concepto en un test de regresión.
- Revisar una corrección: qué más hace ahora el código que se ha tocado.
- Saber cómo llega una corrección a un contrato desplegado, y cuándo se puede contar.

## Qué problema resuelve

Un informe de auditoría no hace más seguro un protocolo: lo hacen las correcciones. Y corregir mal
es fácil: arreglar la línea del PoC y no la del al lado, escribir un test que comprueba que existe
el `onlyOwner` en vez de que el ataque falla, o introducir un fallo nuevo con la corrección. En los
concursos de auditoría hay una fase solo para esto, la **revisión de correcciones** (*fix review*),
porque una parte de las correcciones no corrige o rompe otra cosa.

El ejercicio 03 lo muestra: con las tres correcciones del informe, el pool sigue teniendo un fallo
que nadie pidió corregir, y lo encuentra quien revisa lo que cambió.

## Cómo funciona

### Reproducir primero

Antes de discutir un hallazgo, ejecuta su PoC en el commit auditado. Si pasa, el fallo existe,
aunque no estés de acuerdo con su severidad. Si no pasa, pregunta al auditor qué entorno usó:
quizá tú no lo ves porque tus tests no lo cubren.

### El estado de cada hallazgo

Cada hallazgo recibe una respuesta, con uno de tres estados:

| Estado | Cuándo | Qué escribes |
| ------ | ------ | ------------ |
| **Corregido** | Cambias el código y el ataque deja de funcionar | La corrección, el test de regresión y dónde está desplegada |
| **Reconocido** | El fallo existe y decides no corregirlo: es el diseño, o corregirlo cuesta más de lo que protege | Por qué, y qué lo limita. Pasa a ser un riesgo aceptado del informe |
| **En disputa** | No estás de acuerdo en que sea un fallo, o en su severidad | Tus argumentos: el impacto y la probabilidad, con un test si puedes |

"En disputa" no es "no me gusta": es una conversación con el auditor que termina en un acuerdo, y
la severidad acordada es la que va al informe. En tu proyecto, H-06 bajó de media a baja con un
argumento (el OP Stack nunca devuelve `startedAt` = 0) y aun así se corrigió; H-07 se reconoce
porque es el diseño.

### La causa, no el síntoma

El PoC demuestra un camino; la causa puede tener otros. H-02 del ejercicio 02 dice "`stake` no
llama a `_update`". El síntoma es `stake`; la causa es "cambiar algo que `earned` lee sin cerrar lo
acumulado antes". Corregir la causa es preguntar qué otras funciones cambian lo que `earned` lee:
`stake`, `withdraw`... y `setRewardRate`, que cambia `rewardRate`. Esa búsqueda de la misma clase
en el resto del código se llama **análisis de variantes** (*variant analysis*): es lo que habría
encontrado el fallo del paso 4 sin esperar a la revisión.

### El test de regresión

El PoC del auditor demuestra que el ataque funciona. El **test de regresión** es el mismo ataque
con la conclusión al revés: el ataque ya no funciona. No comprueba la corrección (que exista un
`onlyOwner`), sino el comportamiento (que un extraño no fije el ritmo): si mañana alguien quita el
modificador por error, o lo cambia por otro que no protege lo mismo, el test falla.

Un buen test de regresión mata el mutante que deshace la corrección (semana 24): es lo que hacen
los cinco mutantes nuevos de `mutants.sh` en el proyecto.

### La revisión de la corrección

Revisar una corrección no es ejecutar el PoC y ver que falla. Es leer el diff y preguntar, de cada
línea tocada: qué hace ahora que antes no hacía, y qué ha dejado de hacer. Las tres formas típicas
de que una corrección falle:

- **Incompleta**: corrige el camino del PoC y no los demás de la misma causa.
- **Nueva**: introduce otro fallo (un `revert` que bloquea retiradas, un orden nuevo que abre una
  reentrancy).
- **Rompe la compatibilidad**: cambia el layout de storage de un proxy (semana 15), un evento que
  lee el indexador o una firma que usa el frontend.

### El orden de las correcciones

Un informe trae varios hallazgos y no todos se corrigen a la vez. El orden lo decide el riesgo, no
lo fácil que sea cada uno:

1. **Lo explotable hoy en un despliegue con fondos**, primero y en privado: pausa, corrección,
   propuesta.
2. **Lo crítico y lo alto**, cada uno en su commit y con su test, antes de la siguiente versión.
3. **Lo medio y lo bajo**, agrupados en una misma actualización: cada actualización del proxy es
   una propuesta, dos días de espera y un riesgo nuevo de romper el storage.
4. **Lo informativo**, en el informe: casi siempre es documentación, no código.

Dos correcciones que tocan la misma función van juntas y se revisan juntas: corregidas por
separado, la segunda puede deshacer la primera sin que ningún test lo note.

### Llevarla a la red

En un contrato desplegado, "corregido en el código" no es "corregido". Depende de cómo se
desplegó:

- **Detrás de un proxy** (el registro): una implementación nueva y una propuesta de la DAO que
  llama a `upgradeToAndCall`. Con el timelock, la votación más dos días.
- **Inmutable** (el feed del secuenciador): un contrato nuevo, y una propuesta que cambia la
  dirección que el resto lee (`setFeeConfig`). Es la ventaja de envolver en vez de actualizar.
- **Sin forma de cambiarlo**: un contrato nuevo, y los usuarios tienen que mudarse.

Mientras la corrección espera al timelock, el fallo está publicado en la propuesta: cualquiera
puede leer el diff y atacar antes. Para un hallazgo grave, primero se pausa (el guardián, sin
esperar) y después se corrige; y la propuesta no explica el fallo hasta que se ejecuta.

## Cómo se escribe

La revisión de la corrección de H-01 en el ejercicio 03. Con las tres correcciones del informe
hechas, el test de la revisión falla.

**Dónde**: en `test/Fixes.t.sol` del ejercicio 03, con los pasos 1 a 3 resueltos.

```solidity
function test_Paso4_RateChangeIsNotRetroactive() public {
    _stake(alice, 100e18);
    vm.warp(block.timestamp + 1 days);
    vm.prank(owner);
    pool.setRewardRate(2 * RATE);
    assertEq(pool.earned(alice), 86_400e18, "Paso 4: el primer dia, al ritmo de antes");
    vm.warp(block.timestamp + 1 days);
    assertEq(pool.earned(alice), 259_200e18, "Paso 4: el segundo, al nuevo");
}
```

**Ejecuta** `forge test`.

**Salida** (la línea del test):

```text
[FAIL: Paso 4: el primer dia, al ritmo de antes: 172800000000000000000000 != 86400000000000000000000] test_Paso4_RateChangeIsNotRetroactive() (gas: 181985)
```

El día ya pasado se paga al ritmo nuevo: 172 800 en vez de 86 400. Con `_updateGlobal()` antes de
cambiar el ritmo, el día se cierra al ritmo de antes y el test pasa: `7 tests passed, 0 failed`.

La respuesta al informe, en la tabla de la autora:

| Id | Estado | Corrección | Test de regresión |
| -- | ------ | ---------- | ----------------- |
| H-01 | Corregido | `onlyOwner` en `setRewardRate` | `test_Paso1_RevertWhen_StrangerSetsTheRate` |
| H-04 | Corregido (encontrado en la revisión) | `_updateGlobal` en `setRewardRate` | `test_Paso4_RateChangeIsNotRetroactive` |

El mismo camino con un hallazgo del proyecto: H-06, el feed de disponibilidad sin inicializar. El
PoC de la auditoría cruzada demostraba que el precio salía; el test de regresión espera el revert.

**Dónde**: en `contracts/test/cross/ReceivedFindings.t.sol` del proyecto. `UninitializedUptimeFeed`
devuelve una ronda toda a cero, como el feed de Arbitrum antes de inicializarse.

```solidity
function test_RevertWhen_TheUptimeFeedHasNotStarted() public {
    SequencerAwareFeed feed = new SequencerAwareFeed(
        AggregatorV3Interface(address(new UninitializedUptimeFeed())), AggregatorV3Interface(address(priceFeed))
    );
    vm.expectRevert(SequencerAwareFeed.UptimeFeedNotStarted.selector);
    feed.latestRoundData();
}
```

**Ejecuta** `forge test --mc ReceivedFindingsTest` antes de corregir.

**Salida** (la línea del test):

```text
[FAIL: next call did not revert as expected] test_RevertWhen_TheUptimeFeedHasNotStarted() (gas: 635001)
```

La corrección es una línea en `_checkSequencer`, antes del plazo de gracia:
`if (statusSince == 0) revert UptimeFeedNotStarted();`. Con ella, `2 tests passed`. El segundo
test, `test_ReadsThePriceOnceTheUptimeFeedStarted`, es la revisión de la corrección: con un feed
inicializado el precio sigue saliendo, y los nueve tests de la L2 de la semana 33 siguen en verde.
Y `mutants.sh` quita la línea ("acepta el feed sin inicializar") para comprobar que el test la mira.

## Antipatrones y riesgos

- **Discutir antes de reproducir.** Si el PoC pasa, el fallo existe. Lo que se discute es la
  severidad, no el hecho.
- **Corregir solo el camino del PoC.** El auditor encontró un ejemplo de la causa; busca los demás.
- **Un test que comprueba la línea y no el ataque.** Que `setRewardRate` tenga `onlyOwner` no es lo
  importante: lo es que el atacante no fije el ritmo.
- **Cambiar el test del auditor para que pase.** Si su PoC ya no compila con tu corrección,
  adáptalo para que siga atacando lo mismo, y dile qué cambiaste.
- **Reconocer sin escribirlo.** Un hallazgo reconocido que no está en el informe como riesgo
  aceptado se vuelve a encontrar en la siguiente auditoría, y la siguiente persona no sabrá que lo
  decidiste.
- **Publicar el fallo antes que la corrección.** Una propuesta con el diff de una corrección grave
  es un aviso a los atacantes. Primero la pausa.

## Trucos

- Corrige cada hallazgo en su propio commit, con su id en el mensaje: `fix(feed): close H-06 with
  UptimeFeedNotStarted`. El auditor revisa commit a commit.
- Pide al auditor que revise las correcciones: es parte de su trabajo, y es quien mejor sabe qué
  buscaba.
- Tras corregir, ejecuta el PoC original sin cambios: debe fallar en el punto exacto del ataque.
- Añade un mutante por corrección importante: si el mutante sobrevive, tu test de regresión no
  protege nada.

## ✅ Checklist

- [ ] Sé por qué se reproduce un hallazgo antes de discutirlo.
- [ ] Sé cuándo un hallazgo es corregido, reconocido o en disputa.
- [ ] Sé buscar variantes de un hallazgo en el resto del código.
- [ ] Sé ordenar las correcciones de un informe por riesgo.
- [ ] Sé convertir un PoC en un test de regresión que comprueba el comportamiento.
- [ ] Sé revisar una corrección: incompleta, nueva o incompatible.
- [ ] Sé cómo llega una corrección a un contrato detrás de un proxy, a uno inmutable y cuándo pausar
  antes.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 02 — Auditoría cruzada](02-auditoria-cruzada.md) | **Teoría 03 — Corregir hallazgos** | [Teoría 04 — Entregar y mantener →](04-entregar-y-mantener.md) |
