# Gated roadmap

Every milestone has an exit gate. A milestone is not complete because code exists; its evidence must pass from a clean environment.

## M0 — Feasibility, provenance, and upstream freeze

**Status:** technically complete for local development. The 1964GEPD fork and GPL core build are reproducible; public redistribution of the aggregate plugin/asset bundle remains open.

**Purpose:** establish whether the desired public project is technically and legally plausible.

**Work:**

- inventory N64Recomp, N64ModernRuntime, RT64, GoldenRecomp, decompilation, tools, generated artifacts, submodules, and licenses;
- record exact revisions and build instructions;
- trace how the ordinary ROM becomes runtime input;
- classify which generated files contain game code/data;
- evaluate baseline candidates with the scorecard;
- install and verify the desktop toolchain;
- write patch-ledger and evidence templates.

**Exit gate:**

- chosen provisional baseline and fallback are documented;
- build inputs and transformations are understood;
- no known prohibited data is required in public Git;
- redistribution questions have a conservative implementation path;
- all dependencies have an initial provenance status;
- supported US ROM fingerprint is recorded.

**Stop condition:** public asset-free distribution appears impossible or depends on unreleased Xbox material.

## M1 — Reproducible desktop vanilla baseline

**Status:** two Windows proofs exist: the editable MGB64 build and the source-built 1964GEPD Q Branch Quality Adapter. The exact ROM boots through both. The Q Branch core builds with VS2022 and launches through the real launcher; a human Dam completion, later missions, and second-machine quality setup remain before the full gate is closed.

**Purpose:** prove there is a game worth wrapping.

**Work:**

- clean scripted build from pinned sources;
- controller, audio, save, window/fullscreen, logs, clean exit;
- title screen, Dam completion, and one later representative mission;
- initial mission/renderer/timing issue ledger;
- debug symbols and crash capture;
- record baseline performance.

**Exit gate:**

- a second clean directory or machine reproduces the build;
- representative missions are playable without manual memory patches;
- normal developer workflow does not require proprietary SDK tools;
- known failures are classified as blocking/non-blocking;
- no mod code is needed for vanilla play.

## M2 — Asset-free launcher and direct ROM import

**Status:** implemented for the first supported US ROM in both active Adapters. Q Branch accepts quoted paths and uses a verified byte-order-correct hard-link only when the filename extension is misleading; MGB64 consumes the selected ROM directly. Neither copies ROM data into Git or a release.

**Purpose:** achieve the Gen1Recomp first-run model.

**Work:**

- GameImage Module;
- file picker/CLI import;
- byte-order normalization and SHA-1 validation;
- deterministic private transformations;
- versioned atomic cache;
- cancel/interruption/reimport/remove flows;
- build/source/tool metadata;
- privacy-safe error messages.

**Exit gate:**

- ordinary supported ROM imports on a clean machine;
- moving/removing the source ROM does not break later launch;
- interrupted import cannot leave a launchable corrupt install;
- repository/release scan finds no game data;
- wrong revision and corrupt input receive actionable errors.

## M3 — Runtime correctness and presentation

**Status:** reopened after human testing rejected MGB64 mouse feel and rendering. 1964GEPD + GLideN64 is now the quality candidate; automated boot/render evidence passes, while human input/audio/mission qualification remains.

**Purpose:** prevent game defects from becoming mod semantics.

**Work:**

- simulation/presentation clock separation;
- weapon, door, guard, cutscene, animation, and mission timer census at target frame rates;
- custom graphics commands, skybox, water, framebuffer effects;
- audio pacing and save reliability;
- modern dual-analog/control mapping;
- scripted replay/trace capture across missions;
- multiplayer menus/local baseline classification.
- compare quality evidence against MGB64 and keep the latter experimental until it passes the same human gate;

**Exit gate:**

- all single-player missions reach a recorded status; release blockers are explicit;
- Dam and selected stress missions complete at supported presentation rates without accelerated simulation;
- renderer blockers for the alpha are fixed or transparently scoped;
- no-mod replay/state assertions are stable enough to guard future hooks;
- controller presets are usable.

## Optional M4 — Android feasibility after desktop alpha

**Purpose:** investigate the Android nice-to-have without blocking the PC critical path. Do not schedule this milestone until M1–M3 and the desktop portions of M5–M8 produce a useful alpha.

**Work:**

- arm64 Gradle/NDK/JNI build;
- Vulkan surface and renderer host spike;
- Storage Access Framework ROM import;
- controller/touch events and optional touch overlay prototype;
- low-latency audio/audio focus;
- pause/resume/background/process recreation;
- safe private storage and package import;
- thermal/performance measurements on Adreno and Mali.

**Exit gate:**

- physical device renders a representative scene;
- suspend/resume and audio focus survive repeated cycles;
- controller input and private ROM import work;
- sustained performance has an honest supported profile;
- renderer approach and maintenance cost are accepted.

**Fallback gate:** keep Android deferred. M5 and later PC milestones never depend on this gate.

## M5 — Mod platform kernel

