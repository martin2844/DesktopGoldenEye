# Risk register

Scale: probability and impact are Low/Medium/High. “Trigger” is the observable sign that forces review.

| ID | Risk | P | I | Mitigation / experiment | Trigger |
|---|---|---:|---:|---|---|
| R1 | GoldenEye decomp/generated artifacts have unclear redistribution provenance | High | High | M0 file-by-file inventory; conservative local generation; qualified legal review before release | cannot classify a required public artifact |
| R2 | No qualified Android host exists for the selected runtime | High | Medium | defer until desktop alpha; later time-boxed renderer/lifecycle spike; do not couple PC Interfaces to Android assumptions | no representative frame/lifecycle proof within optional spike |
| R3 | MGB64 has later-mission correctness gaps despite passing Dam | Medium | High | run representative mission gate; keep upstream fidelity/issue census before freezing semantic hooks | persistent blockers in later missions |
| R4 | 60 fps presentation changes simulation behavior | High | High | separate clocks; weapon/AI/door/timer census; replay assertions at rates | state/event divergence by presentation rate |
| R5 | custom GoldenEye graphics behavior leaves skybox/water/effects wrong | Medium | Medium | use MGB64's capture/fidelity harnesses and upstream general renderer fixes | mission clarity or completion affected |
| R6 | direct ordinary-ROM flow regresses or leaks ROM data | Low | High | keep ROM outside Git; private smoke only; artifact scans; all byte orders tested | player needs a transformed image or release contains ROM bytes |
| R7 | a future Android renderer/host is too slow or fragile | Medium | High | benchmark only after desktop alpha; keep package/Lua Interfaces platform-neutral | first representative scene misses lifecycle or performance gate |
| R8 | semantic Lua Interface mirrors unstable internals | Medium | High | deep GoldenEyeModel, semantic IDs, handles, schemas, no raw memory; M6 modder review | ordinary update breaks many sample mods |
| R9 | broad Interface designed before game parity creates permanent mistakes | Medium | High | freeze only vertical slice after M3; mark experimental; compatibility tests | public tutorials depend on provisional behavior |
| R10 | Lua callbacks hurt frame time or destabilize threads | Medium | High | safe phases, budgets, profiling, no real-time audio callbacks, bounded event payloads | mod overhead exceeds frame budget |
| R11 | sandbox is marketed as stronger than it is | Medium | High | explicit threat model; remove unsafe libraries; permissions; native code warning; fuzz/security tests | untrusted package escapes claimed capability set |
| R12 | native mods fragment platform support | High | Medium | separate expert lane; declared ABI/architecture/platform; Lua remains common format | popular mod works only on one unmarked platform |
| R13 | dependency/conflict behavior becomes unpredictable | Medium | High | deterministic solver, provenance, lock snapshots, table/property tests | same profile resolves differently by machine/order |
| R14 | mod failure corrupts merged content or save data | Medium | High | transaction journal, atomic writes, migrations, safe mode, fault injection | failed load changes next clean launch |
| R15 | Android storage/lifecycle loses private import or saves | Medium | High | SAF, app-private atomic storage, process recreation and low-space tests | resume/revoke/upgrade produces data loss |
| R16 | Mali and Adreno behavior diverges | High | Medium | physical two-family beta matrix; validation; conservative feature level | one GPU family shows persistent renderer failure |
| R17 | WSL graphics issues are mistaken for product bugs | Medium | Medium | distinguish WSL developer environment; native Windows/Linux qualification | bug reproduces only under WSLg |
| R18 | existing ROM-hack community sees project as replacement/fragmentation | Medium | High | early outreach; format terminology map; private patch profiles; author-consented converters | community feedback rejects workflow or duplicates catalog |
| R19 | converted community content redistributes unauthorized data | Medium | High | provenance rules, original-author consent, private transformations, package scanner/takedown | converter output contains game assets/code |
| R20 | public index creates moderation/security burden | Medium | High | defer to M10; immutable hashes; review/signing; incident/takedown process | no maintainers own package review/incident response |
| R21 | upstream changes break long-lived fork | Medium | High | pin revisions; small patch ledger; upstream general fixes; scheduled upgrade/replay testing | patch count/gap grows beyond maintainable level |
| R22 | single-maintainer burnout | High | High | gated scope; docs/reproducible builds; narrow alpha; recruit co-maintainers before index/1.0 | only one person can build/release/debug |
| R23 | mod author tools drift from runtime validation | Medium | Medium | canonical schemas/generated bindings; runtime remains authority; CI drift tests | CLI accepts package runtime rejects |
| R24 | beginner workflow takes too long | Medium | High | timed novice tests, scaffold defaults, actionable errors, three reference mods | M6 first mod exceeds 15 minutes |
| R25 | build/release contains ROM fragments through generated objects/logs | Medium | High | artifact scanning, entropy/signature checks, clean runner, explicit generated-file classification | public scan finds known ROM sequences/assets |
| R26 | save/profile compatibility surprises players | Medium | High | record exact profile hashes; warn; backups/migrations; reference semantics | enable/disable causes irreversible progress loss |
| R27 | project name/branding creates trademark confusion | Medium | Medium | clearly unofficial codename/notice; avoid official logos/assets; revisit public name | public distribution/community launch |
| R28 | scope expands into online multiplayer or full editor too early | Medium | High | non-goals, milestone gates, request map; post-1.0 research only | core gate slips while unrelated feature grows |
| R29 | toolchain version churn breaks reproducibility | Medium | Medium | pin CMake/NDK/SDK/dependencies; wrappers/lockfiles; build metadata | clean build fails after host update |
| R30 | private test coverage cannot run in public CI | High | Medium | strong synthetic harness; private runner only for integration; aggregate evidence | parser/kernel defect only discoverable with ROM |

## Top five immediate risks

1. **R1 provenance:** determines whether a public binary/repository model is viable.
2. **R3 baseline breadth:** Dam passes, but later missions must qualify before semantic Interfaces freeze.
3. **R4 timing:** incorrect simulation would poison gameplay and mod contracts.
4. **R8 semantic stability:** brittle low-level Lua bindings would undermine the whole mod ecosystem.
5. **R22 sustainability:** the architecture and release process must remain pet-project sized.

Review these after every Phase 0/M1 experiment. Add evidence links and change probability rather than merely marking them “handled.”

## Risk review cadence

- At every milestone gate: review all High-impact risks.
- Every two weeks during active development: review triggers and new evidence.
- Before dependency upgrades: review R4, R8, R21, R23, R29.
- Before Android claims: review R2, R7, R15, R16.
- Before public packages/index: review R1, R11, R19, R20, R25, R27.
- After any incident: add a test and update the relevant decision/risk.
