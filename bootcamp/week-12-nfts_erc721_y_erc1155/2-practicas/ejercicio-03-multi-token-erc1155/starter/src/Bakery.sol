// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Owned} from "./Owned.sol";

// ¿Qué? Una panadería con tres tipos de token en un contrato ERC-1155: harina y azúcar
//   (ingredientes, fungibles) y tartas, que se hornean quemando ingredientes.
// ¿Para qué? Usar las operaciones en lote de ERC-1155 (`_mintBatch`, `_burnBatch`) y una
//   `uri` propia por id.
// ¿Impacto? Solo el dueño reparte ingredientes; las tartas solo salen del horno. Si `supply`
//   aceptara cualquier id, el dueño podría crear tartas sin ingredientes.
contract Bakery is ERC1155, Owned {
    using Strings for uint256;

    uint256 public constant FLOUR = 0;
    uint256 public constant SUGAR = 1;
    uint256 public constant CAKE = 2;
    uint256 public constant FLOUR_PER_CAKE = 3;
    uint256 public constant SUGAR_PER_CAKE = 1;

    error NotAnIngredient(uint256 id);
    error NothingToBake();
    error UnknownItem(uint256 id);

    constructor() ERC1155("") {}

    // PASO 1: repartir ingredientes en lote. Solo el dueño, y solo harina o azúcar.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function supply(address to, uint256[] calldata ids, uint256[] calldata amounts) external onlyOwner {
        revert("TODO: Paso 1");
        //> for (uint256 i = 0; i < ids.length; i++) {
        //>     if (ids[i] != FLOUR && ids[i] != SUGAR) revert NotAnIngredient(ids[i]);
        //> }
        //> _mintBatch(to, ids, amounts, "");
    }

    // PASO 2: hornear `cakes` tartas con los ingredientes de quien llama.
    function bake(uint256 cakes) external {
        revert("TODO: Paso 2");
        //> if (cakes == 0) revert NothingToBake();
        //> uint256[] memory ids = new uint256[](2);
        //> uint256[] memory amounts = new uint256[](2);
        //> (ids[0], ids[1]) = (FLOUR, SUGAR);
        //> (amounts[0], amounts[1]) = (FLOUR_PER_CAKE * cakes, SUGAR_PER_CAKE * cakes);
        //> _burnBatch(msg.sender, ids, amounts);
        //> _mint(msg.sender, CAKE, cakes, "");
    }

    // PASO 3: una URI por id, y error para los que no existen.
    function uri(uint256 id) public pure override returns (string memory) {
        revert("TODO: Paso 3");
        //> if (id > CAKE) revert UnknownItem(id);
        //> return string.concat("https://bakery.example/items/", id.toString(), ".json");
    }
}
