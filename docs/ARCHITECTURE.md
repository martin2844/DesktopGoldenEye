# Architecture

## Architecture objective

The architecture must make a difficult runtime feel simple to players and mod authors. Its central rule is: keep N64 recompilation, memory mapping, renderer details, asset derivation, dependency solving, and platform lifecycle behind a small number of deep Modules. Public Lua Interfaces describe GoldenEye concepts, not implementation addresses.

The target flow is:

```text
user ROM
   │
   ▼
GameImage.inspect/normalize
   │
   ▼
MGB64 Windows/Linux Adapter ──► GameRuntime ─► WebGPU/OpenGL
                                   │
                                   ▼
                              ModPlatform
                 ┌──────────┴──────────┐
                 ▼                     ▼
          Lua author lane       native expert lane
                 │
                 ▼
        GoldenEye semantic Interface
       registries + events + hooks + saves
```

## Architecture vocabulary

This project uses these terms precisely:

- **Module:** implementation plus its public Interface.
- **Interface:** everything another Module can observe, including functions, data formats, errors, ordering, and timing.
- **Implementation:** decisions hidden inside a Module.
- **Depth:** how much complexity an Interface hides relative to its size.
- **Seam:** the intentional meeting point between Modules.
- **Adapter:** translation at a real Seam, such as Windows and Linux desktop host integration.
- **Leverage:** how much useful behavior one Interface operation provides.
- **Locality:** keeping related knowledge and change together.

A new abstraction is justified only when it hides meaningful complexity or when two implementations actually meet at a Seam. Thin pass-through wrappers are not architecture.

## Proposed deep Modules

### 1. GameImage

**Responsibility:** verify a user-selected ROM and expose normalized bytes to the runtime without copying the source ROM into the repository or release.

**Initial Interface:**

```cpp
ImportResult inspect(const FileRef& rom);
NormalizedGameImage open(const FileRef& rom);
void verify(const NormalizedGameImage&);
```

It hides ROM byte order, supported revision checks, and the normalized in-memory view consumed by the engine. MGB64 already handles `.z64`, `.v64`, and `.n64` inputs directly; a private derived-asset cache should be added only when a real mod feature needs one.

The initial accepted ROM is the US release with SHA-1:

```text
abe01e4aeb033b6c0836819f549c791b26cfde83
```

Other revisions are separate compatibility work. The ROM stays in the user's chosen location and is never copied into Git or a release bundle.

### 2. GameRuntime

**Responsibility:** own one executing game instance.

**Conceptual Interface:**

```cpp
RuntimeSession start(const GameInstall&, const LaunchProfile&);
void submit_input(RuntimeSession&, const InputFrame&);
FrameResult run_frame(RuntimeSession&);
Checkpoint save_checkpoint(RuntimeSession&);
void stop(RuntimeSession&);
```

It hides recompiled functions, N64 memory and thread scheduling, audio queues, frame pacing, save emulation, bridge calls, and crash containment. The exact Interface will follow the selected upstream rather than forcing this sketch onto it.

Game simulation timing and presentation timing must be distinct. A higher display rate must not accelerate weapons, guards, doors, or mission scripts.

### 3. ModPlatform

**Responsibility:** discover, validate, resolve, load, and apply mods as one transaction.

**Conceptual Interface:**

```cpp
Catalog scan(const ModLocation&);
Resolution resolve(const Catalog&, const Profile&);
LoadReport load(const Resolution&, GameRuntime&);
void unload(GameRuntime&);
```

Its Implementation is a focused C++17 Module inside MGB64's app shell. The current ROM-free Seam includes directory discovery, strict `manifest.toml` validation, persisted explicit enable state, one isolated/bounded Lua state per mod, transactional rollback, and the first semantic operation (`game.unlock_all_levels`). It will add dependency resolution, schema-backed registries, broader permissions, scoped persistence, diagnostics, and cross-platform packages in that order.

A failed mod load must either roll back all of that mod's registrations or fail the launch before gameplay. Partial mutation is not allowed.

### 4. GoldenEyeModel

