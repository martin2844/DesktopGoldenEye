# GoldenEye Mod Platform

An unofficial pet-project plan for a native GoldenEye 007 PC runtime with a Gen1Recomp-style modding experience. Android is a later nice-to-have.

> Status: planning and feasibility only. No game code, ROM data, or playable build is included.

## Product promise

A player supplies a legally obtained GoldenEye 007 US ROM. The launcher verifies it, creates a private local game install, and runs it natively on PC. The `.gemod` format remains platform-neutral so a future Android port can consume the same Lua packages. A new modder should be able to scaffold, run, validate, and package a Lua mod in under 15 minutes without knowing N64 memory addresses.

The project deliberately separates two lanes:

- **Lua lane:** the default, stable, documented interface for gameplay and content mods.
- **Native lane:** an advanced N64Recomp/N64ModernRuntime path for engine-level work that cannot fit the Lua interface.

## Recommended technical direction

- C++20 host and runtime.
- N64Recomp plus N64ModernRuntime as the low-level recompilation and native-mod substrate.
- GoldenRecomp and the GoldenEye decompilation as research inputs, subject to provenance and redistribution review.
- Standard Lua 5.4 embedded as the friendly authoring language.
- RT64 on supported desktop platforms.
- Windows x86-64 first because the closest GoldenRecomp build path is currently Visual Studio/Windows-oriented; Linux x86-64 follows once the baseline is understood.
- A future thin Kotlin Android shell only after the desktop alpha is healthy.
- CMake and Ninja for native builds; Python for author tools and code generation.

This is not a commitment to fork one upstream unchanged. The first milestone must prove that the selected baseline is reproducible, redistributable, and capable of completing real missions before public interfaces are frozen.

## Start here

1. Read [Prerequisites](docs/PREREQUISITES.md) for the ROM, tools, hardware, and current machine gaps.
2. Read [Upstream Evaluation](docs/UPSTREAM_EVALUATION.md) for the baseline decision and unresolved blockers.
3. Read [Architecture](docs/ARCHITECTURE.md) and [Modding Model](docs/MODDING_MODEL.md).
4. Use [Roadmap](docs/ROADMAP.md) for gated implementation order.
5. Use [Plan](docs/PLAN.md) for scope, work streams, estimates, and the first two weeks.

## Planning index

| Document | Purpose |
|---|---|
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
