# Genesis MiSTer — Savestates R58

R58 of the archived **MiSTer-devel/Genesis_MiSTer** core with working FPGA savestates.

## Contents
This repository contains the complete R58 Quartus project, the savestate implementation in `rtl/savestate/`, all integrated CPU/VDP/system changes, release metadata, and the tested `Genesis_SS.rbf` binary.

The original upstream README is preserved as `README_UPSTREAM.md`. Detailed development notes are in `README_R58_RU.md`.

## Savestates
R58 provides four persistent save-state slots. State data is stored through MiSTer's external DDR/file-backed savestate area. States are associated with ROM identity and relevant machine settings, and data is verified during save/load.

## Building
Use **Quartus Prime 18.1 Standard**. Open `Genesis.qpf`, select revision `Genesis`, and perform a full compilation. The checked-in `Genesis.qsf` is the authoritative configuration for this release. Always re-check setup slack, hold slack and TNS after rebuilding; timing results from the supplied RBF must not be assumed for a new build.

## Source manifest note
`R58_SOURCE_MANIFEST.json` is retained as development provenance. It was generated immediately before the final QSF recovery adjustment, so its recorded `Genesis.qsf` hash is older than the checked-in final QSF. During publication, all other listed source files were verified against that manifest, while the final QSF was verified separately against the live release file.

## Upstream
Based on the archived [MiSTer-devel/Genesis_MiSTer](https://github.com/MiSTer-devel/Genesis_MiSTer) project.

## Development
The source is published so the MiSTer community can inspect, test and extend the savestate implementation. Further work can focus on compatibility edge cases, special hardware/peripherals and deeper MiSTer integration.

## License
The upstream `LICENSE` and source copyright notices are retained. Preserve applicable notices when redistributing or modifying the project.
