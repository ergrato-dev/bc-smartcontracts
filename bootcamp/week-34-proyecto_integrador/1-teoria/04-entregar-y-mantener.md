# Teoría 04 — Entregar y mantener

## 🎯 Objetivos

- Cerrar una versión del protocolo: etiqueta, notas y qué incluye.
- Escribir el `README.md` de un repositorio de portfolio y preparar una demo que no falla.
- Vigilar un protocolo desplegado con sus eventos: quién recibe roles, quién pausa.
- Tener un plan de incidentes antes de necesitarlo: quién pausa, cómo se corrige y cómo se cuenta.
- Saber qué es la divulgación responsable, qué es un programa de recompensas por fallos y qué falta
  antes de mover dinero real.

## Qué problema resuelve

Un protocolo no termina cuando pasan sus tests. Termina una **versión**: un commit concreto que
alguien puede leer, auditar, desplegar y citar. Y después del despliegue empieza otra parte del
trabajo: si alguien da un rol que no debía, si el guardián pausa, si llega un correo diciendo que
hay un fallo, alguien tiene que enterarse y saber qué hacer.

Esta teoría es lo que pasa a partir de hoy: cómo se presenta lo que has construido y cómo se
mantiene vivo y seguro.

## Cómo funciona

### Una versión

Una **etiqueta** de git (*tag*) pone un nombre fijo a un commit. `v1.0.0` sigue el **versionado
semántico** (*semantic versioning*): el primer número cambia cuando algo deja de ser compatible
(una función que desaparece, un layout de storage nuevo), el segundo cuando se añade algo
compatible, y el tercero con correcciones. En un protocolo desplegado, el número de la versión
debería coincidir con lo que devuelve `version()` del contrato, o el informe debería decir qué
versión del código corresponde a cada versión desplegada.

Una etiqueta **anotada** (`git tag -a`) guarda además quién la creó, cuándo y un mensaje. Es la que
se usa para entregas: la auditoría externa cita su commit y la etiqueta lo nombra.

### Las notas de la versión

Una etiqueta dice qué commit es la versión; las **notas de la versión** (*release notes*) dicen qué
contiene. En GitHub van en la *release* de la etiqueta, y para un protocolo responden cuatro cosas:

- **Qué hace**: las capas, en una lista corta (registro actualizable, puntos, vault, DAO, altas
  patrocinadas, L2).
- **Dónde está desplegada**: cada red, con sus direcciones y la versión de `version()` en cada una.
- **Qué se auditó**: el commit de la auditoría cruzada, los hallazgos y su estado.
- **Qué cambia respecto a la anterior**: lo incompatible primero. En `v1.0.0` no hay anterior; en
  `v1.1.0`, lo que la DAO tiene que aprobar para llevarla a la red.

Quien vaya a usar o auditar el protocolo empieza por aquí, no por el código.

### El README de un portfolio

Quien abre tu repositorio tiene dos minutos. El `README.md` de la raíz le dice, en este orden: qué
es (el problema y para quién), cómo está hecho (la arquitectura: el mapa de la teoría 01), cómo
probarlo (un comando), dónde está desplegado (direcciones con enlace al explorador), qué riesgos
tiene (el informe y la auditoría cruzada) y qué no está hecho. La última sección no resta: dice
que sabes dónde están los límites.

### Una demo que no falla

Una demo en vivo contra una testnet depende de la red, del faucet y del RPC. Prepárala para que no
dependa de nada:

- **Un guion**: qué vas a enseñar, en qué orden y cuánto dura cada parte.
- **Un script**: los comandos en un archivo, con anvil y tus scripts de despliegue, que puedes
  ejecutar dos veces seguidas y da lo mismo.
- **Un plan B**: la salida de una ejecución anterior guardada, por si algo falla en directo.

### Vigilar con eventos

Lo que hace un protocolo queda en sus eventos (semana 07). Los que importan para la seguridad son
pocos: `RoleGranted` y `RoleRevoked` (quién recibe o pierde poder), `Paused` y `Unpaused`,
`Upgraded` del proxy, `CallScheduled` del timelock (una propuesta en cola) y los de configuración
(`FeeConfigChanged`, `HookChanged`). Una **alerta** es un programa que lee esos eventos y avisa a una
persona: tu indexador de la semana 19 ya lee eventos y los guarda en PostgreSQL, y una consulta
periódica sobre esas tablas es la alerta más simple.

`CallScheduled` es el más valioso: el timelock existe para que los usuarios vean un cambio antes
de que ocurra, y eso solo sirve si alguien mira.

### El plan de incidentes

Un **incidente** es cualquier cosa que pone en riesgo los fondos o el servicio: un hallazgo que te
llega, una transacción rara, un oráculo que se para. El plan se escribe antes, en el repositorio,
y responde cuatro preguntas:

1. **Quién decide**: quién puede pausar (el guardián) y cómo se le avisa a cualquier hora.
2. **Qué se para**: `pause()` para las altas; qué sigue funcionando (retirar del vault, las altas
   con puntos de la L2) y por qué eso está bien.
3. **Cómo se corrige**: la corrección, su test, la propuesta de la DAO y su plazo (teoría 03).
4. **Cómo se cuenta**: un informe del incidente (*post-mortem*) cuando ya está corregido: qué
   pasó, cuándo se supo, qué se hizo y qué cambia para que no vuelva.

### Divulgación responsable y recompensas

Quien encuentra un fallo en un protocolo desplegado tiene que saber a quién decírselo en privado.
Eso es la **divulgación responsable** (*responsible disclosure*): el fallo se cuenta primero a los
autores, se corrige, y solo después se publica. Un archivo `SECURITY.md` en la raíz del
repositorio dice cómo contactar y qué plazos se compromete el equipo a cumplir; GitHub lo enseña en
la pestaña de seguridad.

