# `ooda-screenshot`

Native Wayland Screenshot capture tool (`Screen`, `Window`, and `Region` modes with configurable `0s`/`3s`/`5s` delay, live preview, `~/Pictures/Screenshots/` export, and Feedback) for [openOODA](https://openOODA.org) (`L5` • `openOODA-apps`).

- **Desktop Name**: `Screenshot` (`org.openooda.screenshot`)
- **Subcommands**: `--gui [--live-frames N]`, `--install-desktop`, `capture [--mode screen|window|region] [--delay 0|3|5] [--out <path>]`, `list`, `feedback`, `about [--json]`
- **Capabilities (`CapReg64`)**: `FsRead`, `FsWrite`, `Fs`, `Process`, `Env`, `Time`, `Ffi`

## Build & Verify

```sh
make clean all && make det && make test && make check
```
