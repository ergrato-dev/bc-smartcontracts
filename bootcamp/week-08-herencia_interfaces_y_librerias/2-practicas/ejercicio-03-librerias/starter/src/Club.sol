// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Bps} from "./Bps.sol";
import {AddressList} from "./AddressList.sol";

// ¿Qué? Un club: entrar cuesta FEE; una parte va a la tesorería y el resto al bote de
//   premios.
// ¿Para qué? Usar dos librerías con `using for`: una de cálculo y otra que trabaja sobre el
//   storage del club.
// ¿Impacto? El código de las librerías se copia en el club y se ejecuta con su storage y
//   su ETH: se revisa como si fuera propio.
contract Club {
    using Bps for uint256;
    using AddressList for address[];

    uint256 public constant FEE = 0.01 ether;
    uint256 public constant TREASURY_BPS = 2_500;

    uint256 public treasury;
    uint256 public prizePool;
    address[] private _members;

    event Joined(address indexed member, uint256 toTreasury);
    event Left(address indexed member);

    error WrongFee(uint256 expected, uint256 sent);
    error AlreadyMember(address account);
    error NotMember(address account);

    // PASO 4: entrar pagando FEE exacto, una sola vez, y repartir la cuota.
    function join() external payable {
        revert("TODO: Paso 4");
        //> if (msg.value != FEE) revert WrongFee(FEE, msg.value);
        //> if (_members.contains(msg.sender)) revert AlreadyMember(msg.sender);
        //> _members.push(msg.sender);
        //> uint256 toTreasury = msg.value.bps(TREASURY_BPS);
        //> treasury += toTreasury;
        //> prizePool += msg.value - toTreasury;
        //> emit Joined(msg.sender, toTreasury);
    }

    // PASO 5: salir del club. La cuota no se devuelve.
    function resign() external {
        revert("TODO: Paso 5");
        //> if (!_members.remove(msg.sender)) revert NotMember(msg.sender);
        //> emit Left(msg.sender);
    }

    function members() external view returns (address[] memory) {
        return _members;
    }
}
