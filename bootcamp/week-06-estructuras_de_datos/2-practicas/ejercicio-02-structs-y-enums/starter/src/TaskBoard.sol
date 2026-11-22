// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Un tablero de tareas: cada tarea es un struct con un estado de un enum.
// ¿Para qué? Practicar structs, enums, structs dentro de un mapping y la diferencia entre
//   una referencia `storage` y una copia `memory`.
// ¿Impacto? Modificar una copia en memory no cambia nada guardado: el error no revierte,
//   simplemente no hace nada.
contract TaskBoard {
    enum Status {
        Todo,
        Doing,
        Done
    }

    struct Task {
        string title;
        address owner;
        uint8 priority;
        Status status;
    }

    mapping(uint256 => Task) public tasks;
    uint256 public taskCount;

    error TaskNotFound(uint256 id);
    error NotTaskOwner(address caller);
    error InvalidStatus(Status current);

    // PASO 1: crear una tarea en estado Todo con quien llama como dueño. Los ids empiezan en 1.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function createTask(string calldata title, uint8 priority) external returns (uint256 id) {
        revert("TODO: Paso 1");
        //> id = ++taskCount;
        //> tasks[id] = Task({title: title, owner: msg.sender, priority: priority, status: Status.Todo});
    }

    // PASO 2: devolver la tarea entera; TaskNotFound si nadie la creó (dueño address(0)).
    function getTask(uint256 id) external view returns (Task memory) {
        revert("TODO: Paso 2");
        //> Task memory task = tasks[id];
        //> if (task.owner == address(0)) revert TaskNotFound(id);
        //> return task;
    }

    // PASO 3: pasar de Todo a Doing. Solo el dueño de la tarea.
    //   `storage` hace que `task` apunte a la tarea guardada, no a una copia.
    function start(uint256 id) external {
        revert("TODO: Paso 3");
        //> Task storage task = tasks[id];
        //> if (task.owner != msg.sender) revert NotTaskOwner(msg.sender);
        //> if (task.status != Status.Todo) revert InvalidStatus(task.status);
        //> task.status = Status.Doing;
    }

    // PASO 4: pasar de Doing a Done. Solo el dueño de la tarea.
    function finish(uint256 id) external {
        revert("TODO: Paso 4");
        //> Task storage task = tasks[id];
        //> if (task.owner != msg.sender) revert NotTaskOwner(msg.sender);
        //> if (task.status != Status.Doing) revert InvalidStatus(task.status);
        //> task.status = Status.Done;
    }

    // PASO 5: devolver el estado como número y el número del último valor del enum.
    function statusCode(uint256 id) external view returns (uint8 code, uint8 maxCode) {
        revert("TODO: Paso 5");
        //> code = uint8(tasks[id].status);
        //> maxCode = uint8(type(Status).max);
    }

    // PASO 6: borrar la tarea; todos sus campos vuelven al valor por defecto.
    function removeTask(uint256 id) external {
        revert("TODO: Paso 6");
        //> if (tasks[id].owner != msg.sender) revert NotTaskOwner(msg.sender);
        //> delete tasks[id];
    }
}
