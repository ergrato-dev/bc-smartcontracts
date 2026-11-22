// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Un programa de puntos: cada cuenta tiene un saldo de puntos y una lista de amigos.
// ¿Para qué? Practicar mappings simples y anidados, el valor por defecto y `delete`.
// ¿Impacto? Un mapping no sabe qué claves "existen": toda clave devuelve un valor, aunque
//   nadie la haya escrito nunca.
contract Points {
    mapping(address => uint256) public points;
    mapping(address => bool) public isMember;
    mapping(address => mapping(address => bool)) public isFriend;

    error InsufficientPoints(uint256 available, uint256 requested);
    error AlreadyMember(address account);

    // PASO 1: sumar `amount` a los puntos de `user`.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function addPoints(address user, uint256 amount) external {
        revert("TODO: Paso 1");
        //> points[user] += amount;
    }

    // PASO 2: devolver si `user` tiene algún punto. Una clave nunca escrita vale 0.
    function hasPoints(address user) external view returns (bool) {
        revert("TODO: Paso 2");
        //> return points[user] != 0;
    }

    // PASO 3: pasar puntos de quien llama a `to`; InsufficientPoints si no le alcanzan.
    function transferPoints(address to, uint256 amount) external {
        revert("TODO: Paso 3");
        //> uint256 available = points[msg.sender];
        //> if (amount > available) revert InsufficientPoints(available, amount);
        //> points[msg.sender] = available - amount;
        //> points[to] += amount;
    }

    // PASO 4: marcar o desmarcar a `friend` como amigo de quien llama (mapping anidado).
    function setFriend(address friend, bool value) external {
        revert("TODO: Paso 4");
        //> isFriend[msg.sender][friend] = value;
    }

    // PASO 5: dejar los puntos de quien llama en el valor por defecto.
    function resetPoints() external {
        revert("TODO: Paso 5");
        //> delete points[msg.sender];
    }

    // PASO 6: alta de quien llama, una sola vez. Un mapping a bool distingue "nunca se
    //   unió" de "se unió y tiene 0 puntos".
    function join() external {
        revert("TODO: Paso 6");
        //> if (isMember[msg.sender]) revert AlreadyMember(msg.sender);
        //> isMember[msg.sender] = true;
    }
}
