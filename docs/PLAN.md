# Comprehensive execution plan

## Outcome

Build an unofficial, cleanly distributed GoldenEye 007 mod platform where:

- the player selects a legally obtained ordinary US N64 ROM;
- import happens locally and produces a private, versioned GameInstall;
- the native runtime plays reliably on desktop and Android;
- the same Lua `.gemod` package works on both;
- a beginner makes a useful first mod in under 15 minutes;
- advanced authors can use native N64Recomp mods without forcing that complexity on everyone;
- the project collaborates with the existing GoldenEye ROM-hack community.

The shortest honest route is not “make a full mod SDK first.” It is:

```text
provenance + runnable game
→ direct-ROM product flow
→ timing/renderer correctness
→ physical Android proof
→ narrow semantic mod slice
→ manager and author tools
→ ecosystem breadth
```

## Success metrics

### Player metrics

- Clean install to first playable frame in under 10 minutes, excluding ROM acquisition.
- Imported ROM never needs to remain accessible to the launcher.
- Dam completion succeeds on supported desktop and Android hardware.
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
- Desktop and Android Lua package hashes are identical.
- Release artifacts include checksums, build metadata, and a software bill of materials.
- Public index packages state permissions and immutable hashes.

## Guiding decisions

1. **C++20 is the product language.** It matches N64Recomp, N64ModernRuntime, RT64, platform tooling, performance, and Android NDK constraints.
2. **Lua 5.4 is the default mod language.** It gives the short, reloadable author loop seen in Gen1Recomp.
3. **Kotlin is only the Android Adapter.** It owns platform UX/lifecycle and delegates runtime logic to shared C++.
4. **Python owns author/build tools.** It is suitable for schemas, scaffolding, lint orchestration, deterministic packaging, and inspection.
5. **Semantic Interfaces precede breadth.** One deep weapon registry is worth more than dozens of thin memory wrappers.
6. **N64ModernRuntime machinery is reused.** The project adds a friendly layer rather than recreating dependency resolution, native hooks, and code-mod infrastructure.
7. **Android is a gate.** It is tested early because current renderer/runtime support is incomplete.
8. **Private import is a product feature.** Legal/provenance constraints shape architecture, CI, caching, and community tooling from day one.

## Critical path

```text
M0 provenance/upstream gate
 └─ M1 reproducible desktop baseline
     └─ M2 direct-ROM private installer
         └─ M3 correctness/timing baseline
             ├─ M4 Android feasibility
             └─ M5 mod kernel
                  └─ M6 semantic vertical slice
                      ├─ M7 player manager/cross-platform package
                      └─ M8 author toolchain/docs
                           └─ M9 community bridge
                               └─ M10 beta/community release
```

M4 should begin as soon as M1 can present frames; it may overlap M2/M3 research. M5 may prototype against a synthetic host before game hooks stabilize, but no public Interface freezes until M3.

## Work streams

### A. Provenance and reproducibility

Deliverables:

- dependency inventory with exact revisions, licenses, notices, and redistribution status;
- classification of generated recompilation artifacts;
- clean-room/contribution policy;
- reproducible bootstrap/build command;
- patch ledger for every upstream fork;
- decision on whether game code is generated locally or may be part of a binary.

Owner skill set: build engineering, open-source licensing research, N64 toolchain knowledge. Obtain qualified legal advice before public distribution if uncertainty remains.

### B. Native game baseline

Deliverables:

- pinned GoldenEye recomp build;
- normal-ROM transformation/import recipe;
- reliable controller, audio, save, renderer, and shutdown;
- known-issue census across all missions and multiplayer menus;
- decoupled simulation/presentation timing;
- skybox/water/custom graphics command correctness;
- debug symbols, traces, and repeatable controller playback.

Keep this work below the GameRuntime and GameImage Interfaces.

### C. Android host and renderer

Deliverables:

- arm64 Gradle/NDK build;
- Kotlin/JNI lifecycle Adapter;
- Vulkan surface and renderer decision;
- Storage Access Framework import;
- controller and optional touch mapping;
- audio focus, suspend/resume, process recreation, thermal/performance profiles;
- physical-device matrix and diagnostic bundle.

This stream has a hard feasibility checkpoint. Desktop-first is an explicit fallback, not an unspoken failure.

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
- ZIP install on desktop and Android;
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
| M4 Android spike | 2–4 weeks for decision; longer for product | RT64/platform port |
| M5–M6 mod kernel and semantic slice | 5–10 weeks | bridge stability and schemas |
| M7–M8 manager and author experience | 5–10 weeks | cross-platform UX/tool polish |
| M9–M10 ecosystem beta | 4–12 weeks | community formats, release hardening |

Total to a narrow, genuinely pleasant alpha: roughly 4–8 months part-time if M0/M4 pass. Community-grade beta: roughly 9–18 months. A newcomer learning N64 internals and Vulkan should expect more. Estimates exclude a major renderer rewrite or legal redesign.

## First two weeks

### Days 1–2: establish evidence

- Install missing desktop prerequisites from [PREREQUISITES.md](PREREQUISITES.md).
- Create `docs/evidence/` templates for dependency, build, mission, and provenance records.
- Record exact upstream revisions and initialize patch ledgers.
- Verify the personal US ROM hash without moving it into the repository.
- Decide whether the first native build runs under Linux/WSL or native Windows; record why.

### Days 3–5: reproduce the closest game baseline

- Clone selected upstreams recursively at pinned revisions.
- Follow the upstream GoldenRecomp build exactly before changing anything.
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

### Days 13–14: Android feasibility kickoff and review

- Build a minimal arm64 Kotlin/JNI/Vulkan surface probe.
- Route lifecycle/input logs into shared C++.
- Attempt the renderer host path and inventory compile/runtime blockers.
- Run on one physical device.
- Review all gates, update risks, and decide the next two-week slice.

A slower desktop build should not be hidden by starting lots of launcher UI. If M1 is not reproducible, remain in M1.

## Release stages

### Developer proof

Private/local only. Normal ROM import may be command-line. One mission and one semantic mod. No compatibility promise.

### Technical alpha

Desktop binaries for a small tester group. Direct ROM picker, local mods, safe diagnostics, frozen package format only if evidence supports it. Android may remain an experimental APK.

### Modder alpha

Stable Lua Interface slice, author CLI, examples/tutorials, profiles, package import, feedback channel. Breaking changes are allowed but migrated/documented.

### Public beta

Supported desktop and Android matrix, recovery, signed/checksummed releases, public index, moderation/takedown path, compatibility policy, crash diagnostics, and a representative mod catalog.

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
- Create issue templates for runtime bug, mod Interface request, Android device report, and package-index review.
- Establish a code of conduct and moderation/takedown workflow before opening the package index.

## Decision and stopping rules

Pause or narrow the project when:

- provenance review cannot support the intended public artifact;
- ordinary-ROM local import cannot be made reliable;
- the baseline cannot complete representative missions after a bounded M1/M3 effort;
- Android rendering requires an unmaintainable permanent fork and desktop-first no longer feels worthwhile;
- Lua semantic hooks measurably destabilize simulation without a safer bridge;
- maintenance cost exceeds the pet-project goal.

A failed gate is useful evidence. The fallback order is: narrow Android promise → desktop-first alpha → reconsider renderer/runtime baseline → stop public distribution but keep research notes.

## Overall definition of done

The project has fulfilled its original promise when a new player can install an asset-free desktop or Android build, select their own verified ROM, play GoldenEye, install the same safe Lua mod package on either platform, manage profiles and errors, and follow tested documentation to create a mod quickly—while native experts retain a deeper extension lane and public artifacts remain provenance-clean.
