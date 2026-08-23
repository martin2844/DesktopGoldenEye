# Decision log

Statuses:

- **Accepted:** safe to plan and implement now.
- **Provisional:** preferred direction, but a named gate must confirm it.
- **Pending:** material choice deliberately deferred.
- **Rejected:** considered and not used for the stated scope.

Each decision that changes should preserve the old entry, add a superseding entry, and explain new evidence.

## D-001 — Product languages

**Status:** Accepted  
**Decision:** C++20 for shared host/runtime; Lua 5.4 for default mods; Kotlin for the thin Android Adapter; Python for author tooling and generators.

**Why:** This matches the upstream ecosystem and platform constraints while reproducing Gen1Recomp's short Lua author loop. Rust would add a foreign-language Seam around C++-heavy upstreams without enough early benefit. JavaScript is not suitable for the native runtime. C alone would discard useful C++ upstream integration.

**Consequence:** Public Lua bindings and C++ ownership need strong tests. Kotlin must not accumulate gameplay logic.

## D-002 — Primary runtime line

**Status:** Provisional, confirm at M0/M1  
**Decision:** base experiments on N64Recomp/N64ModernRuntime and GoldenRecomp-specific work.

**Why:** It offers the strongest existing native-mod substrate and aligns with recompilation-based deployment.

**Gate:** reproducible mission-capable desktop build, ordinary-ROM import path, and acceptable provenance.

**Fallback:** reassess a decomp-based port or desktop-only baseline using the M0 scorecard.

## D-003 — Reuse native mod machinery

**Status:** Accepted in principle; exact integration provisional  
**Decision:** reuse N64ModernRuntime manifests/dependency/code-mod/event/hook capabilities wherever they fit, rather than rewriting low-level native mod loading.

**Why:** The project should invest in GoldenEye semantic Leverage and author experience.

**Consequence:** The ModPlatform must Adapter-map native behavior into one coherent player catalog without leaking native complexity into Lua.

## D-004 — Lua as default author lane

**Status:** Accepted  
**Decision:** standard Lua 5.4, isolated per mod, rooted at `mod`, with schemas, registries, events, hooks, permissions, and scoped persistence.

**Why:** Small language, proven embedding, cross-platform, hot reload, and close to the fun Gen1Recomp workflow.

**Rejected alternative:** making C/C++ recomp patches the beginner path.

## D-005 — No raw memory in stable Lua Interface

**Status:** Accepted  
**Decision:** stable Lua operations use GoldenEye semantic IDs, schemas, values, and generation-checked handles.

**Why:** Raw addresses are brittle across revisions, timing fixes, recomp layout, and platform builds; they have low Depth and poor Locality.

**Exception:** developer-only experimental permission or native lane, explicitly unstable.

## D-006 — Direct ordinary-ROM player flow

**Status:** Accepted as product requirement; implementation provisional  
**Decision:** player selects an ordinary supported ROM. GameImage performs any normalization/transformation locally and stores a private versioned install without copying the source ROM.

**Gate:** Phase 0 establishes which generated artifacts may be cached/distributed.

## D-007 — Android follows the desktop alpha

**Status:** Accepted  
**Decision:** ship and stabilize the PC baseline, semantic mod slice, manager, and author loop before scheduling an Android renderer/lifecycle spike.

**Why:** Android is a nice-to-have, while RT64 and runtime Android host work remain incomplete. It must not delay a useful PC port.

**Future gate:** a time-boxed physical-device Vulkan/lifecycle spike after the desktop alpha. Failure leaves Android deferred without changing the PC roadmap.

## D-008 — Desktop renderer

**Status:** Provisional  
**Decision:** use RT64 for desktop through the selected runtime host.

**Gate:** renderer correctness on representative GoldenEye custom commands and supported desktop platforms.

**Android decision:** pending; do not assume the same host code works unchanged.

## D-009 — Package format

**Status:** Provisional until M5/M7  
**Decision:** deterministic ZIP named `.gemod`, containing `manifest.json`, Lua, original assets/transforms, docs, and optional declared native artifacts.

**Why:** easy install/share/inspect and platform-neutral Lua payload.

**Gate:** archive threat tests, cross-platform path semantics, reproducible output, and community review.

## D-010 — Registry lifecycle

**Status:** Accepted  
**Decision:** entry chunks register into a transaction; content merges and validates; structural registries freeze before gameplay. Events/hooks/runtime operations remain available under documented lifecycle rules.

