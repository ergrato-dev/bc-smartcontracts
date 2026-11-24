# 📖 Glosario — Semana 25

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| BMC (*bounded model checking*) | Motor del SMTChecker que analiza cada función por separado, sin seguir secuencias de transacciones | `engine = "bmc"` |
| Camino | Una de las ejecuciones posibles de un programa con entradas simbólicas, una por cada combinación de ramas | Los dos caminos de `tryCode` |
| CHC (*constrained Horn clauses*) | Motor del SMTChecker que razona sobre cualquier secuencia de transacciones, buscando una invariante del contrato | `engine = "chc"` |
| Condición de camino | Lo que tiene que cumplirse en las entradas para que la ejecución pase por un camino | `code ^ 0x5eed5eed5eed == 0x1234abcd9876` |
| Contraejemplo | Entradas que, según el solver, hacen fallar una aserción | `p_code_uint64_87621e2_00 = 0x4cd9f520c69b` |
| Contraejemplo espurio | Contraejemplo que la herramienta cree posible y la EVM no, porque el modelo no entiende algo del código | `reserve(8)` con un máximo de 4 |
| Ejecución simbólica | Ejecutar un programa con las entradas como incógnitas y seguir todos sus caminos | Halmos con los parámetros de un `check_` |
| Especificación (*spec*) | Lo que el código debe hacer, escrito de forma precisa para poder comprobarlo | `check_retireOnlyByHolder` |
| Invariante del contrato | Fórmula sobre el estado que el constructor cumple y que ninguna función rompe | `!((sold + reserved) >= 11)` |
| Llamada simbólica | Calldata que representa cualquier función de un contrato con cualquier argumento | `svm.createCalldata("Token")` |
| Límite de bucle | Cuántas vueltas sigue Halmos un bucle con límite simbólico; lo que pasa después no se explora | `--loop 11` |
| Modelo | La representación del programa y su entorno sobre la que razona la herramienta | Las direcciones `0xaaaa0001...` de Halmos |
| `sat` / `unsat` | Respuestas del solver: hay valores que cumplen la fórmula, o no hay ninguno | `sat` da un contraejemplo; `unsat` demuestra el camino |
| SMTChecker | Verificador formal dentro de `solc` que intenta demostrar los `assert` al compilar | `[profile.default.model_checker]` |
| Solver SMT | Programa que decide si una fórmula sobre enteros, vectores de bits o arrays tiene solución | z3, yices |
| Spec vacía (*vacuous*) | Spec que pasa porque ninguna entrada, o ninguna de las que importan, llega a la aserción | `check_DisjointAccepted` sin `try` |
| Verificación formal | Demostrar con un razonamiento mecánico que el código cumple una especificación para todos los casos | Halmos, el SMTChecker |
| Vector de bits | Número de ancho fijo con la aritmética de la máquina, que da la vuelta al desbordarse | Un `uint256` para el solver |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | Semana 26 (próximamente) |
