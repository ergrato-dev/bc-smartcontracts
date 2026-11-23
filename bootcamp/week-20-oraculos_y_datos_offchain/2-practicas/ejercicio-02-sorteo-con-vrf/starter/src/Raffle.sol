// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

// ¿Qué? Un sorteo: cada jugador paga 0,01 ETH y un número aleatorio de Chainlink VRF elige quién
//   se lleva el bote.
// ¿Para qué? Que nadie (ni el dueño, ni quien produce el bloque) pueda elegir o prever el
//   ganador: el número llega con una prueba que el coordinador de VRF comprueba en la cadena.
// ¿Impacto? El sorteo va en dos transacciones: `draw` pide el número y, unos bloques después, el
//   coordinador llama a `fulfillRandomWords` con él. Entre medias, nadie entra.
contract Raffle is VRFConsumerBaseV2Plus {
    uint256 public constant ENTRY_FEE = 0.01 ether;
    uint256 public constant MAX_PLAYERS = 20;
    /// @notice Bloques que espera el coordinador antes de responder: un reorg corto no cambia el número.
    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    /// @notice Gas máximo de `fulfillRandomWords`. Si se pasa, el coordinador no reintenta.
    uint32 public constant CALLBACK_GAS_LIMIT = 200_000;
    /// @notice Tras este tiempo sin respuesta, el dueño puede cancelar el sorteo pendiente.
    uint256 public constant DRAW_TIMEOUT = 1 hours;

    /// @notice El carril de gas de VRF (cuánto se está dispuesto a pagar por el gas de la respuesta).
    bytes32 public immutable KEY_HASH;
    /// @notice La suscripción de VRF que paga los números.
    uint256 public immutable SUBSCRIPTION_ID;

    address[] public players;
    bool public drawing;
    uint256 public pendingRequestId;
    uint256 public drawRequestedAt;
    address public lastWinner;
    mapping(address => uint256) public prizes;

    event Entered(address indexed player);
    event DrawRequested(uint256 indexed requestId);
    event WinnerPicked(uint256 indexed requestId, address indexed winner, uint256 prize);
    event DrawCancelled(uint256 indexed requestId);

    error WrongFee(uint256 sent);
    error RaffleFull();
    error DrawInProgress();
    error NoPlayers();
    error UnknownRequest(uint256 requestId);
    error NoDrawPending();
    error TooEarly(uint256 availableAt);
    error NothingToWithdraw();
    error TransferFailed();

    /// @param coordinator El coordinador de VRF de la red.
    /// @param subscriptionId La suscripción que paga, con este contrato como consumidor.
    /// @param keyHash El carril de gas.
    constructor(address coordinator, uint256 subscriptionId, bytes32 keyHash) VRFConsumerBaseV2Plus(coordinator) {
        SUBSCRIPTION_ID = subscriptionId;
        KEY_HASH = keyHash;
    }

    /// @notice Cuántos jugadores hay en el sorteo abierto.
    function playerCount() external view returns (uint256) {
        return players.length;
    }

    // PASO 1: entrar pagando la entrada exacta, si no hay un sorteo en curso ni está lleno.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    /// @notice Entra en el sorteo pagando ENTRY_FEE.
    function enter() external payable {
        revert("TODO: Paso 1");
        //> if (drawing) revert DrawInProgress();
        //> if (msg.value != ENTRY_FEE) revert WrongFee(msg.value);
        //> if (players.length >= MAX_PLAYERS) revert RaffleFull();
        //> players.push(msg.sender);
        //> emit Entered(msg.sender);
    }

    // PASO 2: pedir un número aleatorio al coordinador y cerrar la entrada.
    /// @notice Pide el número que elegirá al ganador. Solo el dueño.
    function draw() external onlyOwner returns (uint256 requestId) {
        revert("TODO: Paso 2");
        //> if (drawing) revert DrawInProgress();
        //> if (players.length == 0) revert NoPlayers();
        //> drawing = true;
        //> drawRequestedAt = block.timestamp;
        //> requestId = s_vrfCoordinator.requestRandomWords(
        //>     VRFV2PlusClient.RandomWordsRequest({
        //>         keyHash: KEY_HASH,
        //>         subId: SUBSCRIPTION_ID,
        //>         requestConfirmations: REQUEST_CONFIRMATIONS,
        //>         callbackGasLimit: CALLBACK_GAS_LIMIT,
        //>         numWords: 1,
        //>         extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        //>     })
        //> );
        //> pendingRequestId = requestId;
        //> emit DrawRequested(requestId);
    }

    // PASO 3: con el número, elegir al ganador y apuntarle el bote, sin enviarle nada.
    // `rawFulfillRandomWords` (de VRFConsumerBaseV2Plus) ya comprobó que llama el coordinador.
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        revert("TODO: Paso 3");
        //> if (!drawing || requestId != pendingRequestId) revert UnknownRequest(requestId);
        //> address winner = players[randomWords[0] % players.length];
        //> uint256 prize = players.length * ENTRY_FEE;
        //> delete players;
        //> drawing = false;
        //> lastWinner = winner;
        //> prizes[winner] += prize;
        //> emit WinnerPicked(requestId, winner, prize);
    }

    // PASO 4: cada ganador retira su premio.
    /// @notice Envía a quien llama todo lo que ha ganado.
    function withdraw() external {
        revert("TODO: Paso 4");
        //> uint256 amount = prizes[msg.sender];
        //> if (amount == 0) revert NothingToWithdraw();
        //> prizes[msg.sender] = 0;
        //> (bool ok,) = msg.sender.call{value: amount}("");
        //> if (!ok) revert TransferFailed();
    }

    // PASO 5: si VRF no responde, reabrir el sorteo tras DRAW_TIMEOUT.
    /// @notice Cancela el sorteo pendiente: los jugadores siguen dentro y se puede volver a pedir.
    function cancelDraw() external onlyOwner {
        revert("TODO: Paso 5");
        //> if (!drawing) revert NoDrawPending();
        //> uint256 availableAt = drawRequestedAt + DRAW_TIMEOUT;
        //> if (block.timestamp < availableAt) revert TooEarly(availableAt);
        //> drawing = false;
        //> emit DrawCancelled(pendingRequestId);
        //> pendingRequestId = 0;
    }
}
