import { parseAbi } from "viem";

export { registryAbi } from "./registry-abi.ts";

// ¿Qué? Lo poco que la página lee del token de fidelidad, en formato legible.
// ¿Para qué? Mostrar los puntos de la cuenta sin generar la ABI entera del token.
export const loyaltyAbi = parseAbi([
  "function balanceOf(address account) view returns (uint256)",
  "function decimals() view returns (uint8)",
  "function symbol() view returns (string)",
]);
