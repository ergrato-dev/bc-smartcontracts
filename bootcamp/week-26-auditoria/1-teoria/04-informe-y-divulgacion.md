# Teoría 04 — Informe y divulgación

## 🎯 Objetivos

- Escribir un informe de auditoría con sus secciones: resumen, alcance, modelo de amenazas,
  metodología, hallazgos, revisión de correcciones y limitaciones.
- Hacer la revisión de correcciones y dar a cada hallazgo su estado final.
- Saber qué hacer si encuentras un fallo en un contrato desplegado que no es tuyo: divulgación
  responsable y bug bounties.
- Conocer las formas de practicar y de trabajar como auditor: concursos, bounties y CTF.

## Qué problema resuelve

El informe es lo único que queda de una auditoría. Lo lee el equipo para corregir, lo lee la
dirección para decidir si se despliega, y si se publica lo leen los usuarios para decidir si
confían su dinero. Cada lector busca una cosa distinta, y un informe que solo sirve a uno de ellos
falla a los demás: una lista de hallazgos sin resumen no la lee la dirección; un resumen sin
alcance hace creer al usuario que se revisó todo.

Y a veces el fallo aparece fuera de una auditoría: en un contrato ya desplegado, con dinero real
dentro. Ahí lo que haces en las horas siguientes importa tanto como haberlo encontrado.

## Cómo funciona: las secciones del informe

| Sección | Para quién | Qué dice |
| ------- | ---------- | -------- |
| **Resumen** | Dirección, usuarios | Qué se auditó, cuántos hallazgos de cada severidad, cuántos corregidos y el riesgo principal, en un párrafo |
| **Alcance** | Todos | Contratos, líneas, commit y lo que quedó fuera |
| **Modelo de amenazas** | Equipo, auditores futuros | Actores, activos, fronteras y la tabla de amenazas (teoría 02) |
| **Metodología** | Todos | Qué técnicas y herramientas, con versiones |
| **Hallazgos** | Equipo | Una tabla con todos y una sección por hallazgo (teoría 03) |
| **Revisión de correcciones** | Equipo, usuarios | Cada corrección, cómo se comprobó y si ya está desplegada |
| **Limitaciones** | Todos | Lo que la auditoría no cubre y por qué no es una garantía |

El **resumen** va primero y se escribe al final. Un ejemplo con la tabla que esperan todos los
lectores:

```markdown
## Resumen

Auditoría del Crowdfund en el commit `<hash>`, del 1 al 5 de marzo. Revisión manual, modelo de
amenazas y Slither.

| Severidad | Encontrados | Corregidos | Reconocidos |
| --------- | ----------- | ---------- | ----------- |
| Crítica | 2 | 2 | 0 |
| Media | 1 | 1 | 0 |
| Baja | 1 | 0 | 1 |

El riesgo principal era `refundAll`: un solo aportante podía bloquear todas las devoluciones.
```

### La revisión de correcciones

Cuando el equipo corrige, entrega un commit nuevo. La **revisión de correcciones** (*fix review*)
comprueba cada cambio:

1. La PoC del hallazgo ya no pasa, y hay un test que comprueba el comportamiento correcto.
2. La corrección no rompe otra cosa: los tests de antes siguen en verde, y el diff no toca nada
   más de lo necesario.
3. La corrección no trae un fallo nuevo. Si lo trae, es un hallazgo nuevo con su número.

Cada hallazgo acaba con uno de estos **estados**:

| Estado | Significa |
| ------ | --------- |
| Corregido | La corrección está en el commit nuevo y se comprobó |
| Corregido parcialmente | Mejora, pero queda un escenario abierto, que se describe |
| Reconocido | El equipo lo acepta sin corregir, con su motivo: un riesgo asumido o una corrección futura |
| Disputado | El equipo no cree que sea un fallo; el informe recoge las dos posturas |

En un protocolo con proxy hay una pregunta más: **¿la corrección está desplegada?** Un fallo
corregido en el repositorio sigue vivo en la cadena hasta que se actualiza el proxy.

### Las limitaciones

Todo informe termina diciendo lo que no es. Lo mínimo:

- La auditoría vale para el commit del alcance, no para lo que venga después.
- Lo que quedó fuera del alcance no se revisó.
- Lo que cada herramienta no cubre (los límites de las invariantes, las specs que dieron
  `TIMEOUT`).
- Una auditoría reduce el riesgo; no demuestra que no haya fallos.

## Divulgación responsable

Supón que lees el código verificado de un contrato desplegado en mainnet y ves un fallo que deja
sacar los fondos. Lo que **no** haces: explotarlo "para demostrarlo", publicarlo en redes ni
contárselo a nadie más que al equipo. Hay dinero real de gente real dentro, y tu mensaje puede
llegar a un atacante antes que al equipo.

