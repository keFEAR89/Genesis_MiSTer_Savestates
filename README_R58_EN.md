# Genesis MiSTer — Savestates R58 (Beta)

> **Status: beta release.** The savestate system is fully implemented, but compatibility is not universal yet. Save or restore may fail in some games or configurations. Do not use savestates as the only copy of important progress.

## What is included

- 4 persistent savestate slots
- **Save State** and **Load State** commands in the core menu
- state files written through MiSTer's normal savestate system
- states persist across core restarts and power cycles
- ROM and relevant configuration checks before loading
- ready-to-use `Genesis_SS.rbf`
- complete Quartus source tree for further development

## Usage

1. Run `Genesis_SS.rbf` on MiSTer.
2. Load a game and choose **Savestate Slot 1–4**.
3. Select **Save State**.
4. To return to that point, choose the same slot and select **Load State**.

After saving, allow MiSTer Main enough time to finish writing the state file before powering off, changing ROMs or overwriting the same slot.

## Compatibility

R58 is a **beta**. Savestates already work in many standard Genesis / Mega Drive games, but **compatibility has not been confirmed for every game**.

Known limitations remain for special hardware and peripherals, including SVP, Pier Solar-specific hardware, multitap, mouse, light gun and serial devices. Additional game-specific compatibility issues may also exist.

If a game hangs, resets, restores incorrectly, or develops audio, video or gameplay problems after **Load State**, treat it as a compatibility bug in the current beta.

## Building

Use **Quartus Prime 18.1 Standard**. Open `Genesis.qpf`, select revision `Genesis`, and run a Full Compilation. The checked-in `Genesis.qsf` is the authoritative configuration for this release.

Always verify setup slack, hold slack and TNS after rebuilding.

## Upstream

Based on the archived [MiSTer-devel/Genesis_MiSTer](https://github.com/MiSTer-devel/Genesis_MiSTer) core.

## License

The upstream license and copyright notices are retained. Preserve all applicable notices when redistributing or modifying the project.
