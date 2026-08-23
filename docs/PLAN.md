# Comprehensive execution plan

## Outcome

Build an unofficial, cleanly distributed GoldenEye 007 mod platform where:

- the player selects a legally obtained ordinary US N64 ROM;
- the selected ROM is validated and normalized in memory without entering Git or release artifacts;
- the native runtime plays reliably on Windows first and Linux next;
- the Lua `.gemod` package is platform-neutral and works across supported PC builds;
- a beginner makes a useful first mod in under 15 minutes;
- advanced authors can work directly in the C/C++ engine without forcing that complexity on everyone;
- the project collaborates with the existing GoldenEye ROM-hack community.

The shortest honest route is not “make a full mod SDK first.” It is:

```text
provenance + runnable game
→ direct-ROM product flow
→ timing/renderer correctness
→ Windows/Linux product baseline
→ narrow semantic mod slice
→ manager and author tools
→ ecosystem breadth
```

## Success metrics

### Player metrics

- Clean install to first playable frame in under 10 minutes, excluding ROM acquisition.
- The ROM remains in the player's chosen location and is never copied into the application or release.
- Dam completion succeeds on supported Windows and Linux PC builds.
- Reference mod profile launches successfully at least 99% across automated stress runs.
- A broken Lua mod yields an actionable diagnostic and safe-mode recovery, not a crash loop.
- No-mod profile matches recorded vanilla state/replay assertions.

### Author metrics

- Scaffold to visible PP7 damage change in under 15 minutes for a Lua-capable beginner.
- Edit-to-result loop under 5 seconds for reload-safe changes.
- Manifest/Interface errors are reported before packaging.
- Package build is byte-for-byte reproducible.
- Tutorial snippets execute in CI.
- 80% of early community mod requests fit semantic Interfaces without raw memory access; the remainder informs native lane priorities.

### Distribution metrics

- Release source and launcher contain zero detected ROM/game-asset material.
- Every dependency has a pinned revision, license/provenance status, and notice.
- Windows and Linux Lua package hashes are identical.
- Release artifacts include checksums, build metadata, and a software bill of materials.
- Public index packages state permissions and immutable hashes.

## Guiding decisions

1. **Portable C plus C++17 remain the native/mod implementation languages.** The immediate 1964GEPD Quality Adapter is an external GPL C runtime; the launcher does not fork it merely to claim one language.
2. **Lua 5.4 is the default mod language.** It gives the short, reloadable author loop seen in Gen1Recomp.
3. **Windows is the first executable baseline.** It is built and ROM-smoke-tested through MSYS2/MinGW64. Linux becomes the second PC Adapter after the Lua vertical slice.
4. **Python owns author/build tools.** It is suitable for schemas, scaffolding, lint orchestration, deterministic packaging, and inspection.
5. **Semantic Interfaces precede breadth.** One deep weapon registry is worth more than dozens of thin memory wrappers.
6. **Quality and mod hosting are separate Adapters for now.** 1964GEPD is the default player Implementation; MGB64 retains the focused mod catalog, Lua host, transactions, and semantic experiments. The Runtime Interface prevents launcher coupling to either.
7. **Android is optional after desktop alpha.** Shared Interfaces stay portable, but Android cannot block the PC product.
8. **Private import is a product feature.** Legal/provenance constraints shape architecture, CI, caching, and community tooling from day one.

## Critical path

```text
M0 provenance/upstream gate
 └─ M1 reproducible desktop baseline
     └─ M2 direct-ROM private installer
         └─ M3 correctness/timing baseline
             └─ M5 mod kernel
                  └─ M6 semantic vertical slice
                      ├─ M7 player manager/cross-platform package
                      └─ M8 author toolchain/docs
                           └─ M9 community bridge
                               └─ M10 beta/community release
```

M5 may prototype against a synthetic host before game hooks stabilize, but no public Interface freezes until M3. Optional M4 begins only after a useful desktop alpha unless a contributor independently owns it.

## Work streams

### A. Provenance and reproducibility

Deliverables:

- dependency inventory with exact revisions, licenses, notices, and redistribution status;
- classification of the vendored source-port files and any future derived assets;
- clean-room/contribution policy;
- reproducible bootstrap/build command;
- patch ledger for every upstream fork;
- decision on whether game code is generated locally or may be part of a binary.

Owner skill set: build engineering, open-source licensing research, N64 toolchain knowledge. Obtain qualified legal advice before public distribution if uncertainty remains.

### B. Native game baseline

Deliverables:

- pinned MGB64 source-port build;
- ordinary-ROM validation and byte-order normalization path;
- reliable controller, audio, save, renderer, and shutdown;
- known-issue census across all missions and multiplayer menus;
- decoupled simulation/presentation timing;
- skybox/water/custom graphics command correctness;
- debug symbols, traces, and repeatable controller playback.

Keep this work below the GameRuntime and GameImage Interfaces.

### C. PC platform hosts

Deliverables:

- reproducible native Windows x86-64 build using the closest supported upstream route;
- Windows file picker, controller, audio, save, window/fullscreen, logging, and crash diagnostics;
- removal or isolation of Windows-only assumptions;
- Linux x86-64 build and desktop Adapter;
- identical GameImage, GameRuntime, ModPlatform, packages, saves, and replay contracts on both;
- per-platform package, controller, filesystem, and renderer qualification.

A later optional Android stream may add Kotlin/JNI, Vulkan surface, Storage Access Framework, controller/touch, audio focus, and lifecycle behavior. It begins only after the desktop alpha.

### D. Mod platform kernel

Deliverables:

- package and manifest schema;
- catalog scan and deterministic dependency resolver;
- isolated Lua environments;
- transaction journal and rollback;
- permissions/capabilities;
- canonical schema/merge/provenance engine;
- events/hooks with error containment;
- scoped persistence;
- native expert-lane bridge.

Build most kernel tests against synthetic fixtures without a ROM.

### E. GoldenEye semantic model

Deliverables:

- symbol/behavior map from game concepts to runtime bridge points;
- weapon registry;
- mission text/objective registry slice;
- guarded spawn/runtime operation;
- mission/objective/guard/weapon events;
- combat/weapon hook slice;
- stable handles and lifecycle rules;
- no-mod parity assertions and change provenance.

Each new concept needs a real use case, schema, diagnostics, lifecycle contract, and test. Avoid a catch-all “game” helper bag.

### F. Player experience

Deliverables:

- first-run ROM picker/import progress/error recovery;
- installed mod catalog and profile manager;
- enable/disable/order/options/permissions;
- ZIP install on Windows and Linux;
- safe mode and crash recovery;
- update/catalog metadata;
- diagnostic export with privacy scrub;
- controller-first launcher navigation where practical.

The launcher can start simple and utilitarian; error recovery and clarity precede visual polish.

### G. Author experience and community

Deliverables:

- `gemod` scaffold/run/validate/lint/pack/docs/inspect;
- transactional hot reload;
- developer console/event trace/provenance;
- generated Interface reference;
- tested tutorial ladder and cookbook;
- reference mods;
- GitHub release/publishing workflow;
- signed/static public index;
- N64 Vault/Setup Editor compatibility research and converters.

Talk to existing modders during M6, not after M10. Validate terminology and top mod requests before broadening registries.

## Roadmap and estimates

See [ROADMAP.md](ROADMAP.md) for detailed gates.

Indicative effort for one experienced developer, part-time:

| Phase | Expected range | Main uncertainty |
|---|---:|---|
| M0–M1 feasibility and desktop baseline | 2–4 weeks | upstream build/provenance |
| M2–M3 import and game correctness | 3–8 weeks | transformed input, renderer/timing gaps |
| Optional M4 Android spike after desktop alpha | 2–4 weeks for decision; longer for product | RT64/platform port |
| M5–M6 mod kernel and semantic slice | 5–10 weeks | bridge stability and schemas |
| M7–M8 manager and author experience | 5–10 weeks | cross-platform UX/tool polish |
| M9–M10 ecosystem beta | 4–12 weeks | community formats, release hardening |

Total to a narrow, genuinely pleasant Windows/Linux alpha: roughly 4–8 months part-time if M0/M1 pass. Community-grade beta: roughly 9–18 months. A newcomer learning N64 internals and Vulkan should expect more. Estimates exclude a major renderer rewrite, optional Android port, or legal redesign.

## First two weeks

The original schedule below is preserved as the execution baseline. As of 2026-08-23, the Windows toolchain is installed, MGB64 is pinned and vendored, the ordinary ROM validates, Dam renders, and the Mods panel transactionally loads isolated Lua packages through one semantic operation. User testing then exposed unacceptable MGB64 mouse/render quality. The immediate work has therefore moved back to M3: qualify the new 1964GEPD Quality Adapter across representative missions before expanding the mod Interface.

### Days 1–2: establish evidence

- Install missing desktop prerequisites from [PREREQUISITES.md](PREREQUISITES.md).
- Create `docs/evidence/` templates for dependency, build, mission, and provenance records.
- Record exact upstream revisions and initialize patch ledgers.
- Verify the personal US ROM hash without moving it into the repository.
- Decide whether the first native build runs under Linux/WSL or native Windows; record why.

