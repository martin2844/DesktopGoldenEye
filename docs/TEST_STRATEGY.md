# Test strategy

## Principle

Public CI must be useful without possessing GoldenEye data. Private ROM-backed tests supply integration confidence but cannot be the only tests that protect package parsing, dependency resolution, schemas, Lua behavior, persistence, platform lifecycle, or author tools.

Tests are divided by data class:

- **public synthetic:** independently authored fixtures safe for Git and public CI;
- **public structural:** hashes, generated-schema drift, licenses, package policy, and build metadata;
- **private ROM-backed:** local or access-controlled tests using a contributor's legal ROM/import;
- **manual qualification:** mission playthrough, visual/audio judgment, physical-device behavior;
- **community compatibility:** author-approved external projects with explicit provenance.

No test failure should print ROM bytes, extracted strings, or private filesystem paths into public logs.

## Test layers

### Unit tests

Fast, deterministic, ROM-free:

- ROM byte-order detection and hash logic using synthetic byte buffers;
- atomic cache state machine and interrupted-import recovery;
- semantic-version parsing and range resolution;
- dependency ordering, cycles, conflicts, optional dependencies;
- ZIP path normalization, case collision, expansion/size limits, duplicate entries;
- manifest and content schemas;
- merge modes and provenance tracking;
- registry freeze and dangling-reference checks;
- event/hook ordering, reentrancy, invalid returns, timeout/error policy;
- transaction journal commit/rollback;
- scoped persistence and migrations;
- handle generation/invalidation;
- Lua sandbox library/capability restrictions;
- deterministic package writer;
- profile serialization and compatibility explanation.

Property/fuzz tests should target parsers, resolver graphs, archives, schema values, Lua/C++ value conversion, and save migrations.

### Module contract tests

Each deep Module is tested through its Interface:

- GameImage: inspect/import/verify/remove state transitions with fake transformation tools;
- GameRuntime: synthetic runtime harness for clocks, input frames, teardown, and checkpoints;
- ModPlatform: full package discovery-to-freeze flow with original fixtures;
- GoldenEyeModel: generated/synthetic tables and fake entity bridge;
- Persistence: platform filesystem fakes plus crash-at-write points;
- PlatformHost: recorded lifecycle/input events;
- Toolchain: scaffold snapshots and pack/inspect round trips.

Contract tests prevent platform Adapters or upstream updates from changing observable behavior silently.

### Integration tests

Public integration tests combine the synthetic runtime, Lua, package loader, manager state, and author CLI. They should cover:

- two mods patching different and same fields;
- dependencies that change order;
- optional integration when another mod is present;
- conflict explanation;
- entry failure rollback;
- event callback failure;
- profile switch and safe-mode restore;
- option/save migration across mod versions;
- hot reload success and failure restore;
- desktop and Android package parser equivalence.

Private integration tests repeat the key paths against the imported real game.

## ROM-backed private suite

The private suite locates a GameInstall by environment/config outside the repository. It refuses to run if the expected supported hash is absent. It never uploads artifacts by default.

Suites:

1. **Import:** normal z64/n64/v64 variants normalize to the same identity; wrong/truncated inputs fail.
2. **Boot:** title/menu/new game/save load/clean exit.
3. **Mission smoke:** enter every mission and record a stable checkpoint/status.
4. **Representative completion:** Dam plus missions chosen for AI, objectives, effects, vehicles/exterior, and cutscenes.
5. **Timing:** compare important counters and behaviors at supported presentation rates.
6. **Renderer:** scene/image comparisons with tolerant masks and metric thresholds.
7. **Audio:** underrun/cadence counters and recorded event timing; do not commit game audio.
8. **Semantic mods:** registry/event/hook reference mods.
9. **No-mod parity:** disabled ModPlatform path versus enabled-empty profile.
10. **Save compatibility:** vanilla and mod-profile transition rules.
11. **Stress:** repeated mission restart, profile switch, suspend/resume, and long run.

Private results can publish aggregate pass/fail, hashes, timings, and non-copyrighted diagnostics—never captured copyrighted frames/audio unless access is controlled and policy permits.

## Deterministic input and replay

A replay records:

- game/import/runtime versions and hashes;
- initial save/checkpoint identity;
- mod profile and exact package hashes;
- per-simulation-frame logical controller state;
- clock configuration and random-seed observations where controllable;
- selected semantic trace events;
- periodic state fingerprints over allowlisted, normalized state.

It is a test instrument, not initially a player-facing deterministic netcode promise. Pointer addresses, padding, renderer buffers, and known nondeterministic values must not enter state fingerprints.

Assertions should prefer semantic checkpoints:

- mission entered;
- objective transitioned;
- guard count/category;
- weapon/ammo state;
- mission completed/failed;
- elapsed simulation ticks within tolerance.

## Visual testing

Golden-image testing is helpful but delicate because drivers differ.