**Status:** started early after the baseline proof. Directory scan, strict manifest validation, persisted enable state, isolated/bounded Lua setup, transactional rollback, and one semantic operation are implemented. Dependency resolution, broader permissions, registries, runtime callbacks, and scoped persistence remain.

**Purpose:** build safe mechanics before game breadth.

**Work:**

- manifest/package schema;
- scan, validate, dependency/conflict resolver, stable order;
- isolated Lua environments;
- permissions;
- load journal/rollback;
- schema registry and merge/provenance engine;
- event/hook engine and callback containment;
- scoped options/save/storage;
- native expert-lane content type;
- ROM-free synthetic harness.

**Exit gate:**

- solver and package corpus pass;
- malformed and hostile archives are rejected within resource limits;
- failed setup leaves zero partial registrations;
- callback faults are attributed and contained;
- persistence cannot cross mod namespaces;
- CLI/runtime validation semantics agree;
- all kernel CI is ROM-free.

## M6 — GoldenEye semantic vertical slice

**Purpose:** prove the friendly author promise inside the real game.

**Work:**

- semantic identifier map;
- weapon registry and `weapons:patch`;
- mission text/objective metadata slice;
- safe controlled spawn/query;
- mission/objective/guard/weapon events;
- one combat or weapon middleware hook;
- generation-checked entity handles;
- three reference mods;
- no-mod parity and overhead measurements.

**Exit gate:**

- scaffold-to-visible-change under 15 minutes;
- no beginner tutorial uses a raw address;
- three reference mods demonstrate registry, event, hook, option, and persistence;
- disabling the profile restores tested vanilla behavior;
- callback overhead meets budget;
- Interface/lifecycle docs match executable tests;
- feedback from at least three prospective modders is recorded.

## M7 — Windows/Linux player mod experience

**Purpose:** turn mod mechanics into a usable product.

**Work:**

- local `.gemod` import via Windows and Linux desktop pickers;
- catalog, enable/disable, order, profiles;
- generated options UI and permissions;
- dependency/conflict remediation;
- safe mode and last-profile recovery;
- profile export/import without game data;
- update metadata/checks;
- privacy-scrubbed diagnostics.

**Exit gate:**

- one exact Lua package checksum works on Windows and Linux;
- broken profile recovery does not require deleting app data;
- dependency and conflict UI explains causes;
- profile/save mismatch is visible;
- manager works by mouse/keyboard and controller for core operations;
- update never silently installs or expands permissions.

## M8 — Author toolchain, hot reload, and documentation

**Purpose:** make modding inviting and repeatable.

**Work:**

- `gemod new/run/validate/lint/pack/docs/inspect`;
- deterministic ZIP;
- editor type hints/stubs;
- transactional reload;
- developer console, event trace, registry provenance;
- generated Interface reference;
- tutorial ladder and cookbook;
- CI templates and GitHub release workflow.

**Exit gate:**

- all tutorials execute automatically;
- pack output is byte-identical across repeated runs;
- runtime and CLI schema drift test passes;
- failed reload restores previous working state;
- a fresh tester completes first tutorial without live help;
- diagnostics name mod/file/line and corrective action.

## M9 — Existing-community bridge

**Purpose:** connect rather than fragment GoldenEye modding.

**Work:**

- document Setup Editor/N64 Vault formats and rights assumptions;
- conversion prototypes for independently authored semantic exports;
- private ROM-patch game-build profiles for BPS/xdelta/IPS;
- compatibility/hash reporting;
- native mod SDK examples;
- migration guides and terminology mapping;
- community review sessions.

**Exit gate:**

- at least one permitted community-authored project converts with author consent;
- raw patch import cannot masquerade as a portable Lua mod;
- private patched installs have distinct identity and compatibility warnings;
- no conversion output bundles unauthorized assets;
- community maintainers confirm docs are useful and respectful.

## M10 — Public beta and community operations

**Purpose:** release responsibly and sustain the project.

**Work:**

- signed/checksummed Windows and Linux artifacts; Android artifacts only if optional M4 has passed;
- static/signed mod index and immutable package hashes;
- moderation, ID ownership, takedown, and compromised-package process;
- crash/update privacy policy;
- SBOM, notices, reproducible release metadata;
- compatibility/version support policy;
- support templates, contribution docs, governance;
- performance/device/replay release qualification.

**Exit gate:**

- provenance review approves intended artifacts;
- clean-machine player and author journeys pass;
- supported platform/device matrix is published;
- recovery/update/index threat scenarios are tested;
- package catalog has a small high-quality seed set;
- at least two maintainers can perform a release;
- beta limitations and data practices are explicit.

## Beyond beta

Possible later work, driven by evidence:

- broader AI/mission authoring Interface;
- multiplayer semantic model and scenarios;
- accessibility presets and mod categories;
- richer asset transforms and texture tooling;
- deterministic challenge/replay sharing;
- localization and translated tutorials;
- macOS and additional desktop architectures;
- native extension ABI stabilization;
- alternative renderer only if a proven second Adapter warrants the Seam.
