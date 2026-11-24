# Proyecto — Specs de tu protocolo

> Escribes con Halmos las specs de las reglas de acceso y de cobro de tu protocolo, las
> demuestras para cualquier llamante, valor y argumento, y compruebas con mutantes que de verdad
> atrapan fallos. Añades al informe qué se demostró, con qué límites, y qué no se pudo demostrar.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana en verde; tu proyecto de la semana 24 en
`main`.

## Capa que se añade y por qué ahora

Las invariantes de la semana 24 prueban secuencias, pero con tres cuentas, unos pocos valores y
las acciones que tiene el handler. Lo que más importa de tu protocolo son reglas que deben valer
para **cualquiera**: que una cuenta sin roles no toque la configuración, que nadie retire lo que
no es suyo, que en pausa no entre ninguna alta, que se cobre la tasa exacta pague lo que pague
quien llama. Esta semana las demuestras con Halmos, para todos los valores de cada parámetro.

El SMTChecker no entra en el proyecto: tu protocolo usa errores personalizados, OpenZeppelin y
llamadas a otros contratos, y con eso solo daría avisos de lo que no entiende (teoría 02).

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-25
   ```

2. Copia el starter en `week-25/` y pon encima tus contratos, tus invariantes, tu detector y tu
   informe de la semana 24:

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-25-verificacion_formal/3-proyecto/starter week-25
   cp -r week-24/contracts/src week-24/contracts/script week-25/contracts/
   cp -r week-24/contracts/test/invariant week-25/contracts/test/
   cp week-24/detectors/unpaused_register.py week-25/detectors/
   cp -r week-24/audit week-25/
   ls -l week-25/contracts/lib
   ```

   **Verifica**: `lib -> /opt/lib`. Tus `src/`, `script/`, `test/invariant/` y tu detector son
   los de la semana 24, y `week-25/audit/README.md`, tu informe.

3. Entra al contenedor y mira el rojo:

   ```bash
   cd week-25
   docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
   bash test.sh
   ```

**Verifica**: `forge test` pasa, `27 tests passed`, y `test.sh` se para en Halmos:

```text
[FAIL] check_pausedRejectsRegistrations(address,uint256,uint8,uint256) (paths: 4, time: 0.02s, bounds: [])
[FAIL] check_perAccountLimit(address) (paths: 3, time: 0.01s, bounds: [])
[PASS] check_registerChargesExactFee(address,uint256) (paths: 6, time: 0.15s, bounds: [])
[FAIL] check_retireOnlyByHolder(address) (paths: 3, time: 0.02s, bounds: [])
[FAIL] check_strangerCannotAdmin(address,uint8,address,uint256,uint256,bytes32) (paths: 5, time: 0.02s, bounds: [])
Symbolic test result: 1 passed; 4 failed; time: 0.36s
```

## Qué hay en el starter

| Ruta | Qué es |
| ---- | ------ |
| `contracts/src/`, `contracts/script/`, `contracts/test/invariant/` | Los de la solución de la semana 24: tu referencia. Tú usas los tuyos |
| `contracts/test/formal/RegistrySpec.t.sol` | **Tu trabajo**: las specs. El `setUp` y una spec hechos; cuatro con su `// TODO` |
| `contracts/foundry.toml` | Con `ast = true` para Halmos (teoría 03). `dynamic_test_linking = false` ya estaba |
| `contracts/test/` (el resto) | Los tests de las semanas 20 a 24 |
| `detectors/` | El detector de la semana 23; pon encima el tuyo |
| `mutants.sh` | Los cuatro mutantes de la semana 24 y seis nuevos para las specs. **No lo modifiques** |
| `test.sh` | Lo de la semana 24, con Halmos después de `forge test` |

## El `setUp`

`RegistrySpec` despliega el protocolo en V3, con capacidad 10 y 5 altas por cuenta, y es su
administrador. No usa el handler de la semana 24: el handler calcula la dirección del proxy con
la fórmula de `CREATE`, y Halmos no da esa dirección (teoría 04). En su lugar, el proxy va a una
dirección elegida, `0x5E6157A7`, con `vm.etch` y `vm.store`. Lee el `setUp` entero antes de
seguir: al final da 1 ETH al registro, y una de tus specs lo necesita.

## Las specs

Ya está hecha, como modelo:

| Spec | Qué demuestra |
| ---- | ------------- |
| `check_registerChargesExactFee(caller, value)` | Cualquier cuenta sin código que pague cualquier `value`: el registro se queda la tasa exacta y devuelve el resto |

Fíjate en el `vm.assume`: una cuenta con código podría rechazar la devolución, y `address(0)` no
envía transacciones.

Las cuatro que escribes:

| # | Spec | Qué demuestra |
| - | ---- | ------------- |
| 1 | `check_retireOnlyByHolder(caller)` | Una cuenta fija da de alta; `retire` sale bien si y solo si `caller` es esa cuenta, y solo entonces baja `activeCount` |
| 2 | `check_perAccountLimit(caller)` | Tras `MAX_PER_ACCOUNT` altas de `caller`, la siguiente se rechaza |
| 3 | `check_strangerCannotAdmin(caller, which, a, x, y, role)` | Una cuenta sin roles no puede llamar a ninguna de las diez funciones privilegiadas, con ningún argumento |
| 4 | `check_pausedRejectsRegistrations(caller, value, which, deadline)` | En pausa, ninguna de las cinco formas de alta sale bien |

