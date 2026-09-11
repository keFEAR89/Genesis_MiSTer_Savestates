# Genesis MiSTer — Savestates R58 (Beta)

> **Beta release.** Savestates are fully implemented, but compatibility is not universal yet. Save/load may fail in some games or configurations. Do not rely on savestates as the only copy of important progress.

[English](README_R58_EN.md) · [Русский](README_R58_RU.md)

This project adds persistent FPGA savestates to the archived **MiSTer-devel/Genesis_MiSTer** core.

## Features

- 4 persistent savestate slots
- Save and Load commands in the MiSTer core menu
- states are written to MiSTer's normal savestate storage
- saved states persist across core restarts and power cycles
- ROM and relevant configuration checks before loading
- bundled tested binary: `Genesis_SS.rbf`
- complete Quartus source tree for further development

## Compatibility

R58 is a **beta**. Savestates work in many standard Genesis / Mega Drive games, but **not every game is supported or fully stable yet**.

Known unsupported or limited areas include special cartridge hardware and peripherals such as SVP, Pier Solar-specific hardware, multitap, mouse, light gun and serial devices. Other game-specific compatibility issues may still exist.

If a state does not restore correctly, the game hangs, resets, loses audio/video state, or behaves differently after loading, treat it as a compatibility bug in this beta.

## Quick use

1. Load `Genesis_SS.rbf` on MiSTer.
2. Load a game and choose **Savestate Slot 1–4**.
3. Select **Save State**.
4. Later select the same slot and use **Load State**.

After saving, allow MiSTer Main enough time to finish writing the state file before powering off, changing ROMs or overwriting the same slot.

## Building

Use **Quartus Prime 18.1 Standard**. Open `Genesis.qpf`, select revision `Genesis`, and perform a full compilation. The checked-in `Genesis.qsf` is the authoritative configuration for this release.

Always re-check setup slack, hold slack and TNS after rebuilding.

## Upstream

Based on the archived [MiSTer-devel/Genesis_MiSTer](https://github.com/MiSTer-devel/Genesis_MiSTer) project.

## License

The upstream `LICENSE` and source copyright notices are retained. Preserve all applicable notices when redistributing or modifying the project.