Un **programa de recompensas por fallos** (*bug bounty*) paga por los hallazgos que llegan así, en
función de su severidad. Plataformas como Immunefi los gestionan para cientos de protocolos. La
recompensa tiene que compensar más que explotar el fallo: si no, el incentivo va al revés.

### Antes de dinero real

Tu protocolo ha pasado una auditoría propia, herramientas, verificación formal y una auditoría
cruzada. Antes de mover dinero real faltarían, como mínimo: una auditoría profesional del commit
que se va a desplegar, un guardián y un tesorero que sean multifirmas (semana 13) y no cuentas
sueltas, un programa de recompensas, las alertas en marcha y un plan de incidentes probado. Esto no
es parte de la entrega: es lo que el informe dice en `## Limitaciones`.

## Cómo se escribe

**Una versión.** En tu repositorio, en `main` y con el pull request de la semana fusionado:

```bash
git tag -a v1.0.0 -m "Protocolo completo y auditado"
git tag -n
```

**Salida**:

```text
v1.0.0          Protocolo completo y auditado
```

Y `git push origin v1.0.0` la sube: en GitHub, la pestaña *Releases* la muestra, y puedes añadirle
notas con lo que incluye.

**Vigilar los roles.** En el despliegue de la tienda de la teoría 01, en anvil, la lista de quién
recibió un rol en los puntos sale de sus eventos, aunque el contrato no tuviera
`AccessControlEnumerable`:

```bash
cast logs --from-block 0 --address 0x5FbDB2315678afecb367f032d93F642f64180aa3 \
  "RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)" \
  --rpc-url http://127.0.0.1:8545 | grep -E "blockNumber|role:|account:"
```

**Salida**:

```text
  blockNumber: 1
  	role: 0x0000000000000000000000000000000000000000000000000000000000000000
  	account: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
  blockNumber: 3
  	role: 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6
  	account: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
  blockNumber: 3
  	role: 0x0000000000000000000000000000000000000000000000000000000000000000
  	account: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
```

Tres concesiones: el administrador a quien despliega (al crear los puntos), el minter a la tienda
y el administrador al timelock. Los `indexed` de la firma importan: sin ellos, `cast` no sabe que
esos datos van en los *topics* del log y no los decodifica. Con `RoleRevoked` en la misma
llamada sale la cuarta pieza, la renuncia:

```text
  blockNumber: 3
  	role: 0x0000000000000000000000000000000000000000000000000000000000000000
  	account: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

Concesiones menos renuncias es la lista de quién tiene cada rol: lo que contaría una alerta.

**Un `SECURITY.md`.** En la raíz de tu repositorio, para que quien encuentre un fallo sepa qué
hacer:

```markdown
# Seguridad

Si encuentras un fallo de seguridad, no abras un issue público. Escríbeme por los avisos privados
de GitHub (pestaña Security → Report a vulnerability) con el commit, la descripción y, si puedes,
una prueba de concepto en un test de Foundry.

Respondo en 72 horas. Si el fallo afecta a un despliegue, el guardián pausa las altas antes de
corregir. Publico el hallazgo, con tu nombre si quieres, cuando la corrección esté desplegada.

Este protocolo es un proyecto de formación desplegado solo en testnets: no tiene fondos reales ni
programa de recompensas.
```

## Antipatrones y riesgos

- **Entregar una rama.** Una rama se mueve; la auditoría y la demo tienen que citar algo que no
  cambie. Una etiqueta y su commit.
- **Una demo que depende de la red.** Un faucet seco o un RPC lento en directo. Script en anvil y
  salida guardada.
- **Alertas que nadie lee.** Un canal con cien avisos al día es un canal sin avisos. Avisa solo de
  lo que exige actuar: roles, pausas, propuestas en cola, actualizaciones.
- **Improvisar el plan de incidentes.** En un incidente, cada minuto cuenta y nadie piensa bien.
  Quién pausa y cómo, escrito antes.
- **Corregir en silencio.** Si un fallo pudo afectar a usuarios, se cuenta, aunque se haya
  corregido sin pérdidas. El post-mortem es lo que hace que confíen en el siguiente despliegue.
- **Confundir "auditado" con "seguro".** Una auditoría reduce el riesgo de un commit concreto; no
  cubre el siguiente cambio ni la configuración del despliegue.

## Trucos

- Ejecuta `CheckDeployment` en la demo: enseña el despliegue y su comprobación, no solo el
  despliegue.
- Graba la demo una vez antes de presentarla. Si la grabación dura más de diez minutos, recorta el
  guion, no la velocidad.
- En el README, un enlace a cada dirección en el explorador vale más que la dirección sola: quien
  lee puede comprobar que existe y que está verificada.
- Las notas de la versión pueden ser la tabla de capas del hilo conductor con lo que hiciste en
  cada una.

## ✅ Checklist

- [ ] Sé crear una etiqueta anotada y por qué una entrega cita una etiqueta y no una rama.
- [ ] Sé qué cuentan las notas de una versión.
- [ ] Sé qué lleva el README de un portfolio y en qué orden.
- [ ] Sé preparar una demo con guion, script y plan B.
- [ ] Sé qué eventos vigilar y sacar de ellos quién tiene cada rol.
- [ ] Sé qué responde un plan de incidentes y qué es un post-mortem.
- [ ] Sé qué es la divulgación responsable, qué lleva un `SECURITY.md` y qué falta antes de dinero
  real.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 03 — Corregir hallazgos](03-corregir-hallazgos.md) | **Teoría 04 — Entregar y mantener** | [Ejercicio 01 — Un despliegue que se comprueba →](../2-practicas/ejercicio-01-un-despliegue-que-se-comprueba/README.md) |
