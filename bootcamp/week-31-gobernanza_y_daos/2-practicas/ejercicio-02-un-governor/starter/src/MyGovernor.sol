// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Governor} from "@openzeppelin/contracts/governance/Governor.sol";
import {GovernorSettings} from "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import {GovernorVotes} from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import {GovernorVotesQuorumFraction} from
    "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";

// ¿Qué? Un Governor de OpenZeppelin con el recuento de votos escrito a mano: a favor, en contra y
//   abstención, como GovernorCountingSimple.
// ¿Para qué? Ver qué decide el recuento: quién puede votar y cuántas veces, qué cuenta para el
//   quórum y cuándo gana una propuesta. El resto del ciclo (proponer, la foto, los plazos,
//   ejecutar) es el Governor.
// ¿Impacto? Este contrato ejecuta lo aprobado él mismo: lo que gobierna tiene que ser suyo.
contract MyGovernor is Governor, GovernorSettings, GovernorVotes, GovernorVotesQuorumFraction {
    /// @notice Lo que significa cada valor de `support` al votar.
    enum VoteType {
        Against,
        For,
        Abstain
    }

    struct ProposalVote {
        uint256 againstVotes;
        uint256 forVotes;
        uint256 abstainVotes;
        mapping(address voter => bool) hasVoted;
    }

    mapping(uint256 proposalId => ProposalVote) internal _proposalVotes;

    // PASO 4: los plazos (en bloques) y el mínimo para proponer.
    // Borra la línea que acaba en `// <- Paso 4` y descomenta la de debajo.
    constructor(IVotes token)
        Governor("My Governor")
        GovernorSettings(0, 1, 0) // <- Paso 4
        //> GovernorSettings(7200, 50_400, 10_000 ether)
        GovernorVotes(token)
        GovernorVotesQuorumFraction(4)
    {}

    /// @notice Cómo cuenta este Governor (ERC-6372 y IGovernor): las opciones de Governor Bravo y
    ///   el quórum con a favor y abstención.
    // forge-lint: disable-next-line(mixed-case-function)
    function COUNTING_MODE() public pure override returns (string memory) {
        return "support=bravo&quorum=for,abstain";
    }

    /// @notice Si `account` ya votó la propuesta `proposalId`.
    function hasVoted(uint256 proposalId, address account) public view override returns (bool) {
        return _proposalVotes[proposalId].hasVoted[account];
    }

    /// @notice Los votos de cada opción en la propuesta `proposalId`.
    function proposalVotes(uint256 proposalId)
        external
        view
        returns (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes)
    {
        ProposalVote storage pv = _proposalVotes[proposalId];
        return (pv.againstVotes, pv.forVotes, pv.abstainVotes);
    }

    // PASO 1: anotar un voto. Una vez por cuenta, con `support` de VoteType; devuelve los votos
    // que contaron. `weight` lo calcula el Governor: los votos de `account` en la foto.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function _countVote(uint256 proposalId, address account, uint8 support, uint256 weight, bytes memory)
        internal
        override
        returns (uint256)
    {
        revert("TODO: Paso 1");
        //> ProposalVote storage pv = _proposalVotes[proposalId];
        //> if (pv.hasVoted[account]) revert GovernorAlreadyCastVote(account);
        //> pv.hasVoted[account] = true;
        //> if (support == uint8(VoteType.Against)) {
        //>     pv.againstVotes += weight;
        //> } else if (support == uint8(VoteType.For)) {
        //>     pv.forVotes += weight;
        //> } else if (support == uint8(VoteType.Abstain)) {
        //>     pv.abstainVotes += weight;
        //> } else {
        //>     revert GovernorInvalidVoteType();
        //> }
        //> return weight;
    }

    // PASO 2: el quórum. A favor y abstención cuentan; en contra, no.
    // Borra la línea que acaba en `// <- Paso 2` y descomenta las de debajo.
    function _quorumReached(uint256 proposalId) internal view override returns (bool) {
        return true; // <- Paso 2
        //> ProposalVote storage pv = _proposalVotes[proposalId];
        //> return quorum(proposalSnapshot(proposalId)) <= pv.forVotes + pv.abstainVotes;
    }

    // PASO 3: gana si hay más votos a favor que en contra. Un empate pierde.
    // Borra la línea que acaba en `// <- Paso 3` y descomenta las de debajo.
    function _voteSucceeded(uint256 proposalId) internal view override returns (bool) {
        return true; // <- Paso 3
        //> ProposalVote storage pv = _proposalVotes[proposalId];
        //> return pv.forVotes > pv.againstVotes;
    }

    // Lo que sigue solo resuelve la herencia múltiple: Solidity exige decir cuál gana.

    /// @inheritdoc Governor
    function votingDelay() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.votingDelay();
    }

    /// @inheritdoc Governor
    function votingPeriod() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.votingPeriod();
    }

    /// @inheritdoc Governor
    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.proposalThreshold();
    }

    /// @inheritdoc Governor
    function quorum(uint256 timepoint) public view override(Governor, GovernorVotesQuorumFraction) returns (uint256) {
        return super.quorum(timepoint);
    }
}