### Days 3–5: reproduce the closest game baseline

- Clone selected upstreams recursively at pinned revisions.
- Follow the pinned MGB64 build exactly before changing anything.
- Script only the repeatable, non-proprietary steps.
- Capture compiler versions, commands, hashes, warnings, and outputs.
- Reach title screen and Dam; record controller, audio, renderer, timing, and exit behavior.
- If the build requires a special ROM, document the deterministic local transformation.

### Days 6–7: provenance and artifact audit

- Trace every input to generated C/C++/objects/assets.
- List which artifacts would enter source, CI, launcher, and release.
- Classify licenses and missing licenses.
- Test a completely game-data-free public build workspace.
- Choose or reject the provisional baseline using the Phase 0 scorecard.

### Days 8–10: thin vertical runtime proof

- Put the selected upstream behind the smallest useful GameImage/GameRuntime integration.
- Add a ROM fingerprint/import dry run.
- Add a build-info screen/log with all source/tool hashes.
- Add one trace point at a safe GoldenEye behavior, such as weapon damage lookup.
- Prove no-mod behavior before making it mutable.

### Days 11–12: Lua bridge proof

- Embed Lua 5.4 in a synthetic harness first.
- Load one manifest and one entry function.
- Implement one transactional `weapons:patch` fixture with schema errors and rollback.
- Bind that single semantic operation to the traced game behavior.
- Measure overhead and confirm disabling it restores baseline.

### Days 13–14: first semantic mod proof and review

- Embed Lua 5.4 in a synthetic harness.
- Load one manifest and one transactional weapon patch.
- Connect that patch to one traced GoldenEye behavior only if the vanilla baseline is stable.
- Rebuild from a clean Windows directory and capture every manual prerequisite.
- Review all gates, update risks, and decide the next PC-focused two-week slice.

A slower desktop build should not be hidden by starting lots of launcher UI. If M1 is not reproducible, remain in M1.

## Release stages

### Developer proof

Private/local only. Normal ROM import may be command-line. One mission and one semantic mod. No compatibility promise.

### Technical alpha

Windows binaries for a small tester group, followed by Linux when qualified. Direct ROM picker, local mods, safe diagnostics, and a frozen package format only if evidence supports it. Android is out of scope at this stage.

### Modder alpha

Stable Lua Interface slice, author CLI, examples/tutorials, profiles, package import, feedback channel. Breaking changes are allowed but migrated/documented.

### Public beta

Supported Windows/Linux matrix, recovery, signed/checksummed releases, public index, moderation/takedown path, compatibility policy, crash diagnostics, and a representative mod catalog. Android has its own later qualification stage if pursued.

### 1.0

Interface stability policy, migration window, upgrade tests, complete notices/provenance, sustainable maintainership, and demonstrated community ownership beyond one developer.

## Community plan

- Publish the scope and clean-room policy early.
- Join existing GoldenEye modding spaces respectfully and ask which workflows hurt.
- Recruit three types of testers: ROM hackers, Lua beginners, and N64Recomp/native experts.
- Maintain a public capability/request map rather than promising every request.
- Label experimental Interfaces clearly.
- Showcase small original mods and accessibility improvements.
- Offer conversion tools where formats are understood and legal, not proprietary lock-in.
- Create issue templates for runtime bug, mod Interface request, package-index review, and—only if that port starts—Android device reports.
- Establish a code of conduct and moderation/takedown workflow before opening the package index.

## Decision and stopping rules

Pause or narrow the project when:

- provenance review cannot support the intended public artifact;
- ordinary-ROM local import cannot be made reliable;
- the baseline cannot complete representative missions after a bounded M1/M3 effort;
- the Windows baseline cannot be made reproducible or the Linux port would require an unmaintainable permanent fork;
- Lua semantic hooks measurably destabilize simulation without a safer bridge;
- maintenance cost exceeds the pet-project goal.

A failed gate is useful evidence. The fallback order is: Windows-only developer alpha → reconsider renderer/runtime baseline → stop public distribution but keep research notes. Android remains independently optional.

## Overall definition of done

The project has fulfilled its primary promise when a new player can install an asset-free Windows or Linux build, select their own verified ROM, play GoldenEye, install a safe portable Lua mod package, manage profiles and errors, and follow tested documentation to create a mod quickly—while native experts retain a deeper extension lane and public artifacts remain provenance-clean. Android is a later bonus milestone.