Use:

- scene-specific captures at controlled camera/input points;
- perceptual comparison with documented thresholds;
- masks for nondeterministic UI/counters;
- renderer event/command counters alongside images;
- a small reference GPU/driver matrix;
- explicit human review for skybox, water, framebuffer, fog, depth, and aspect-ratio changes.

Store public test images only if independently authored. Game screenshots belong in private artifacts unless redistribution has been cleared.

## Performance testing

Collect:

- simulation frame duration distribution;
- renderer CPU/GPU frame time;
- Lua callback time by mod/event;
- allocations and memory high-water marks;
- audio underrun count;
- import and cold/warm launch time;
- thermal throttling and battery behavior on Android;
- package scan and resolver time at 0, 50, 500 packages.

Budgets live in Architecture. CI should fail only on stable, calibrated benchmarks; noisy device benchmarks report trends and gates through qualification.

## Android matrix

Minimum engineering matrix:

| Dimension | First spike | Beta qualification |
|---|---|---|
| ABI | arm64-v8a | arm64-v8a |
| GPU | one Adreno | Adreno plus Mali |
| OS | one current device | oldest supported plus current |
| Input | one controller | Xbox/PlayStation/generic plus touch |
| Lifecycle | pause/resume | repeated background, screen lock, process recreation |
| Storage | ROM picker | picker, revoke, low storage, reimport |
| Audio | normal play | focus loss, Bluetooth route, interruption |
| Thermal | 10-minute run | 30–60-minute representative run |

Android emulators are useful for manager UI and lifecycle automation but do not qualify renderer performance or controller latency.

## Desktop matrix

Initial beta intent:

- Windows x86-64 native;
- Linux x86-64 on a defined glibc baseline;
- WSL only as a developer convenience, not necessarily a supported runtime;
- macOS added only after its baseline and signing path are resourced.

Test debug/ASan/UBSan builds on Linux and platform-native release builds. Run ThreadSanitizer selectively if the runtime dependencies permit it.

## Security and robustness testing

- archive/parser fuzz corpus;
- manifest deep nesting/large strings/unicode/case/path edge cases;
- dependency graph size/cycle bombs;
- Lua memory and instruction/time abuse;
- capability denial and permission upgrade on update;
- native-mod warning and incompatible architecture;
- symlink/path traversal and Android URI permission revocation;
- corrupted saves/options and power-loss write points;
- malicious update/catalog metadata;
- diagnostic privacy scrub;
- crash-loop safe mode;
- package checksum/signature mismatch;
- rollback after every injected load phase failure.

Native mods are process-trusted; tests verify warning/compatibility mechanics, not false sandbox guarantees.

## Documentation tests

- every Lua snippet parses;
- every tutorial package validates and runs in the synthetic harness;
- generated Interface reference matches canonical schemas/bindings;
- all internal Markdown links resolve;
- commands are checked in clean containers where feasible;
- compatibility/version tables match runtime constants.

A documentation example that cannot be tested should explain why.

## CI lanes

### Pull request

- formatting/static analysis;
- C++ unit and contract tests;
- Lua tests;
- Python author-tool tests;
- schema/codegen drift;
- synthetic integration;
- package/security corpus;
- license/secret/game-data pattern scan;
- Markdown links;
- one primary desktop build.

### Nightly

- sanitizers and fuzz smoke;
- secondary compiler/platform builds;
- larger dependency/package corpus;
- performance trends;
- upstream compatibility probe;
- private ROM suite only on a deliberately configured private runner, with private artifacts.

### Release candidate

- clean-room build reproduction;
- full desktop matrix;
- physical Android matrix;
- representative mission/replay suite;
- no-mod parity;
- import interruption/recovery;
- manager/profile/update/safe mode;
- package/tool reproducibility;
- SBOM, notices, checksums, signing;
- manual visual/audio/controller checklist.

## Release-blocking failures

Always block release for:

- game data in a public artifact;
- unsupported ROM accepted as valid;
- import/cache corruption or unsafe path write;
- vanilla mission regression in the supported set;
- simulation acceleration tied to presentation rate;
- reproducible crash loop without safe recovery;
- mod sandbox/capability escape within the claimed Lua security model;
- dependency resolution nondeterminism;
- profile/save data loss;
- same Lua package behaving incompatibly across supported platforms without declared reason;
- missing required license/notice/provenance record;
- broken Android lifecycle or sustained rendering on a claimed supported device.

## Test implementation order

1. resolver/schema/journal/sandbox synthetic tests;
2. baseline boot/Dam private replay and issue ledger;
3. import state-machine and data scan;
4. timing/renderer representative private suite;
5. one semantic weapon registry no-mod/mod parity test;
6. Android lifecycle/input/renderer instrumentation;
7. manager/profile/package end-to-end;
8. documentation/tool reproducibility;
9. community format conversions;
10. beta matrix and security hardening.
