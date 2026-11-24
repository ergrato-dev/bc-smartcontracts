// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Un bote de propinas en ETH: cualquiera da propina a una cuenta, cada cuenta retira lo
//   suyo, y quien da propina gana insignias numeradas, cada una reclamable una vez.
// ¿Para qué? Alguien lo "optimizó" sin tests: cada optimización ahorra gas y rompe algo. Cada
//   paso arregla una sin deshacer el ahorro.
// ¿Impacto? Con estos fallos, el bote pierde ETH, se queda propinas o deja de funcionar. Solo en
//   anvil y en tests.
contract TipJar {
    // Saldo y fecha de la última propina en un slot: 12 + 8 bytes.
    struct Account {
        uint96 balance;
        uint64 lastTip;
    }

    mapping(address => Account) public accounts;
    mapping(uint256 => uint256) private _badgeWords;

    error TooLarge(uint256 amount);
    error InsufficientBalance(uint256 amount, uint256 balance);
    error TransferFailed(address to, uint256 amount);
    error BadgeTaken(uint256 badge);

    /// @notice Da `msg.value` de propina a `to`.
    function tip(address to) external payable {
        _credit(to, msg.value);
    }

    /// @notice Reparte `msg.value` a partes iguales entre `to`. Lo que sobra de dividir se queda en el bote.
    function tipMany(address[] calldata to) external payable {
        uint256 share = msg.value / to.length;
        // PASO 5: un contador de 8 bits da la vuelta en 255 y el bucle no acaba nunca.
        for (uint8 i = 0; i < to.length;) { // <- Paso 5
        //> for (uint256 i = 0; i < to.length;) {
            _credit(to[i], share);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Retira `amount` de tu saldo.
    function withdraw(uint256 amount) external {
        Account storage account = accounts[msg.sender];
        uint96 balance = account.balance;
        // PASO 2: sin esta comprobación, la resta sin comprobar da la vuelta.
        //> if (amount > balance) revert InsufficientBalance(amount, balance);
        // PASO 3: escribir el saldo nuevo antes de enviar el ETH, no con el valor de antes después.
        //> unchecked {
        //>     account.balance = balance - uint96(amount);
        //> }
        (bool ok,) = msg.sender.call{value: amount}("");
        if (!ok) revert TransferFailed(msg.sender, amount);
        unchecked { // <- Paso 3
            account.balance = balance - uint96(amount); // <- Paso 3
        } // <- Paso 3
    }

    /// @notice Reclama la insignia `badge`. Cada una, una vez.
    function claimBadge(uint256 badge) external {
        // PASO 4: 256 insignias por palabra: el bit es `badge & 0xff`, los 8 bits bajos.
        uint256 bit = 1 << (badge & 0x7f); // <- Paso 4
        //> uint256 bit = 1 << (badge & 0xff);
        uint256 word = _badgeWords[badge >> 8];
        if (word & bit != 0) revert BadgeTaken(badge);
        _badgeWords[badge >> 8] = word | bit;
    }

    // Suma `amount` al saldo de `to` y apunta la hora.
    function _credit(address to, uint256 amount) internal {
        Account storage account = accounts[to];
        // PASO 1: `uint96(amount)` corta los bits altos sin avisar.
        account.balance += uint96(amount); // <- Paso 1
        //> if (amount > type(uint96).max) revert TooLarge(amount);
        //> account.balance += uint96(amount);
        account.lastTip = uint64(block.timestamp);
    }
}