**Why:** deterministic conflicts, rollback, diagnostics, and no-mod parity.

## D-011 — Existing ROM patches

**Status:** Accepted direction, later milestone  
**Decision:** BPS/xdelta/IPS patches create separate private GameInstall profiles from the user's ROM. They are not represented as portable Lua mods.

**Why:** their compatibility and rights model differs, and they may rewrite arbitrary code/data.

## D-012 — Public index

**Status:** Pending until local packages stabilize  
**Decision under consideration:** a signed/static metadata catalog with immutable package hashes and GitHub-hosted releases.

**Gate:** M7 proves local package, permissions, version, conflict, and recovery semantics.

## D-013 — Project-code license

**Status:** Pending  
**Decision:** do not choose a repository license until the M0 upstream/provenance review identifies which original code will live here and how linked/derived dependencies constrain distribution.

**Consequence:** planning documents are visible locally, but no assumption of reuse rights is granted by an absent license.

## D-014 — First supported platforms

**Status:** Provisional  
**Decision:** Windows x86-64 first, then Linux x86-64; Android arm64 and macOS are later optional targets.

**Why:** GoldenRecomp's documented path currently provides Windows-only recomp binaries and a Visual Studio build. Reproduce that shortest path first, then remove Windows assumptions and qualify Linux. WSL remains useful for tooling and repository work, not the initial graphics qualification target.

## Open decisions and required evidence

| Decision | Evidence needed | Latest responsible milestone |
|---|---|---:|
| static AOT versus live/local recomp artifacts | performance, package size, provenance, startup, platform support | M1/M2 |
| exact N64ModernRuntime integration shape | spike of Lua custom content type and lifecycle | M5 |
| Android renderer approach | post-desktop physical Vulkan spike and patch estimate | optional M4 |
| Lua state model per mod versus shared state/environments | isolation, memory, callback overhead measurements | M5 |
| canonical schema format | C++/Python/Lua codegen prototype | M5 |
| UI toolkit | Windows/Linux host fit and controller proof | M7 |
| package signing/index trust | threat model and operational owner | M10 |
| native extension ABI promise | real expert mods and upgrade cost | after beta |
| Japanese/PAL ROM support | symbol/data differences and community demand | after M6 |
| online multiplayer | deterministic runtime/netcode scope | post-1.0 research |

## D-015 — MGB64 is the desktop baseline

**Status:** Accepted; supersedes D-002, D-003, and D-008 for the primary implementation line
**Decision:** pin MGB64 at `0d1d40b4` as an editable squashed subtree and build the mod platform into its existing in-process launcher and C engine Seams.

**Evidence:** the documented GoldenRecomp dependency cannot be fetched; MGB64 built with MinGW64, validated the ordinary supported US `.n64` ROM, and rendered Dam through WebGPU on Windows.

**Consequence:** N64Recomp native-mod machinery is no longer assumed. Dependency resolution, Lua isolation, transactions, and semantic hooks will be implemented as focused Modules over MGB64. RT64 is not the selected renderer.

## D-016 — Match the baseline's implementation languages

**Status:** Accepted; narrows D-001
**Decision:** preserve MGB64's portable C engine and C++17 shell. Use C++17 for the first ModPlatform host, Lua 5.4 for authored mods, and Python only where author tooling benefits from it.

**Why:** forcing C++20 or rewriting working C creates no product Leverage. A future isolated Module may raise its own language level when a dependency requires it.

## D-017 — Directory manifests before executable mods

**Status:** Accepted for the first vertical slice
**Decision:** discover unpacked development packages with a strict top-level `manifest.toml` v1 subset before embedding Lua or finalizing `.gemod` archives.

**Why:** catalog discovery, validation errors, identity, and path safety are independently testable without executing untrusted code. D-009's deterministic `.gemod` archive remains a later packaging decision.

## D-018 — Mod execution is a named safety gate

**Status:** Accepted
**Decision:** the launcher may list packages now, but it must state that scripts are not executed until Lua isolation, library removal, host API allowlisting, failure rollback, and no-mod parity tests land together.

**Why:** silently executing a discovered `main.lua` would turn a useful catalog feature into arbitrary native-user process access.

**Evidence:** the gate now passes with isolated 8 MiB states, a 250 ms setup hook, unsafe standard libraries removed, explicit launcher enable state, one allowlisted semantic operation, and rollback tests for runaway/missing packages and host-state restoration.
