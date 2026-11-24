# Rúbrica de evaluación — Semana 30: DeFi

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: un vault de puntos |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | En un pool de 100 A y 400 B, ¿por qué 10 A dan 36,26 B y no 40? Separa lo que se lleva la comisión de lo que es impacto en el precio | 10 |
| 2 | ¿Por qué la comisión hace crecer `x · y`, y quién se queda con ese crecimiento? | 10 |
| 3 | ¿Por qué el primer proveedor de liquidez recibe `√(x · y) − 1000` shares? ¿Qué pasaría sin las 1000? | 10 |
| 4 | El precio de A pasa de 4 B a 9 B. ¿Cuánto pierde un proveedor frente a guardar sus tokens, y por qué, si el pool no perdió nada? | 10 |
| 5 | ¿Por qué `deposit` redondea las shares hacia abajo y `mint` el activo hacia arriba? ¿Qué pasaría si las dos redondearan hacia abajo? | 10 |
| 6 | En el ejercicio 02, el paso 2 rompe `testFuzz_WithdrawMaxBurnsEveryShare`, que estaba en verde. ¿Por qué, y por qué lo arregla el paso 3? | 10 |
| 7 | ¿Qué hace `_decimalsOffset` y por qué, con offset 3, el atacante del ataque de inflación pierde la mitad de lo que regala? | 10 |
| 8 | Con 2 ETH de garantía a 2000 y 3000 de deuda, ¿a qué precio te pueden liquidar? ¿Para qué sirven el premio y el close factor? | 10 |
| 9 | ¿Por qué un protocolo de préstamos lleva el interés con un índice en vez de actualizar cada deuda? ¿Qué pasa si `borrow` no actualiza el índice primero? | 10 |
| 10 | En el proyecto, ¿por qué `setStakingVault` es de una sola vez, y por qué el bonus de antes del primer depósito no se lo lleva el primero en depositar? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. Sin comisión saldrían `400 · 10 / 110 = 36,36`, no 40: cada A que metes encuentra menos B y más
   A en el pool, así que vale menos que la anterior. Eso es el impacto en el precio, y ya cuesta
   un 9,1 %. La comisión del 0,3 % se descuenta de la entrada (el pool paga por 9,97 A) y baja la
   salida a 36,26. Juntos, un 9,3 % frente al precio marginal de 4.
2. El pool recibe la entrada entera pero paga la salida como si hubiera entrado un 0,3 % menos:
   ese 0,3 % se queda en la reserva y el producto de las reservas crece. No se emiten shares por
   él, así que cada LP share pasa a valer más: lo cobran los proveedores de liquidez, en
   proporción a sus shares, al retirar.
3. La media geométrica no depende del precio ni del token en que se mida, y escala con las
   reservas. Las 1000 shares bloqueadas en `0xdead` impiden el ataque de inflación: sin ellas, el
   primero podría dejar 1 share, regalar tokens al pool y hacer que una share valga tanto que las
   aportaciones de otros redondeen a cero shares.
4. Un 7,7 %: el arbitraje compra A en el pool hasta que su precio es 9, y el pool queda con 66,67 A
   y 600 B, que valen 1200 B; los 100 A y 400 B guardados valdrían 1300 B. El pool no pierde: el
   valor se lo lleva el arbitrajista, que compró A más barato que fuera. Es la fórmula
   `2 · √r / (1 + r) − 1` con `r` = 2,25. Las comisiones compensan una parte.
5. Las dos redondean a favor del vault, de quien ya está dentro: en `deposit` recibes de menos y en
   `mint` pagas de más. Si `mint` redondeara hacia abajo, pedir shares podría salir un wei más
   barato de lo que valen, y repetirlo sacaría valor de los demás, un wei cada vez.
6. Con el paso 2, `previewRedeem` descuenta la comisión, y `maxWithdraw` de OpenZeppelin es
   `previewRedeem` de todas tus shares: el máximo ya tiene la comisión restada. Pero `withdraw`
   seguía sin cobrarla y quemaba menos shares de las que tienes: te quedaban shares con valor.
   El paso 3 cobra la comisión también en `previewWithdraw`, y retirar el máximo cuesta todas tus
   shares: las dos salidas vuelven a costar lo mismo.
7. Cuenta como si siempre hubiera `10^offset` shares y 1 de activo más. Con offset 3, el atacante
   que deposita 1 wei recibe 1000 shares y las virtuales son otras 1000: el regalo de 100 se
   reparte entre las dos mitades, y él solo puede sacar unos 50. La víctima recibe casi 2000
   shares y saca 99,975 de sus 100.
8. A 1875: `3000 / (2 · 0,8)`. Por debajo, la salud baja de 1. El premio (5 %) paga al liquidador
   por vigilar y pagar el gas, para que se liquide pronto, antes de que la garantía valga menos que
   la deuda. El close factor (50 %) limita cada liquidación a la mitad de la deuda: la posición
   vuelve a estar sana sin perder toda la garantía.
9. Actualizar cada deuda exigiría recorrer todas las cuentas, y no cabe en una transacción. Con un
   índice, cada cuenta guarda su deuda escalada y una escritura del índice mueve las de todos.
   Si `borrow` no lo actualiza antes, el interés desde la última actualización se calcularía sobre
   la deuda nueva, y quien acaba de pedir pagaría el interés de un tiempo en el que no debía.
10. Si se pudiera cambiar, quien controla la clave del administrador desviaría el bonus a otra
    dirección, y los depositantes no sabrían a qué vault llega (T-14). El bonus de antes del
    primer depósito llega a un vault sin shares: con el offset de 6, ese bonus es de las shares
    virtuales, así que el primero en depositar recibe shares por lo que mete, no por lo que había
    (T-13). El precio: ese bonus se queda en el vault para siempre.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Un AMM | `forge test` sin error: `10 tests passed, 0 failed` | 15 |
| | Explica por qué `bob` pierde 25 A en el paso 3 y de dónde sale lo que `alice` gana de más en el paso 5 | 10 |
| 02 — Un vault con comisiones | `forge test` sin error: `9 tests passed, 0 failed` | 15 |
| | Explica qué funciones del estándar cambió cada paso y por qué el paso 2 rompe un test que el 3 arregla | 10 |
| 03 — Un préstamo con garantía | `forge test` sin error: `9 tests passed, 0 failed` | 15 |
| | Calcula a mano la salud, el precio de liquidación y la garantía que se lleva el liquidador del test del paso 4 | 15 |
| Todos | Sin tocar `foundry.toml` ni los tests | 20 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-30/` sin `out/`, `cache/` ni `crytic-export/`, con `contracts/snapshots/RegisterGasTest.json`, y pull request `week-30` → `main` | 10 |
| `bash test.sh` sin error: informe, gas con snapshots, 53 tests, specs, `forge lint`, Slither, detector, Medusa y los veinticuatro mutantes muertos | 25 |
| `PointsVault` con offset 6, `setStakingVault` de una vez y solo del admin, el bonus solo al vault, y el despliegue que lo conecta | 25 |
| Informe: alcance, actores, activos, T-13 a T-15 con su prueba, y la sección `## Vault de puntos (semana 30)` con el gas de tus snapshots | 25 |
| Decisión sobre T-15 con tus números: por qué se acepta o cómo lo corriges | 15 |

**Total**: 100 puntos → 30 % de la nota.

---

## 🏅 Bandas

| Banda | Rango |
| ----- | ----- |
| Sobresaliente | 90-100 |
| Notable | 80-89 |
| Aprobado | 70-79 |
| No aprobado | < 70 en alguna evidencia |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Proyecto — Un vault de puntos](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
