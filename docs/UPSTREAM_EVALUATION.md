# Upstream evaluation

## Implementation update — quality/runtime split

The original N64Recomp recommendation below is retained as the historical Phase 0 hypothesis. The project now has two runtime roles based on direct testing on 2026-08-23.

The default Windows player baseline is **1964GEPD** with its bundled GLideN64 and Mouse Injector plugins. It consumes the ordinary US ROM, includes years of GoldenEye-specific 60 fps/timing/input work, and is the strongest proven game-quality route that satisfies the user's current ROM-only requirement. The exact no-Discord-RPC release asset and ROM have both been hash-verified, and the game now boots through this repository's launcher.

**MGB64**, pinned at `0d1d40b4`, remains the experimental mod baseline. Its deep Module provides ordinary-ROM validation, an in-process Dear ImGui launcher, SDL2 input/audio, editable portable C/C++, and the Lua host built in this repository. Direct user testing found its mouse feel and rendering quality unacceptable as the default player experience, consistent with its documented texture/fog/glass/platform gaps.

GoldenRecomp was rejected as the implementation baseline because its pinned `lib/ge` source dependency is private/unavailable and the public mirror no longer contains the required commit or transformation branch. A build that cannot be reproduced from its documented inputs is not a viable foundation for this pet project.

N64Recomp, N64ModernRuntime, GoldenRecomp, the complete GoldenEye decompilation, and the Perfect Dark PC port remain valuable long-term research inputs. A decomp/native line is the likely route to reunifying quality and friendly semantic mods; none is ready to replace 1964GEPD today under the direct-N64-ROM constraint.

The experimental MGB64 runtime is vendored as a squashed subtree so local changes are editable and upstream provenance stays visible. The Quality Adapter downloads its exact upstream release instead. Public binary redistribution remains gated on a file-level provenance and notice review; local gameplay success does not resolve that legal question.

## Recommendation

Historical recommendation: use the **N64Recomp ecosystem as the primary engineering line**, with N64ModernRuntime as the low-level runtime/mod substrate and GoldenRecomp as the closest game-specific experiment. Build a separate Lua-first GoldenEyeModel on top to deliver Gen1Recomp-like mod ergonomics.

An important distinction: Gen1Recomp is a handwritten Lua/LÖVE2D reimplementation that imports data from the player's ROM; it is not itself an N64 static recompiler. This project should mimic its product setup and mod-author experience, not copy its internal runtime architecture. GoldenEye's real-time N64 execution, renderer, timing, and native-code needs make a C++ recompilation host the more appropriate core.

This recommendation is provisional until Phase 0 proves four things:

1. a reproducible desktop build can complete Dam and at least one later mission;
2. the public launcher can accept an ordinary verified US ROM and create the private artifacts the runtime needs;
3. the distributed artifacts have acceptable provenance and licensing;
4. a physical Android Vulkan spike can render and survive lifecycle transitions.

Do not begin by distributing a build made directly from the GoldenEye decompilation. That repository is invaluable for symbols and behavior, but its licensing/provenance must be reviewed first.

## Sources audited

The audit on 2026-08-23 examined:

