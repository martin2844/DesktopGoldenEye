# Desktop release contract

## Player promise

Every supported platform ships one signed/checksummed archive or app bundle containing everything needed except copyrighted game data. The first-run journey is:

1. download and extract/install DesktopGoldenEye;
2. open DesktopGoldenEye;
3. select a legally obtained, unmodified supported ROM;
4. receive a clear verification result;
5. press Play with Modern FPS controls and the recommended quality profile already active.

The supported journey never asks the player to locate an emulator, select plugins, edit INI files, install a mod loader, use a terminal, or move the ROM into the application directory.

## Release contents

Each platform artifact must include:

- the platform runtime and renderer;
- mouse/keyboard and controller input support;
- audio support;
- the DesktopGoldenEye launcher and defaults;
- save storage, backups, and recovery;
- diagnostics and exact component hashes;
- licenses, notices, source revision, and an SBOM/component manifest;
- mod manager/runtime components once that lane is player-ready;
- no ROM, extracted game assets, player state, or prebuilt save.

## Platform matrix

| Platform | Current status | Runtime direction | Release gate |
|---|---|---|---|
| Windows x86/x64 host | Working alpha package | Forked 1964 Win32 x86 core + GLideN64 + Mouse Injector | Human mission qualification, clean-machine test, third-party redistribution audit, signing |
| Linux x86-64 | Research | Portable MGB64/decomp-derived Adapter or another quality-equivalent open runtime | Rendering/input/audio parity and same ROM/mod contracts |
| macOS Apple Silicon | Feasibility target | Native arm64 portable runtime with Metal/WebGPU-class renderer; not the 1964 Win32 dynarec/plugins | Apple Silicon build, notarized app bundle, sandbox-safe ROM picker/saves, mission parity |
| macOS Intel | Unscheduled | Only if maintenance demand justifies a second macOS architecture | Same as Apple Silicon plus supported hardware evidence |

Wine can be documented as an experiment, but it does not count as native Linux or macOS support.

## Mod progression

The release format reserves one product identity and profile model across runtimes. Mod support should arrive in increasing-risk layers:

1. verified ROM patch profiles for existing BPS/xdelta/IPS projects;
2. structured cheats and configuration packages supported by the 1964 Adapter;
3. portable `.gemod` packages with manifests, dependencies, permissions, and Lua semantic APIs;
4. an explicitly unstable native expert lane.

The launcher must label which mods work on which runtime. A Windows-only memory patch must never masquerade as a portable semantic mod.

## Publishing gate

The local Windows packager already creates and validates the complete ROM-free artifact. Public upload requires the exact bundled plugin/asset license inventory, required attribution/source links, malware-signing/reputation plan, clean-machine evidence, and final artifact checksum. A development archive is evidence, not automatically a redistributable public release.