Para las specs 3 y 4, la lista de funciones es explícita, con `which` como selector simbólico
(teoría 04). Recuerda que en Halmos revertir no es fallar: lo que debe rechazarse se comprueba con
`try` o con `call` y un `assert` sobre el resultado.

Si tu protocolo tiene reglas propias de tu dominio (otro rol, otra forma de pago, otro límite),
añade su spec.

## Cómo verificar

```bash
bash test.sh
```

**Verifica**, en este orden:

- `27 tests passed`.
- Halmos: `Symbolic test result: 5 passed; 0 failed`, en un par de segundos y **sin ningún
  `WARNING`** de bucles ni de caminos revertidos.
- `forge lint` sin avisos y Slither con `0 result(s) found`.
- `2 passed` en los tests del detector.
- Medusa: `Test summary: 13 test(s) passed, 0 test(s) failed`.
- `mutants.sh`, los diez muertos:

  ```text
  ✅ retire no resta el activo: muerto
  ✅ no se devuelve lo pagado de más: muerto
  ✅ el alta con puntos no quema: muerto
  ✅ una alta de más por cuenta: muerto
  ✅ devuelve 1 wei de más: muerto
  ✅ cualquiera retira: muerto
  ✅ sin límite por cuenta: muerto
  ✅ cualquiera cambia la tasa: muerto
  ✅ cualquiera se lleva las tasas: muerto
  ✅ se registra en pausa: muerto
  ```

`test.sh` tarda unos tres minutos y medio. Los seis últimos mutantes los mata Halmos: si uno
sobrevive, la spec que lo debía matar no mira ahí. `cualquiera retira` sobrevive si
`check_retireOnlyByHolder` solo comprueba que el dueño puede, y `cualquiera se lleva las tasas`,
si el registro no tiene saldo. Si un mutante dice que la expresión no cambia el archivo, tu línea
es distinta de la de la solución de referencia: compárala, no modifiques `mutants.sh`.

Si una spec da `TIMEOUT` unas veces sí y otras no, ejecútala varias veces con `--solver z3`
(teoría 03) antes de cambiarla.

## El informe de auditoría

Añade a `week-25/audit/README.md`, antes de `## Hallazgos`:

1. **Las specs**, una por fila, con lo que demuestran.
2. **La herramienta**: Halmos, versión, solver, opciones y resultado.
3. **Los mutantes** de Halmos y qué spec mata cada uno.
4. **Lo que no se demostró**: lo que diste por fijo (`"label"`, el estado de `setUp`), lo que
   intentaste y dio `TIMEOUT`, las funciones que no están en tus listas y las secuencias.

```markdown
## Verificación formal (semana 25)

| Spec | Qué demuestra |
| ---- | ------------- |
| `registerChargesExactFee` | Para cualquier cuenta y cualquier `msg.value`, ... |
| ... | ... |

| Herramienta | Versión | Configuración | Resultado |
| ----------- | ------- | ------------- | --------- |
| Halmos | 0.3.2 | ... | ... |

| Mutante (`mutants.sh`) | Lo mata |
| ---------------------- | ------- |
| `_refundExcess` devuelve 1 wei de más | `registerChargesExactFee` |
| ... | ... |

Lo que esta verificación **no** demuestra: ...
```

Si una spec encuentra un fallo en tu protocolo, es un hallazgo: H-04, con el formato de los
anteriores, su contraejemplo convertido en test como prueba y su corrección. Si no encuentra
ninguno, escríbelo así: "sin hallazgos nuevos", con lo que sí se demostró.

## Ejemplos de adaptación

| Dominio | Una spec propia |
| ------- | --------------- |
| Biblioteca | Para cualquier socio y cualquier libro, solo quien lo tiene prestado puede devolverlo |
| Tienda en línea | Para cualquier comprador y cualquier precio, la tienda recibe el precio exacto y el resto se devuelve |
| Cine | Para cualquier cuenta, en una sesión cerrada ninguna forma de compra sale bien |

## Criterios de calidad (no automatizables)

- Cada spec dice una promesa del protocolo, no repite su código.
- Lo que debe aceptarse se comprueba con `try` o `call` y un `assert`, no con una llamada directa.
- Cada `vm.assume` tiene un motivo, escrito en un comentario o en el informe.
- El informe dice qué se demostró, con qué límites, y qué no.

## Entrega

1. `bash test.sh` acaba sin error: tests, specs, `forge lint`, Slither, detector, Medusa y
   mutantes en verde.
2. `week-25/audit/README.md` con la sección de verificación formal.
3. Commit y pull request:

   ```bash
   git add week-25
   git commit -m "test(week-25): add Halmos specs for access and fee rules"
   git push -u origin week-25
   ```

   Abre el pull request `week-25` → `main` y fusiónalo cuando esté en verde.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Specs de contrato](../2-practicas/ejercicio-03-specs-de-contrato/README.md) | **Proyecto — Specs de tu protocolo** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