| Upstream | Audited revision | Useful role | Key concern |
|---|---|---|---|
| [N64Recomp](https://github.com/N64Recomp/N64Recomp) | `ffb39cd` | static recompilation, mod recompiler/merger/tooling | game integration still project-specific |
| [N64ModernRuntime](https://github.com/N64Recomp/N64ModernRuntime) | current checkout during audit | C++20 host and mature native mod machinery | Android is not a turnkey supported target |
| [RT64](https://github.com/rt64/rt64) | current checkout during audit | desktop renderer, texture replacement | Android window paths contain explicit unimplemented branches |
| [GoldenRecomp](https://github.com/kholdfuzion/GoldenRecomp) | `f31b5d1` | GoldenEye-specific recomp experiment and patch knowledge | work in progress; special transformed ROM/ELF flow; no release |
| [GoldenEye decompilation](https://github.com/n64decomp/007) | `c4356466` | symbols, structures, behavior, build comparison | no obvious repository-level license; proprietary-header provenance needs review |
| [MGB64](https://github.com/akratch/mgb64) | `0d1d40b4` | experimental mod runtime, launcher, renderer, direct ROM flow | documented fidelity/platform gaps; public redistribution still needs file-level provenance review |
| [1964GEPD](https://github.com/Graslu/1964GEPD) | release `latest`, bundle dated 2023-07-03 | quality Windows Adapter, GoldenEye timing fixes, Mouse Injector, GLideN64 | Windows/emulator-only; aggregate plugin/texture licensing favors direct upstream retrieval |

Revisions should be captured again in a machine-readable dependency lock when implementation begins.

## Option comparison

| Option | Ordinary N64 ROM | Desktop | Android | Mod foundation | Maturity for this goal | Decision |
|---|---:|---:|---:|---:|---|---|
| N64Recomp + N64ModernRuntime + game patches | achievable through local import | strong | substantial port work | strong native base | useful research, longer integration | research |
| GoldenRecomp unchanged | transformed ROM/ELF currently expected | early | absent | upstream N64Recomp lane | useful experiment | research/fork input |
| GoldenEye decomp native port | local baserom build | potentially | potentially | must design | code understanding is strong, product integration unclear | reference, not first distribution line |
| 1964GEPD + GLideN64 | ordinary US ROM directly | mature Windows bundle | no | ROM hacks, cheats, plugins | strongest proven ROM-only play quality | **quality Adapter** |
| MGB64/source-port line | ordinary ROM directly | Windows/Linux/macOS paths | no established Android target | custom Lua layer implemented | editable but visible input/render gaps | **experimental Adapter** |
| XBLA recomp projects | requires unreleased Xbox game files | some builds | some builds | varies | fails the N64-ROM requirement | reject |
| generic emulator plus ROM patches | yes | mature | mature | mature ROM-hack ecosystem | less GoldenEye-specific than 1964GEPD | compatibility input only |

## Why not merely expose N64ModernRuntime mods?

N64ModernRuntime already contains valuable machinery: manifests, ordering, dependencies, configuration, events, hooks, code mods, ROM-patch content types, live-recompiler handles, and mod enable/detail operations. Rebuilding that substrate would waste effort.

Its natural author level is still lower than Gen1Recomp's. GoldenEye modders should usually write “patch the PP7 weapon” or “listen for an objective completion,” not manipulate recomp symbols and memory sections. The plan therefore keeps native mods as an expert lane and adds a semantic Lua lane as a custom content type/embedded Module.

## Direct-ROM import strategy

The desired player experience is direct selection of a normal ROM. MGB64 already supplies the short path:

1. File picker selects a local ROM.
2. GameImage normalizes z64/n64/v64 byte order in memory or private cache.
3. It verifies the supported US game image.
4. It normalizes byte order in memory and passes the selected path to the runtime.
5. It stores the remembered path and user settings, not a ROM copy.

Future texture/content derivation must remain private and versioned, but it is not part of first launch.

## Known technical gaps inherited from the GoldenEye recomp experiment

The initial ledger includes:

- incomplete multiplayer UI/behavior;
- black or missing skybox/water effects tied to custom graphics commands;
- 60 fps changes that accelerate weapons or other simulation behavior;
- incomplete modern dual-analog controls;
- a Windows-oriented original tool flow;
- reliance on special transformed game inputs;
- no ready Android packaging path.

These are baseline exit criteria, not “later polish.” We must know which problems block mission completion, determinism, or a stable mod Interface before building the mod manager.

## Android finding

RT64 currently advertises Windows, Linux, and macOS as its supported desktop platforms and includes D3D12, Vulkan, and Metal work. Although Android-related build definitions exist, the audited source has explicit Android-unimplemented window/application paths. N64ModernRuntime also has desktop-focused platform assumptions.

Therefore Android is a feasibility gate with a time box, not a launch promise. The spike must prove:

- Android arm64 build and JNI/Kotlin startup;
- Vulkan surface creation and frame presentation;
- controller and touch event delivery;
- audio focus and low-latency output;
- pause/resume, background/foreground, rotation policy, and process recreation;
- Storage Access Framework ROM import;
- acceptable performance on both Adreno and Mali.

If RT64 cannot be adapted within the time box, record the evidence and choose between a second renderer Adapter, desktop-first scope, or stopping. Do not let a permanent half-port consume the whole project.

## Existing GoldenEye community

The mature community is primarily ROM-hack and editor oriented, especially GoldenEye Setup Editor and N64 Vault distribution practices. That community should not be asked to abandon its work.

There is not currently one ready, consolidated GoldenEye native-recomp mod community with Gen1Recomp's exact install-and-author workflow. The realistic community strategy is to connect three existing groups—GoldenEye ROM hackers, N64Recomp/runtime contributors, and Lua/content modders—then earn a dedicated package ecosystem through good tools and compatibility. “Has a good community” is therefore a project outcome and adoption risk, not a feature we can inherit automatically.

Compatibility should use explicit Adapters:

- import or convert independently authored Setup Editor project/export data when the format permits;
- let a user apply BPS/xdelta/IPS patches privately to their own verified ROM as a separate game-build profile;
- inspect and report compatibility instead of silently loading incompatible memory patches;
- document how semantic `.gemod` packages differ from ROM patches;
- never redistribute patched ROMs or extracted copyrighted assets.

A raw patch is not treated as a Lua mod. It produces another private GameInstall with its own hash and compatibility identity.

## Fork and upstream strategy

- Begin with pinned forks only for experiments.
- Keep one patch ledger per upstream: reason, originating issue, tests, and upstream status.
- Upstream general N64Recomp/N64ModernRuntime/RT64 improvements whenever feasible.
- Keep GoldenEye-specific semantic knowledge in this repository.
- Rebase only at planned dependency windows after replay and ABI tests.
- Never depend on an unreviewed mutable branch for a release.
- Preserve upstream licenses and notices in release bundles.

## Phase 0 selection scorecard

Score each candidate baseline from 0–3 and keep raw evidence:

| Criterion | Weight |
|---|---:|
| Clean build from pinned sources | 3 |
| Completes representative missions | 3 |
| Ordinary ROM can be imported privately | 3 |
| No game data required in public artifact | 3 |
| License/provenance is documentable | 3 |
| Renderer correctness | 2 |
| Correct timing at 30/60 presentation | 2 |
| Controller and audio stability | 2 |
| Native mod substrate integration | 2 |
| Android port surface is measurable | 2 |
| Debug symbols and diagnostics | 1 |
| Upstream activity and collaboration path | 1 |

A baseline that fails provenance or ordinary-ROM import is rejected regardless of total score.