**Responsibility:** expose high-Leverage GoldenEye concepts to mods.

This is the primary Lua Interface. It translates between stable semantic identifiers and unstable game Implementation. Candidate registries are:

- weapons and ammo;
- missions, difficulties, objectives, and briefings;
- character and guard archetypes;
- guard actions and AI lists where they can be made safe;
- items, props, doors, alarms, and cameras;
- text and localization entries;
- multiplayer scenarios, weapon sets, and spawn sets;
- cheats, music routing, and renderer asset substitutions.

The first vertical slice is intentionally smaller: weapon properties, mission text/objective metadata, and a controlled spawn operation. Every operation needs schema validation, useful errors, no-mod parity tests, and documented lifecycle availability before the registry expands.

Events notify; hooks change behavior. Events include `mission.started`, `objective.completed`, `guard.spawned`, and `weapon.fired`. Hooks may include `combat.damage`, `weapon.select`, and `ai.reaction`. Callback failures are isolated and attributed to the owning mod.

Raw memory access is not part of the stable Lua Interface. A quarantined experimental or native permission may exist for reverse engineering, but packages using it cannot claim stable compatibility.

### 5. Persistence

**Responsibility:** provide game saves, mod saves, options, storage, and checkpoints without path sharing.

**Interface properties:**

- every key is scoped by mod ID and data class;
- writes are atomic;
- schema versions and migrations are explicit;
- quotas are enforceable;
- Android document/storage rules do not leak into mods;
- uninstall and profile-switch semantics are documented;
- a mod cannot read another mod's data without a granted permission.

### 6. PlatformHost

**Responsibility:** adapt the runtime to Windows and Linux desktop hosts first, with Android only as a later optional Adapter.

MGB64's existing application shell owns windows, controllers, filesystem dialogs, logging, and shutdown. The same SDL2/ImGui shell has Windows and Linux paths; platform-specific behavior stays behind those existing Seams. A future Android Adapter may own Activity lifecycle, Storage Access Framework ROM selection, controller/touch input, audio focus, suspend/resume, thermal state, and process recreation.

Kotlin should stay thin: permissions, file picker, settings screens, and lifecycle forwarding. Gameplay behavior belongs in shared C++.

### 7. RendererHost

Desktop uses MGB64's proven WebGPU/OpenGL renderer paths. Windows is qualified first, followed by Linux. If the optional Android port begins later, it is not treated as another compile flag. That future spike must compare adapting the existing renderer, adding a GLES/Vulkan mobile Adapter, or deliberately deferring Android.

Do not create a generic renderer Interface until the spike produces a second viable Adapter. Premature abstraction would hide no complexity and reduce Locality.

### 8. Toolchain

**Responsibility:** make the author loop short and reproducible.

A Python command named provisionally `gemod` should provide:

```text
gemod new
gemod run
gemod validate
gemod lint
gemod pack
gemod docs
gemod inspect
```

The tool owns manifest schemas, scaffolding, package reproducibility, interface-version checks, static Lua checks, and local launcher discovery. Runtime schemas and tool schemas must be generated from one canonical source or compared in CI.

## Boot and mod lifecycle

```text
boot
  → locate or import GameInstall
  → verify importer/runtime compatibility
  → scan installed packages
  → validate manifests and permissions
  → resolve versions, dependencies, conflicts, and order
  → create isolated Lua states/environments
  → execute entry chunks into a transaction journal
  → merge and validate registries
  → freeze structural content
  → start GameRuntime
  → keep events, hooks, options, and scoped storage open
  → save/stop/unload in reverse order
```

Structural content freezes after the merge. Runtime mutation occurs only through documented runtime operations, events, and hooks. This preserves determinism and makes conflict diagnostics possible.

## Package and version layers

The system has several independent versions:

- launcher/application version;
- importer/cache format version;
- native runtime ABI;
- Lua Interface version;
- game revision;
- mod package format version;
- individual mod semantic version.

Never collapse these into one “version.” A manifest declares the Lua Interface range, supported game revisions, and dependencies. The manager explains incompatibility instead of merely disabling a package.

## Threading and ownership

