# Gen1Recomp parity target

## What “mimic Gen1Recomp” means

Gen1Recomp's value is not merely that Lua runs. It provides a coherent product loop: legal local import, quick launch, native mod discovery, semantic content, safe loading, a manager, profiles, author tools, documentation, tests, and cross-platform releases. This plan targets that experience while adapting it to a real-time N64 shooter.

Gen1Recomp is a product and workflow reference, not a source dependency.

## Player parity matrix

| Gen1Recomp experience | GoldenEye target | Milestone | Acceptance evidence |
|---|---|---:|---|
| Select supported ROM on first boot | select ordinary US GoldenEye ROM | M2 | hash/byte-order tests and clean-machine video |
| Private data import/cache | atomic private GameInstall | M2 | interrupted import recovery; repository scan |
| Launcher no longer needs ROM path | launch from versioned private install | M2 | move source ROM; launch still succeeds |
| Desktop packages | Windows/Linux first, macOS after baseline | M1/M7 | signed/checksummed artifacts and smoke tests |
| Android APK | optional post-desktop arm64 port | optional M4 | Adreno and Mali device runs before support claim |
| Portable gameplay/content mods | platform-neutral Lua `.gemod` | M7 | same package works on Windows/Linux; future Android consumes it unchanged |
| In-app mod manager | install, enable, disable, order, inspect | M7 | automated UI/state tests |
| Profiles | isolated enabled sets and order | M7 | switch and restore tests |
| ZIP import | local picker/share import | M7 | malformed/safe archive test corpus |
| Dependencies and conflicts | deterministic resolver and explanation | M5 | table-driven solver tests |
| Per-mod options | schema-generated settings | M5/M7 | validation and migration tests |
| Update metadata | explicit checked updates | M7/M10 | signed catalog fixtures |
| Safe mode | recover from failing mod set | M5/M7 | injected failure scenario |

## Author parity matrix

| Gen1Recomp capability | GoldenEye equivalent | Milestone | Acceptance evidence |
|---|---|---:|---|
| Lua entry function | `return function(mod)` | M5 | reference mod |
| Content registries | GoldenEye semantic registries | M6 | weapon/text/objective vertical slice |
| register/override/patch/remove | same registry vocabulary | M6 | merge/provenance tests |
| Schemas and dangling references | canonical schemas and graph validation | M5/M6 | malformed fixture suite |
| Events | mission/guard/objective/weapon events | M6 | trace/replay assertions |
| Middleware hooks | combat/weapon/AI hooks | M6 | deterministic ordering tests |
| Error isolation | callback attribution and policy | M5 | fault injection |
| Load rollback | per-mod transaction journal | M5 | no partial state test |
| Per-mod save/storage | scoped Persistence Module | M5 | namespace/security/migration tests |
| Permissions | named capabilities and prompts | M5/M7 | denial and escalation tests |
| Asset transforms | private named-source transformations | M8 | rights-safe fixture |
| Hot reload | transactional Lua reload | M8 | fail-and-restore test |
| Developer console | logs, query, provenance, trace | M8 | scripted console tests |
| Scaffold command | `gemod new` | M8 | snapshot/golden project |
| Validate/lint/pack | `gemod validate/lint/pack` | M8 | runtime parity and reproducibility |
| Generated reference docs | schema/binding-generated docs | M8 | drift check |
| Tutorial ladder | tested shooter-specific lessons | M8 | every example runs |
| Release workflow | deterministic package and catalog submission | M10 | sample GitHub release |

## Runtime differences that require deliberate adaptation

### Real-time simulation

GoldenEye has frame pacing, input latency, AI, collision, audio, and renderer behavior that can be destabilized by callbacks. Lua operations need phase/thread contracts and budgets. Gen1-style convenience cannot mean running arbitrary work in audio or rendering critical sections.

### Entity identity

Pokémon definitions are naturally keyed content. GoldenEye also has short-lived runtime entities. Lua receives generation-checked handles and semantic IDs, never durable pointers. A handle becoming invalid is a normal, testable outcome.

### Mission scripting and AI

GoldenEye setup commands and AI lists can form powerful but unsafe low-level Interfaces. The first release should expose high-value schema-backed operations and events. A raw script compiler or arbitrary command injection belongs in a later expert lane after validation and lifecycle semantics exist.

### Presentation versus simulation rate

A 60 fps renderer must not double game behavior. Mod event frequency and timers bind to documented simulation clocks. Replays record which clock an assertion uses.

### Existing ROM-hack culture

Gen1Recomp can establish a newer mod package culture. GoldenEye already has Setup Editor and ROM-patch communities. This project needs conversion and private-patch Adapters, clear documentation, and respectful collaboration rather than a replacement narrative.

## Scope levels

### Minimum lovable alpha

- ordinary ROM import and private install;
- stable desktop completion of representative missions;
- Lua manifest and sandbox;
- weapon registry patch;
- mission/objective event;
- one safe runtime operation;
- dependency resolution and rollback;
- local ZIP install;
- scaffold/validate/pack;
- three excellent example mods.

### Gen1Recomp-shaped beta

Add Windows/Linux releases, profiles, manager, options, storage/save migrations, asset transforms, hot reload, console, tutorials, catalog updates, robust safe mode, and broader registries. Android is a separate later port, not a beta requirement.

### Later ecosystem depth

Add community conversions, richer mission/AI authoring, native extension SDK, multiplayer-specific Interfaces, accessibility mods, deterministic challenges/replays, localized docs, and a mature public index.

The alpha should prove depth and joy in a narrow author loop before breadth.
