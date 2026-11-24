// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

// ¿Qué? Un ERC-20 con votos, escrito a mano: cada cuenta delega sus votos en otra (o en sí misma)
//   y el token guarda, por cada delegado, una lista de checkpoints con sus votos de cada bloque.
// ¿Para qué? Ver por dentro lo que hace `ERC20Votes` de OpenZeppelin: una gobernanza que pregunta
//   "¿cuántos votos tenías en el bloque N?" no se puede mover con tokens comprados o prestados
//   después de N.
// ¿Impacto? Cada transferencia entre cuentas con delegado escribe checkpoints: más gas por
//   transferencia. Quien no delega no tiene votos ni paga ese gas.
contract VotesToken is ERC20 {
    /// @notice Los votos de un delegado desde el bloque `fromBlock`.
    struct Checkpoint {
        uint48 fromBlock;
        uint208 votes;
    }

    /// @notice En quién delega cada cuenta. `address(0)`: en nadie.
    mapping(address account => address delegatee) public delegates;
    mapping(address delegatee => Checkpoint[]) internal _checkpoints;
    Checkpoint[] internal _totalCheckpoints;

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint256 previousVotes, uint256 newVotes);

    error FutureLookup(uint256 blockNumber, uint256 currentBlock);

    constructor() ERC20("Votes Token", "VOTE") {}

    // PASO 1: delegar mueve todos tus votos del delegado de antes al nuevo.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    /// @notice Delega los votos de todo tu saldo, el de ahora y el que llegue, en `delegatee`.
    function delegate(address delegatee) external {
        revert("TODO: Paso 1");
        //> address previous = delegates[msg.sender];
        //> delegates[msg.sender] = delegatee;
        //> emit DelegateChanged(msg.sender, previous, delegatee);
        //> _moveVotes(previous, delegatee, balanceOf(msg.sender));
    }

    /// @notice Los votos de `account` ahora: los de su último checkpoint.
    function getVotes(address account) public view returns (uint256) {
        uint256 n = _checkpoints[account].length;
        return n == 0 ? 0 : _checkpoints[account][n - 1].votes;
    }

    /// @notice Los votos que tenía `account` al acabar el bloque `blockNumber`.
    /// @dev Solo bloques ya cerrados: los votos del bloque actual todavía pueden cambiar en él.
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256) {
        if (blockNumber >= block.number) revert FutureLookup(blockNumber, block.number);
        return _upperLookup(_checkpoints[account], blockNumber);
    }

    /// @notice Los tokens que existían al acabar el bloque `blockNumber`: la base del quórum.
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256) {
        if (blockNumber >= block.number) revert FutureLookup(blockNumber, block.number);
        return _upperLookup(_totalCheckpoints, blockNumber);
    }

    /// @notice Cuántos checkpoints tiene `account`.
    function numCheckpoints(address account) external view returns (uint256) {
        return _checkpoints[account].length;
    }

    /// @notice El checkpoint número `pos` de `account`.
    function checkpoints(address account, uint256 pos) external view returns (Checkpoint memory) {
        return _checkpoints[account][pos];
    }

    // Mint, burn y transfer pasan por aquí.
    function _update(address from, address to, uint256 value) internal override {
        // PASO 3: los votos siguen a los tokens: de su delegado al del que los recibe.
        // Borra la línea que acaba en `// <- Paso 3` y descomenta las de debajo.
        super._update(from, to, value); // <- Paso 3
        //> super._update(from, to, value);
        //> _moveVotes(delegates[from], delegates[to], value);
        // PASO 5: un checkpoint del total en cada mint y cada burn: el quórum se calcula sobre él.
        // Descomenta la línea de debajo.
        //> if (from == address(0) || to == address(0)) _push(_totalCheckpoints, totalSupply());
    }

    // Resta `amount` votos a `from` y se los suma a `to`. `address(0)` es "nadie": sin checkpoint.
    function _moveVotes(address from, address to, uint256 amount) internal {
        if (from == to || amount == 0) return;
        if (from != address(0)) {
            uint256 before = getVotes(from);
            _push(_checkpoints[from], before - amount);
            emit DelegateVotesChanged(from, before, before - amount);
        }
        if (to != address(0)) {
            uint256 before = getVotes(to);
            _push(_checkpoints[to], before + amount);
            emit DelegateVotesChanged(to, before, before + amount);
        }
    }

    // PASO 2: un checkpoint por bloque. Si el último es de este bloque, se sobrescribe.
    // Borra la línea que acaba en `// <- Paso 2` y descomenta las de debajo.
    function _push(Checkpoint[] storage ckpts, uint256 votes) internal {
        ckpts.push(Checkpoint(SafeCast.toUint48(block.number), SafeCast.toUint208(votes))); // <- Paso 2
        //> uint256 n = ckpts.length;
        //> if (n > 0 && ckpts[n - 1].fromBlock == block.number) {
        //>     ckpts[n - 1].votes = SafeCast.toUint208(votes);
        //> } else {
        //>     ckpts.push(Checkpoint(SafeCast.toUint48(block.number), SafeCast.toUint208(votes)));
        //> }
    }

    // PASO 4: el valor del último checkpoint con `fromBlock <= blockNumber`, por búsqueda
    // binaria: los checkpoints están ordenados por bloque.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function _upperLookup(Checkpoint[] storage ckpts, uint256 blockNumber) internal view returns (uint256) {
        revert("TODO: Paso 4");
        //> uint256 low = 0;
        //> uint256 high = ckpts.length;
        //> while (low < high) {
        //>     uint256 mid = Math.average(low, high);
        //>     if (ckpts[mid].fromBlock > blockNumber) {
        //>         high = mid;
        //>     } else {
        //>         low = mid + 1;
        //>     }
        //> }
        //> return high == 0 ? 0 : ckpts[high - 1].votes;
    }
}
