# 📖 Glosario — Semana 15

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| Actualizar (*upgrade*) | Cambiar la implementación a la que reenvía un proxy, sin cambiar su dirección ni su estado | `upgradeToAndCall(v2, data)` |
| Beacon | Contrato que guarda una implementación para muchos proxies a la vez | `UpgradeableBeacon` |
| Choque de selectores | Una función del proxy y otra de la implementación con el mismo selector: la del proxy tapa a la otra | `upgradeTo` en el proxy del ejercicio 01 |
| EIP-1967 | Estándar de slots fijos para la implementación y el administrador de un proxy | `0x3608…bbc` |
| ERC-7201 | Storage con espacio de nombres: las variables de un contrato van en un struct, en un slot calculado a partir de un nombre | `erc7201:openzeppelin.storage.Ownable` |
| Espacio de nombres (*namespace*) | En ERC-7201, el nombre del que sale el slot de un struct de storage | `cast index-erc7201 openzeppelin.storage.Ownable` |
| Implementación (lógica) | Contrato con el código que ejecuta un proxy con `delegatecall`; su propio storage no se usa | `CounterV1`, `Registry` |
| `initialize` | Función que hace lo que haría el constructor, sobre el storage del proxy, una sola vez | `initialize(capacity, token, nft)` |
| `initializer` | Modificador de `Initializable` que deja ejecutar una función una sola vez | `function initialize(...) external initializer` |
| Migrar | Desplegar un contrato nuevo y pedir a todos que usen su dirección, copiando el estado si se puede | La alternativa al proxy |
| `ProxyAdmin` | Contrato que el proxy transparent crea como su administrador; su dueño actualiza | `proxyAdmin.upgradeAndCall(...)` |
| `proxiableUUID` | Función de UUPS que devuelve el slot de EIP-1967: dice que la implementación sabe actualizarse | `0x3608…bbc` |
| Proxy | Contrato que guarda el estado y reenvía cada llamada a una implementación con `delegatecall` | `ERC1967Proxy` |
| `reinitializer(n)` | Modificador que deja inicializar una vez la versión `n` en un proxy ya inicializado | `initializeV2(...) reinitializer(2)` |
| Storage layout | Qué variable ocupa cada slot de storage | `forge inspect Registry storageLayout` |
| Transparent (proxy) | Proxy que solo deja al administrador llamar a sus funciones y reenvía todo lo de los demás | `TransparentUpgradeableProxy` |
| UUPS | Patrón en el que la función de actualizar está en la implementación, protegida por `_authorizeUpgrade` (ERC-1822) | `UUPSUpgradeable` |
| `_disableInitializers` | Función que cierra un contrato para siempre a `initialize` y `reinitializer` | En el constructor de la implementación |
| `_authorizeUpgrade` | Función que escribe cada contrato UUPS para decir quién puede actualizar | `onlyRole(DEFAULT_ADMIN_ROLE)` |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | [Semana 16 — Despliegue y verificación →](../../week-16-despliegue_y_verificacion/README.md) |