La **divulgación responsable** (*responsible disclosure*) es el camino contrario:

1. **Busca el canal de seguridad del protocolo.** Un archivo `SECURITY.md` en su repositorio, una
   página de seguridad en su web, o su programa de bug bounty. Muchos protocolos publican uno en
   [Immunefi](https://immunefi.com), la plataforma de bug bounties más usada en Web3.
2. **Envía un informe privado** con el formato de la teoría 03: descripción, impacto y una PoC que
   corra contra un fork local, nunca contra la red real. Un fork local de mainnet (`anvil
   --fork-url`, semana 09) reproduce el estado exacto sin tocar nada.
3. **Da tiempo al equipo** para corregir y desplegar antes de publicar nada. Lo habitual es
   acordar la fecha con ellos.
4. **No pidas dinero a cambio de no publicar.** Eso es extorsión, no un bounty. La recompensa la
   fija el programa de bounty, con sus reglas publicadas.

Un **bug bounty** es un programa público en el que el protocolo se compromete a pagar por fallos
divulgados de forma responsable, con recompensas según la severidad. Sus reglas dicen qué
contratos entran, qué está prohibido (casi siempre, probar contra la red real) y cuánto paga cada
severidad. Léelas antes de empezar.

## Cómo practicar y trabajar como auditor

| Vía | Qué es |
| --- | ------ |
| **CTF** | *Capture the flag*: niveles con un contrato vulnerable y una condición de victoria. Ethernaut, de OpenZeppelin, y Damn Vulnerable DeFi son los clásicos |
| **Concursos de auditoría** | Un protocolo publica su código durante unos días y muchos auditores buscan fallos a la vez; se reparte un premio según lo encontrado. Code4rena, Sherlock y Cantina son las plataformas más conocidas |
| **Informes publicados** | Las firmas y los concursos publican sus informes. Leer hallazgos de otros es la forma más rápida de aprender patrones |
| **Bug bounties** | Fallos en contratos desplegados, con las reglas de cada programa |

Un **CTF local** es un CTF que corre entero en tu máquina, como el ejercicio 03: cada nivel tiene
un contrato `Setup` que despliega el blanco con fondos y una función `isSolved()` con la condición
de victoria. Tu exploit es un test de Foundry que juega como `player` y termina con
`assertTrue(setup.isSolved())`. Sin red y sin dinero, y con la misma pregunta de una auditoría:
¿qué puede hacer alguien de fuera que el autor no previó?

## ⚠️ Antipatrones y riesgos

- **El informe sin resumen.** Quien decide si se despliega no lee veinte hallazgos. Necesita el
  párrafo y la tabla.
- **Corregido en el repositorio, vivo en la cadena.** La revisión de correcciones mira también qué
  hay desplegado detrás del proxy.
- **Probar contra la red real.** Una PoC contra mainnet mueve fondos de verdad y puede ser delito,
  aunque la intención sea buena. Siempre en un fork local.
- **Divulgar en público primero.** Un tuit con el fallo es una invitación a robar antes de que el
  equipo pueda reaccionar.
- **Informes de marketing.** "Auditado por X" no dice nada sin el informe, su alcance y su commit.
  Como usuario, compruebas que el commit auditado es el que está desplegado.

## 💡 Trucos

- **Escribe el informe mientras auditas**, no al final: cada hallazgo, en cuanto tiene PoC. El
  resumen sí va al final.
- **Una tabla de hallazgos con estado** desde el primer día. La revisión de correcciones solo
  rellena la última columna.
- **El commit en la primera tabla.** Sin él, el informe no dice qué código revisó.
- **Lee un informe publicado a la semana.** Los de los concursos son públicos y tienen las PoC.

## ✅ Checklist

- [ ] Sé qué lleva cada sección de un informe y para quién es.
- [ ] Sé escribir un resumen con la tabla de severidades y el riesgo principal.
- [ ] Sé hacer una revisión de correcciones y dar a cada hallazgo su estado.
- [ ] Sé por qué una corrección no cuenta hasta que está desplegada.
- [ ] Sé qué hacer, y qué no, si encuentro un fallo en un contrato desplegado ajeno.
- [ ] Sé qué es un CTF local y cómo se comprueba un nivel resuelto.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 03 — Hallazgos y severidad](03-hallazgos-y-severidad.md) | **Teoría 04 — Informe y divulgación** | [Ejercicio 01 — Modelo de amenazas →](../2-practicas/ejercicio-01-modelo-de-amenazas/README.md) |
