# DesktopGoldenEye

An unofficial, all-in-one desktop edition of GoldenEye 007 built from [Graslu's 1964 GEPD Edition](https://github.com/Graslu/1964GEPD). Extract one package, select a legally obtained US ROM, and play with modern mouse aiming, WASD movement, high-quality rendering, launcher-managed settings, and a path toward friendly mods.

> Status: both the self-contained Windows ZIP and a single portable EXE are implemented and tested. They bundle the source-built DesktopGoldenEye core, plugins, launcher, notices, and quality defaults—everything except the ROM. Linux and macOS are product targets, but the proven 1964 runtime is Windows-only and cannot simply be recompiled for them.

1964 0.8.5 is Copyright (c) 1999–2002 Joel Middendorf. This fork retains the upstream GPL-2.0 license and notices. The unmodified 1964 0.8.5 source is available from [SourceForge](https://sourceforge.net/projects/schibo/files/1964%200.8.5/1964-2002-0922.zip/1964-2002-0922.zip).

## Product promise

A player downloads one DesktopGoldenEye EXE—or the transparent portable ZIP—opens it, and selects a legally obtained GoldenEye 007 US ROM. The launcher verifies the ROM locally; no emulator, plugin, redistributable, configuration tutorial, or command line should be required. The single EXE unpacks its DLL-based runtime into `%LOCALAPPDATA%\DesktopGoldenEye\Portable` and preserves settings/saves across payload updates. Today, the forked 1964 core provides the best Windows play experience and MGB64 hosts the experimental Lua mod slice. The longer-term goal is the same quality and mod experience on Windows, Linux, and—if a maintainable runtime qualifies—macOS.

The project deliberately separates two lanes:

- **Lua lane:** the default, stable, documented interface for gameplay and content mods.
- **Native lane:** direct C/C++ engine work for advanced changes that cannot fit the stable Lua interface.

## Recommended technical direction

- This source fork of 1964GEPD + GLideN64 as the immediate Windows quality Adapter. The 2002-era x86 C core builds as `DesktopGoldenEye.exe`; a release builder combines it with the checksum-pinned runtime bundle and launcher into one ROM-free archive.
- MGB64's portable C engine and C++17 Dear ImGui shell, pinned in `runtime/mgb64`, as the experimental Lua/mod Adapter.
- GoldenRecomp and N64Recomp remain research inputs, not the reproducible product baseline.
- A Lua 5.4-compatible author Interface (currently hosted by Lua 5.5.1) as the friendly mod language.
- SDL2 plus the runtime's WebGPU/OpenGL renderer paths.
- Windows first because the quality runtime is a Win32 x86 emulator/plugin stack and is ROM-smoke-tested on this PC.
- Linux and macOS require a separate portable quality Adapter; MGB64 is the current research candidate, not yet a release-quality substitute.
- CMake and Ninja for native builds; Python for author tools and code generation.

The Runtime Interface is the stable Seam. Emulator acquisition/configuration, ROM byte order, and MGB64 environment details remain Adapter Implementations. Public release provenance is still a gate even though the local quality install and experimental mod slice both run.

## Start here

1. Read [Prerequisites](docs/PREREQUISITES.md) for the ROM, tools, hardware, and current machine gaps.
2. Read [Quality Baseline](docs/QUALITY_BASELINE.md) for the ready-to-play launcher, controls, hashes, and current tradeoffs.
3. Read [Building on Windows](docs/BUILDING_WINDOWS.md) to reproduce the executable and all-in-one release archive.
4. Read [Desktop Release](docs/DESKTOP_RELEASE.md) for the one-package promise and Windows/Linux/macOS gates.
5. Read [Current Status](docs/CURRENT_STATUS.md) for exact commands and evidence from both runtime tracks.
6. Read [Upstream Evaluation](docs/UPSTREAM_EVALUATION.md) for the baseline decision and unresolved blockers.
7. Read [Architecture](docs/ARCHITECTURE.md) and [Modding Model](docs/MODDING_MODEL.md).
8. Use [Roadmap](docs/ROADMAP.md) and [Plan](docs/PLAN.md) for gated implementation order.

## Planning index

| Document | Purpose |
|---|---|
| [CURRENT_STATUS.md](docs/CURRENT_STATUS.md) | Working build, evidence, commands, manifest contract, and immediate next slice |
| [QUALITY_BASELINE.md](docs/QUALITY_BASELINE.md) | Default Windows runtime, quality profile, mouse/WASD ownership, checksums, and launch instructions |
| [BUILDING_WINDOWS.md](docs/BUILDING_WINDOWS.md) | Reproducible Visual Studio 2022 build and all-in-one packaging |
| [DESKTOP_RELEASE.md](docs/DESKTOP_RELEASE.md) | One-package player contract and Windows/Linux/macOS qualification gates |
| [PLAN.md](docs/PLAN.md) | Comprehensive execution plan and definition of done |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Deep Modules, Interfaces, Seams, lifecycle, and proposed repository layout |
| [GEN1RECOMP_PARITY.md](docs/GEN1RECOMP_PARITY.md) | Feature-for-feature experience target |
| [MODDING_MODEL.md](docs/MODDING_MODEL.md) | Lua interface, packages, sandbox, dependencies, and author workflow |
| [UPSTREAM_EVALUATION.md](docs/UPSTREAM_EVALUATION.md) | Evidence, baseline options, and selection gates |
| [PREREQUISITES.md](docs/PREREQUISITES.md) | Everything needed to begin on this computer |
| [ROADMAP.md](docs/ROADMAP.md) | Milestones with entry and exit criteria |
| [TEST_STRATEGY.md](docs/TEST_STRATEGY.md) | ROM-free CI, private ROM tests, replay, performance, and device coverage |
| [DECISIONS.md](docs/DECISIONS.md) | Accepted, provisional, and pending architecture decisions |
| [RISK_REGISTER.md](docs/RISK_REGISTER.md) | Legal, platform, timing, compatibility, and community risks |

## Non-goals

- Shipping a ROM, extracted assets, proprietary SDK code, or copyrighted game data.
- Pretending the launcher alone is the final product; emulator, input-plugin, packaging, and modding improvements all belong in this fork.
- Making Linux or macOS block a high-quality Windows release.
- Exposing raw RDRAM offsets as the primary public mod interface.
- Promising online multiplayer in the initial release.
- Recreating every Gen1Recomp feature before one useful end-to-end mod works.

## Legal and project identity

This project is unofficial and is not affiliated with Nintendo, Rare, Microsoft, MGM, EON Productions, or the upstream projects named here. GoldenEye 007 and related names and assets belong to their respective owners. See [NOTICE.md](NOTICE.md), [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md), and [LICENSE](LICENSE).
