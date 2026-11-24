// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// ¿Qué? Un préstamo con garantía: depositas COLLATERAL (un token que vale lo que dice el feed),
//   pides prestado DEBT (un dólar de prueba, 1 token = 1 USD) hasta el 75 % de lo que vale, pagas
//   un 5 % anual, y si tu garantía cae por debajo del umbral, cualquiera puede liquidarte.
// ¿Para qué? Ver las cuatro cuentas de un protocolo de préstamos: el valor de la garantía, el
//   máximo a pedir, la salud de la posición y la liquidación, y cómo crece la deuda con un índice.
// ¿Impacto? Todo depende del precio del feed: si el feed miente, el pool presta de más o liquida
//   a quien no debe (semanas 20 y 22).
contract LendingPool {
    using SafeERC20 for IERC20;
    using Math for uint256;

    /// @notice Lo máximo que puedes pedir: un 75 % del valor de tu garantía.
    uint256 public constant LTV_BPS = 7500;
    /// @notice Por debajo de un 80 % del valor de la garantía frente a la deuda, te pueden liquidar.
    uint256 public constant LIQUIDATION_THRESHOLD_BPS = 8000;
    /// @notice Lo que gana quien liquida: un 5 % más de garantía que la deuda que paga.
    uint256 public constant LIQUIDATION_BONUS_BPS = 500;
    /// @notice En cada liquidación se paga como mucho la mitad de la deuda.
    uint256 public constant CLOSE_FACTOR_BPS = 5000;
    /// @notice Un 5 % anual, por segundo y con 18 decimales.
    uint256 public constant RATE_PER_SECOND = uint256(0.05e18) / 365 days;
    /// @notice Antigüedad máxima del precio del feed.
    uint256 public constant MAX_PRICE_AGE = 1 hours;

    IERC20 public immutable COLLATERAL;
    IERC20 public immutable DEBT;
    AggregatorV3Interface public immutable FEED;

    /// @notice Cuánto vale hoy 1 de deuda escalada, con 18 decimales: empieza en 1.
    uint256 public borrowIndex = 1e18;
    uint256 public lastAccrual;
    mapping(address => uint256) public collateralOf;
    // La deuda de cada cuenta dividida por el índice del momento en que la pidió.
    mapping(address => uint256) private _scaledDebt;

    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);
    event Liquidated(address indexed user, address indexed liquidator, uint256 repaid, uint256 seized);

    error InvalidPrice(int256 answer);
    error StalePrice(uint256 updatedAt);
    error ExceedsLtv(uint256 debt, uint256 maxDebt);
    error Unhealthy(uint256 healthFactor);
    error Healthy(uint256 healthFactor);
    error ExceedsCloseFactor(uint256 repay, uint256 maxRepay);

    constructor(IERC20 collateral, IERC20 debt, AggregatorV3Interface feed) {
        COLLATERAL = collateral;
        DEBT = debt;
        FEED = feed;
        lastAccrual = block.timestamp;
    }

    /// @notice Precio de 1 COLLATERAL en USD, con 18 decimales, con las comprobaciones de la semana 20.
    function price() public view returns (uint256) {
        (, int256 answer,, uint256 updatedAt,) = FEED.latestRoundData();
        if (answer <= 0) revert InvalidPrice(answer);
        if (block.timestamp - updatedAt > MAX_PRICE_AGE) revert StalePrice(updatedAt);
        return uint256(answer) * 10 ** (18 - FEED.decimals());
    }

    // PASO 1: lo que vale en USD la garantía de `user`.
    // Borra la línea del revert y descomenta la línea que empieza con `//> `.
    /// @notice Valor en USD, con 18 decimales, de la garantía de `user`.
    function collateralValue(address user) public view returns (uint256) {
        revert("TODO: Paso 1");
        //> return collateralOf[user] * price() / 1e18;
    }

    /// @notice Deuda de `user` hoy, con el interés hasta este segundo, redondeada hacia arriba.
    function debtOf(address user) public view returns (uint256) {
        return _scaledDebt[user].mulDiv(_currentIndex(), 1e18, Math.Rounding.Ceil);
    }

    // PASO 3: la salud de la posición. Por encima de 1 (1e18) está a salvo; por debajo, se liquida.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    /// @notice Garantía por el umbral, dividida por la deuda, con 18 decimales.
    function healthFactor(address user) public view returns (uint256) {
        revert("TODO: Paso 3");
        //> uint256 debt = debtOf(user);
        //> if (debt == 0) return type(uint256).max;
        //> return (collateralValue(user) * LIQUIDATION_THRESHOLD_BPS / 10_000).mulDiv(1e18, debt);
    }

    /// @notice Deposita `amount` de garantía.
    function depositCollateral(uint256 amount) external {
        collateralOf[msg.sender] += amount;
        COLLATERAL.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @notice Retira `amount` de garantía si la posición sigue sana.
    function withdrawCollateral(uint256 amount) external {
        _accrue();
        collateralOf[msg.sender] -= amount;
        uint256 hf = healthFactor(msg.sender);
        if (hf < 1e18) revert Unhealthy(hf);
        COLLATERAL.safeTransfer(msg.sender, amount);
    }

    // PASO 2: no prestar más del LTV.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    /// @notice Pide prestado `amount` de DEBT contra tu garantía.
    function borrow(uint256 amount) external {
        _accrue();
        revert("TODO: Paso 2");
        //> uint256 debt = debtOf(msg.sender) + amount;
        //> uint256 maxDebt = collateralValue(msg.sender) * LTV_BPS / 10_000;
        //> if (debt > maxDebt) revert ExceedsLtv(debt, maxDebt);
        //> _scaledDebt[msg.sender] += amount.mulDiv(1e18, borrowIndex, Math.Rounding.Ceil);
        //> emit Borrowed(msg.sender, amount);
        //> DEBT.safeTransfer(msg.sender, amount);
    }

    /// @notice Devuelve `amount` de tu deuda; si pasa de lo que debes, solo cobra lo que debes.
    function repay(uint256 amount) external returns (uint256 repaid) {
        _accrue();
        repaid = _reduceDebt(msg.sender, amount);
        emit Repaid(msg.sender, repaid);
        DEBT.safeTransferFrom(msg.sender, address(this), repaid);
    }

    // PASO 4: liquidar paga parte de la deuda de otro y se lleva su garantía con un 5 % de premio.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    /// @notice Paga `repayAmount` de la deuda de `user`, que tiene que estar por debajo de 1.
    function liquidate(address user, uint256 repayAmount) external returns (uint256 seized) {
        _accrue();
        revert("TODO: Paso 4");
        //> uint256 hf = healthFactor(user);
        //> if (hf >= 1e18) revert Healthy(hf);
        //> uint256 maxRepay = debtOf(user) * CLOSE_FACTOR_BPS / 10_000;
        //> if (repayAmount > maxRepay) revert ExceedsCloseFactor(repayAmount, maxRepay);
        //> seized = (repayAmount * (10_000 + LIQUIDATION_BONUS_BPS) / 10_000).mulDiv(1e18, price());
        //> _reduceDebt(user, repayAmount);
        //> collateralOf[user] -= seized;
        //> emit Liquidated(user, msg.sender, repayAmount, seized);
        //> DEBT.safeTransferFrom(msg.sender, address(this), repayAmount);
        //> COLLATERAL.safeTransfer(msg.sender, seized);
    }

    // PASO 5: el índice crece con el tiempo, y con él la deuda de todos a la vez.
    // Borra la línea que acaba en `// <- Paso 5` y descomenta la de debajo.
    function _currentIndex() internal view returns (uint256) {
        return borrowIndex; // <- Paso 5
        //> return borrowIndex + borrowIndex * RATE_PER_SECOND * (block.timestamp - lastAccrual) / 1e18;
    }

    // Guarda el índice de hoy: cada función que cambia una deuda lo llama primero.
    function _accrue() internal {
        borrowIndex = _currentIndex();
        lastAccrual = block.timestamp;
    }

    // Resta `amount` de la deuda de `user`, sin pasar de lo que debe; devuelve lo restado.
    function _reduceDebt(address user, uint256 amount) internal returns (uint256) {
        uint256 debt = debtOf(user);
        if (amount >= debt) {
            _scaledDebt[user] = 0;
            return debt;
        }
        _scaledDebt[user] -= amount.mulDiv(1e18, borrowIndex);
        return amount;
    }
}
