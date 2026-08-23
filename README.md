# GoldenEye Mod Platform

An unofficial pet-project plan for a native GoldenEye 007 PC runtime with a Gen1Recomp-style modding experience. Android is a later nice-to-have.

> Status: first Windows vertical slice works locally. The asset-free runtime and launcher build, the user's ordinary US ROM boots Dam, and the launcher discovers validated mod packages. Lua execution is the next milestone. No ROM data is included.

## Product promise

A player supplies a legally obtained GoldenEye 007 US ROM. The launcher verifies it, creates a private local game install, and runs it natively on PC. The `.gemod` format remains platform-neutral so a future Android port can consume the same Lua packages. A new modder should be able to scaffold, run, validate, and package a Lua mod in under 15 minutes without knowing N64 memory addresses.

The project deliberately separates two lanes:

- **Lua lane:** the default, stable, documented interface for gameplay and content mods.
- **Native lane:** direct C/C++ engine work for advanced changes that cannot fit the stable Lua interface.

## Recommended technical direction

- MGB64's portable C engine and C++17 Dear ImGui application shell, pinned in `runtime/mgb64`.
- GoldenRecomp and N64Recomp remain research inputs, not the reproducible product baseline.
- Standard Lua 5.4 embedded as the friendly authoring language.
- SDL2 plus the runtime's WebGPU/OpenGL renderer paths.
- Windows x86-64 first because it is now built and ROM-smoke-tested on this PC; Linux x86-64 follows.
- A future thin Kotlin Android shell only after the desktop alpha is healthy.
- CMake and Ninja for native builds; Python for author tools and code generation.

The runtime is kept behind an explicit subtree boundary so upstream updates remain auditable. Public release provenance is still a gate even though local build and gameplay are proven.

## Start here

1. Read [Prerequisites](docs/PREREQUISITES.md) for the ROM, tools, hardware, and current machine gaps.
2. Read [Current Status](docs/CURRENT_STATUS.md) for the exact commands and evidence from the first working slice.
3. Read [Upstream Evaluation](docs/UPSTREAM_EVALUATION.md) for the baseline decision and unresolved blockers.
4. Read [Architecture](docs/ARCHITECTURE.md) and [Modding Model](docs/MODDING_MODEL.md).
5. Use [Roadmap](docs/ROADMAP.md) and [Plan](docs/PLAN.md) for gated implementation order.

## Planning index

| Document | Purpose |
|---|---|
| [CURRENT_STATUS.md](docs/CURRENT_STATUS.md) | Working build, evidence, commands, manifest contract, and immediate next slice |
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
- Treating an emulator configuration as the final product.
- Making Android support a blocker for the PC alpha.
- Exposing raw RDRAM offsets as the primary public mod interface.
- Promising online multiplayer in the initial release.
- Recreating every Gen1Recomp feature before one useful end-to-end mod works.

## Legal and project identity

This project is unofficial and is not affiliated with Nintendo, Rare, Microsoft, MGM, EON Productions, or the upstream projects named here. GoldenEye 007 and related names and assets belong to their respective owners. See [NOTICE.md](NOTICE.md). A project-code license will be chosen only after the Phase 0 provenance audit establishes what may be distributed.