- The GameRuntime owns N64 execution state.
- Lua callbacks execute on the simulation thread unless an Interface explicitly documents otherwise.
- Rendering consumes immutable or double-buffered frame data.
- Audio has a bounded queue and never calls arbitrary Lua from its real-time thread.
- File and network work is asynchronous and returns results at safe simulation points.
- A mod receives handles with generation checks, not durable pointers.
- The runtime owns teardown order; mods cannot outlive the session.

These rules should be encoded in assertions and sanitizer builds, not left as convention.

## Security model

Lua is embedded for ergonomics, not as a claim of perfect hostile-code security. The default environment omits unrestricted filesystem, process, dynamic-library, debug, and network facilities. Capabilities are named in the manifest and approved at install or enable time.

Initial permissions:

- `storage`: scoped persistent files only;
- `network`: outbound HTTP through a constrained host operation;
- `clipboard`;
- `native_code`: compiled native module, with prominent warning;
- `experimental_memory`: unstable research access, never accepted by the public index by default.

Resource controls include callback time budgets, memory quotas where practical, recursion/error guards, and per-mod log attribution. Native code is trusted at process level and presented as such.

## Proposed repository layout

```text
/
├── apps/
│   ├── desktop/          desktop Adapter and launcher UI
│   └── android/          Kotlin shell, Gradle project, JNI Adapter
├── runtime/
│   ├── game_image/       import, verify, private cache
│   ├── game_runtime/     recomp host and execution ownership
│   ├── goldeneye_model/  semantic registries/events/hooks
│   ├── mod_platform/     resolver, Lua host, transactions
│   ├── persistence/
│   └── renderer/
├── tools/
│   ├── gemod/            Python author CLI
│   └── generators/       schema/docs/binding generation
├── schemas/              canonical manifest and content schemas
├── mods/
│   └── examples/         original, ROM-free example mods
├── tests/
│   ├── fixtures/         synthetic public fixtures
│   ├── integration/
│   ├── replay/
│   └── private/          ignored ROM-backed tests
├── third_party/          pinned dependencies and notices
└── docs/
```

This layout is provisional. It groups knowledge by deep Module and keeps platform-specific code at the actual Adapter Seams.

## Dependency policy

- Pin upstream commits initially; record commit, license, patches, and purpose.
- Prefer upstreamable patches over permanent hidden forks.
- Keep a patch ledger and regularly test against newer upstream revisions.
- Do not vendor data whose redistribution status is unclear.
- Make generated artifacts reproducible and identify their source hashes.
- Use lockfiles or checksums for Python and Android tools.
- Produce a software bill of materials for releases.
- Preserve upstream notices and comply with each license.

## Performance budgets

Initial targets, to validate rather than promise:

| Area | Desktop target | Android target |
|---|---:|---:|
| Simulation | original-correct, decoupled from display | same |
| Presentation | stable 60 fps at 1080p on a modest GPU | stable 30/60 profiles at device resolution |
| Input-to-frame | under 50 ms typical | under 70 ms typical |
| Audio | no underruns over a 30-minute run | no underruns across focus changes |
| Mod overhead | under 1 ms median per simulation frame for reference profile | under 2 ms |
| Cold launch after import | under 5 seconds | under 8 seconds |
| Import recovery | atomic; no corrupt install after termination | same |

Any later Android qualification must include Snapdragon/Adreno and ARM/Mali hardware. Emulator-only results do not qualify.

## Architectural definition of done

The architecture is validated when:

- a clean machine can build the chosen desktop baseline from pinned sources;
- a player can select a normal supported ROM and later launch without reselecting it;
- the launcher and public repository contain no game data;
- Dam can be completed with no mods and with a simple Lua mod;
- the same mod archive works on Windows and Linux;
- disabling all mods restores byte/behavior-level equivalence for tested state;
- dependency conflicts and Lua errors produce actionable diagnostics;
- public Interfaces are documented, schema-validated, and covered by compatibility tests;
- the optional Android lifecycle/controller/audio/storage suite passes before any Android support claim;
- the provenance review allows the intended distribution artifact.
