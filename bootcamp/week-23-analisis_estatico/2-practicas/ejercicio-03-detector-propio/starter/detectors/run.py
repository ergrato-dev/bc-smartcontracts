"""Ejecuta el detector propio sobre un proyecto Foundry.

Uso: "$SLITHER_PYTHON" detectors/run.py <carpeta del proyecto>
Imprime un hallazgo por línea y termina con código 1 si hay alguno, como `slither`.
"""

import sys

from slither import Slither

from eth_send_without_guard import EthSendWithoutGuard


def main(target: str) -> int:
    slither = Slither(target)
    slither.register_detector(EthSendWithoutGuard)
    findings = [result for results in slither.run_detectors() for result in results]
    for finding in findings:
        print(finding["description"], end="")
    print(f"{len(findings)} result(s) found")
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
