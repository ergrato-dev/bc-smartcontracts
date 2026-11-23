// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Un token ERC-20 mínimo, escrito a mano: saldos, transferencias y permisos.
// ¿Para qué? Ver por dentro lo que OpenZeppelin te dará hecho en el ejercicio 02.
// ¿Impacto? Las firmas de las funciones y de los eventos son las del estándar (EIP-20):
//   cualquier wallet o contrato que hable ERC-20 sabe usar este token sin conocerlo.
contract MiniToken {
    string public constant name = "Mini Token";
    string public constant symbol = "MINI";
    uint8 public constant decimals = 18;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    error InvalidReceiver(address to);
    error InsufficientBalance(address from, uint256 balance, uint256 needed);
    error InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /// @notice Crea el token y entrega todo el suministro a quien despliega.
    /// @param supply Unidades mínimas creadas (con 18 decimales, 1 token es 1e18).
    constructor(uint256 supply) {
        totalSupply = supply;
        balanceOf[msg.sender] = supply;
        emit Transfer(address(0), msg.sender, supply);
    }

    /// @notice Envía `value` de tus tokens a `to`.
    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    // PASO 2: permitir que `spender` mueva hasta `value` de tus tokens.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function approve(address spender, uint256 value) external returns (bool) {
        revert("TODO: Paso 2");
        //> allowance[msg.sender][spender] = value;
        //> emit Approval(msg.sender, spender, value);
        //> return true;
    }

    // PASO 3: mover tokens de `from` gastando el permiso que dio a quien llama.
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        revert("TODO: Paso 3");
        //> uint256 allowed = allowance[from][msg.sender];
        //> if (allowed != type(uint256).max) {
        //>     if (allowed < value) revert InsufficientAllowance(msg.sender, allowed, value);
        //>     allowance[from][msg.sender] = allowed - value;
        //> }
        //> _transfer(from, to, value);
        //> return true;
    }

    // PASO 1: mover `value` de `from` a `to`, con sus dos comprobaciones y su evento.
    function _transfer(address from, address to, uint256 value) internal {
        revert("TODO: Paso 1");
        //> if (to == address(0)) revert InvalidReceiver(to);
        //> uint256 fromBalance = balanceOf[from];
        //> if (fromBalance < value) revert InsufficientBalance(from, fromBalance, value);
        //> balanceOf[from] = fromBalance - value;
        //> balanceOf[to] += value;
        //> emit Transfer(from, to, value);
    }
}
