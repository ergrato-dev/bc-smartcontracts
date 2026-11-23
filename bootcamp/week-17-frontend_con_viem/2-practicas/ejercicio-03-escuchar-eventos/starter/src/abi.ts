import { parseAbi } from "viem";

// ¿Qué? La ABI del Token en formato legible: las firmas de Solidity como texto.
// ¿Para qué? Que viem sepa codificar cada llamada y decodificar cada respuesta, y que
//   TypeScript conozca nombres, argumentos y tipos de vuelta de cada función.
// ¿Impacto? Solo lo que está aquí existe para viem: una función que falte no se puede llamar.
export const tokenAbi = parseAbi([
  "function name() view returns (string)",
  "function symbol() view returns (string)",
  "function decimals() view returns (uint8)",
  "function totalSupply() view returns (uint256)",
  "function balanceOf(address account) view returns (uint256)",
  "function transfer(address to, uint256 value) returns (bool)",
  "event Transfer(address indexed from, address indexed to, uint256 value)",
  "error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed)",
]);
