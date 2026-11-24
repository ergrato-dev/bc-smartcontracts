// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Governor} from "@openzeppelin/contracts/governance/Governor.sol";
import {GovernorSettings} from "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import {GovernorCountingSimple} from "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import {GovernorVotes} from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import {GovernorVotesQuorumFraction} from
    "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import {GovernorTimelockControl} from "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";

// ¿Qué? La gobernanza del protocolo (semana 31): un Governor de OpenZeppelin que cuenta los votos
//   de las shares del vault de puntos y ejecuta lo aprobado a través de un timelock.
// ¿Para qué? Que ninguna clave sola pueda cambiar el registro: cada cambio de administrador es una
//   propuesta pública, votada por quien tiene puntos en el vault y retrasada por el timelock.
// ¿Impacto? El timelock es quien tiene los roles del registro. Este contrato solo puede ponerle
//   operaciones en cola; quien tenga la mayoría de los votos de una propuesta decide.
contract ProtocolGovernor is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl
{
    /// @notice Bloques desde la propuesta hasta la foto de los votos: un día de bloques de 12 s.
    uint48 public constant VOTING_DELAY = 7200;
    /// @notice Bloques que dura la votación: una semana.
    uint32 public constant VOTING_PERIOD = 50_400;
    /// @notice Votos mínimos para proponer: tener alguno. Un número de shares fijo no sirve: lo que
    ///   vale una share depende del bonus que llegó antes del primer depósito (semana 30).
    uint256 public constant PROPOSAL_THRESHOLD = 1;
    /// @notice Porcentaje de las shares que tiene que votar a favor o abstenerse.
    uint256 public constant QUORUM_PERCENT = 4;

    /// @param votes Las shares del vault de puntos.
    /// @param timelockController El timelock que ejecuta lo aprobado y tiene los roles del registro.
    constructor(IVotes votes, TimelockController timelockController)
        Governor("Protocol Governor")
        GovernorSettings(VOTING_DELAY, VOTING_PERIOD, PROPOSAL_THRESHOLD)
        GovernorVotes(votes)
        GovernorVotesQuorumFraction(QUORUM_PERCENT)
        GovernorTimelockControl(timelockController)
    {}

    // Lo que sigue solo resuelve la herencia múltiple: cada función existe en dos contratos de
    // OpenZeppelin y Solidity exige decir cuál gana. Ninguna cambia lo que hacen.

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

    /// @inheritdoc Governor
    function state(uint256 proposalId) public view override(Governor, GovernorTimelockControl) returns (ProposalState) {
        return super.state(proposalId);
    }

    /// @inheritdoc Governor
    function proposalNeedsQueuing(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.proposalNeedsQueuing(proposalId);
    }

    function _queueOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint48) {
        return super._queueOperations(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _executeOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._executeOperations(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
        return super._executor();
    }
}
