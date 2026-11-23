# 📖 Glosario — Semana 13

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| `AccessControl` | Contrato de OpenZeppelin que reparte permisos en roles | `contract Registry is AccessControl` |
| Control de acceso | La parte de un contrato que decide quién puede llamar a cada función | `onlyOwner`, `onlyRole` |
| `DEFAULT_ADMIN_ROLE` | El rol `0x00`: administra todos los roles, también a sí mismo, salvo que se cambie | `_grantRole(DEFAULT_ADMIN_ROLE, msg.sender)` |
| Guardián | Cuenta que solo puede pausar, sin plazo, en una emergencia | `PAUSER_ROLE` de la guardiana |
| Mínimo privilegio | Principio: cada cuenta tiene solo los permisos que necesita para su tarea | Quien pausa no retira tasas |
| Multisig | Contrato que actúa como una cuenta y solo ejecuta lo que confirman M de sus N dueños | Un "2 de 3" |
| `onlyRole` | Modificador que revierte con `AccessControlUnauthorizedAccount` si quien llama no tiene el rol | `onlyRole(PAUSER_ROLE)` |
| Operación (timelock) | Una llamada programada en un timelock, identificada por el hash de sus datos | `schedule(target, 0, data, 0x0, 0x0, 3600)` |
| `Ownable` | Contrato de OpenZeppelin con un dueño que se puede transferir y renunciar | `Ownable(msg.sender)` |
| `Ownable2Step` | `Ownable` en el que el nuevo dueño tiene que aceptar con `acceptOwnership` | `pendingOwner()` |
| Parada de emergencia | Interruptor que bloquea las funciones peligrosas mientras se decide qué hacer | `pause()` |
| `Pausable` | Contrato de OpenZeppelin con `whenNotPaused`, `whenPaused`, `_pause` y `_unpause` | `deposit() whenNotPaused` |
| `pendingOwner` | Dirección a la que se ofreció la propiedad en `Ownable2Step` y que aún no la aceptó | `0x7099…79C8` |
| `renounceOwnership` | Deja el dueño en `address(0)`: nadie vuelve a pasar `onlyOwner` | Desactivada en `Vault` |
| Rol | Un `bytes32` con nombre que agrupa permisos | `keccak256("PAUSER_ROLE")` |
| Rol administrador | El rol que puede dar y quitar otro rol | `_setRoleAdmin(EDITOR_ROLE, MODERATOR_ROLE)` |
| Timelock | Contrato que ejecuta llamadas con un plazo mínimo, después de publicarlas | `TimelockController` con 3600 s |
| Umbral | Cuántas confirmaciones necesita un multisig para ejecutar | `THRESHOLD = 2` |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | Semana 14 (próximamente) |
