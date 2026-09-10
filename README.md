# Genesis MiSTer — Savestates R58

R58 of the archived **MiSTer-devel/Genesis_MiSTer** core with working FPGA savestates.

## Contents
This repository contains the complete R58 Quartus project, the savestate implementation in `rtl/savestate/`, all integrated CPU/VDP/system changes, release metadata, and the tested `Genesis_SS.rbf` binary.

The original upstream README is preserved as `README_UPSTREAM.md`. Detailed development notes are in `README_R58_RU.md`.

## Savestates
R58 provides four persistent save-state slots. State data is stored through MiSTer's external DDR/file-backed savestate area. States are associated with ROM identity and relevant machine settings, and data is verified during save/load.

## Building
Use **Quartus Prime 18.1 Standard**. Open `Genesis.qpf`, select revision `Genesis`, and perform a full compilation. The project is configured for 6 parallel processors. Always re-check setup slack, hold slack and TNS after rebuilding.

## Upstream
Based on the archived [MiSTer-devel/Genesis_MiSTer](https://github.com/MiSTer-devel/Genesis_MiSTer) project.

## License
The upstream `LICENSE` and source copyright notices are retained. Preserve applicable notices when redistributing or modifying the project.
