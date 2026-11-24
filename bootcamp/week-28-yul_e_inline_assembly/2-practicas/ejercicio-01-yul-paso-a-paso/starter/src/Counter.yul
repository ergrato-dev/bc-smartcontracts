// ¿Qué? Un contador escrito entero en Yul, sin Solidity: un objeto con el código de despliegue y,
//   dentro, el objeto "runtime" con el código que queda en la cadena.
// ¿Para qué? Escribir a mano lo que solc genera por ti: el dispatcher que elige la función por su
//   selector, el storage y la codificación de lo que se devuelve.
// ¿Impacto? Nadie comprueba la calldata ni el ETH que llega: lo que no escribas, no se hace.
object "Counter" {
    // Código de despliegue: guarda 7 en el slot 0 y devuelve el código runtime, que es lo que la
    //   EVM deja en la dirección del contrato.
    code {
        sstore(0, 7)
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }
    object "runtime" {
        code {
            // PASO 5: el dispatcher. Borra la línea que acaba en `<- Paso 5` y descomenta las
            //   líneas que empiezan con `//> `.
            revert(0, 0) // <- Paso 5
            //> switch shr(224, calldataload(0))
            //> // count()
            //> case 0x06661abd {
            //>     mstore(0, sload(0))
            //>     return(0, 0x20)
            //> }
            //> // increment()
            //> case 0xd09de08a {
            //>     sstore(0, add(sload(0), 1))
            //>     return(0, 0)
            //> }
            //> default {
            //>     revert(0, 0)
            //> }
        }
    }
}
