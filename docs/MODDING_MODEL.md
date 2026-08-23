# Modding model

## Design goal

The default modding experience should feel closer to Gen1Recomp than to reverse engineering:

```text
new project → edit Lua → run immediately → see attributed errors
→ validate → package one ZIP → install on desktop or Android
```

A mod author should not need to build the runtime, link C++, calculate RDRAM addresses, or redistribute a modified ROM. Native recomp mods remain available for experts, but they are not the teaching path.

## Package format

A `.gemod` is a reproducible ZIP with a fixed root layout:

```text
my-first-mod.gemod
├── manifest.json
├── main.lua
├── assets/
├── transforms/
├── locale/
├── schemas/
└── README.md
```

Only `manifest.json` is required for metadata and only the declared entry file executes. Paths are normalized, case collisions are rejected, archive bombs are bounded, and package contents are hashed. Packages may not contain ROMs or extracted game assets.

Example manifest:

```json
{
  "format": 1,
  "id": "example.harder-pp7",
  "name": "Harder PP7",
  "version": "0.1.0",
  "entry": "main.lua",
  "interface": ">=0.1 <0.2",
  "game_revisions": ["ge-us-1.0"],
  "description": "Raises PP7 damage and reports completed objectives.",
  "authors": ["Example Author"],
  "dependencies": {},
  "optional_dependencies": {},
  "conflicts": [],
  "priority": 0,
  "permissions": [],
  "options_schema": {
    "damage": {
      "type": "integer",
      "default": 30,
      "minimum": 1,
      "maximum": 100
    }
  }
}
```

The final schema should borrow proven Gen1Recomp concepts: ID, semantic version, entry, Interface range, priority, supported games/revisions, dependencies, optional dependencies, conflicts, description, project/update source, category, permissions, required/optional imports, options schema, and asset transforms. Fields are added only when the runtime implements their semantics.

## Entry Interface

The entry chunk returns one setup function:

```lua
return function(mod)
  local damage = mod.options:get("damage")

  mod.content.weapons:patch("pp7", {
    damage = damage
  })

  mod.events:on("objective.completed", function(event)
    mod.log:info(("Completed %s"):format(event.objective_id))
  end)
end
```

The `mod` object is the sole stable root. Candidate namespaces:

- `mod.content`: structural registries;
- `mod.events`: notifications;
- `mod.hooks`: behavior interception;
- `mod.game`: safe runtime operations and queries;
- `mod.save`: versioned mod data attached to a save;
- `mod.storage`: mod-private persistent storage;
- `mod.options`: validated player configuration;
- `mod.assets`: private transformations/substitutions;
- `mod.log`: attributed diagnostics;
- `mod.checkpoint`: session recovery where supported;
- `mod.info`: immutable identity and compatibility data.

Global variables and unrestricted standard libraries are not an Interface.

## Registries

Registries hold keyed definitions and use the same small vocabulary:

```lua
registry:register(id, definition)
registry:override(id, definition)
registry:patch(id, partial_definition)
registry:remove(id)
registry:get(id)
registry:each()
```

Each registry has a schema, merge policy, key rules, reference validation, and freeze point. A patch is not a blind table merge: fields declare replace, deep-merge, append, keyed-merge, or compose semantics.

Initial vertical-slice registries:

1. `weapons`: damage, rate/timing values, ammo relationship, flags, presentation references;
2. `mission_text`: briefing/objective text substitutions using semantic keys;
3. `objectives`: safe metadata and completion rules only after behavior parity is understood;
4. `spawns`: a constrained original-content spawn definition for a test arena or known mission hook.

Later candidates include character archetypes, AI lists, props, doors, cameras, multiplayer scenarios, weapon sets, cheats, music routes, and texture/material substitutions.

The content merge produces a provenance map. Diagnostics can answer: “which mod last changed PP7 damage, what was the previous value, and why did this conflict?”

## Events and hooks

Events are notifications and do not replace game behavior:

```lua
mod.events:on("mission.started", function(event) end)
mod.events:on("guard.defeated", function(event) end)
```

Hooks form an ordered middleware chain around behavior:

```lua
mod.hooks:around("combat.damage", function(next, context)
  if context.target:is_player() then
    context.amount = context.amount * 0.5
  end
  return next(context)
end)
```

Ordering is deterministic and visible: dependency order, explicit priority, stable mod ID tie-break, then registration order. Hooks must call `next` exactly according to their contract. The tool catches obvious omissions; the runtime catches double calls and invalid return types.

Every event/hook documents:

- phase and thread;
- payload schema and handle lifetime;
- whether callbacks may mutate data;
- ordering;
- reentrancy;
- error behavior;
- timing budget;
- version introduced.

A Lua callback error disables that callback or mod according to policy, records the full attributed trace, and preserves runtime integrity. It must not become an unexplained game crash.

## Load transaction and rollback

A mod entry chunk runs inside a journal. Registrations, callbacks, options, asset declarations, and handles are provisional until setup completes. On error:

1. remove the mod's provisional changes;
2. close its resources and Lua environment;
3. report the exact manifest/mod/file/line;
4. either continue without the optional mod or fail launch if dependency correctness requires it.

After all entries load, the ModPlatform merges registries, validates references, freezes structural content, and only then starts gameplay. This is critical to no-mod parity and useful conflict reporting.

## Dependency and conflict model

- Semantic versions use a documented subset consistently across runtime and tool.
- Required dependencies must resolve before load.
- Optional dependencies affect ordering only when installed and compatible.
- Conflicts are explicit and explain which declarations caused them.
- Cycles produce a readable chain.
- A profile records enabled mods and order; installed does not imply enabled.
- The manager offers a solution but never silently removes a user's package.
- Save data records the active mod set and warns on material mismatch.

A lock snapshot may record exact resolved versions for reproducible challenge runs without preventing normal upgrades.

## Sandbox and permissions

Default Lua libraries: base safe functions, table, string, math, utf8, and a constrained coroutine policy. Omit `io`, `os`, `package.loadlib`, raw debug access, and arbitrary FFI.

Permissions are capability grants, not decorative manifest text:

| Permission | Capability | Default index policy |
|---|---|---|
| none | content, events, hooks, options, scoped save/storage | allowed |
| `clipboard` | explicit copy/paste operations | review |
| `network` | constrained asynchronous HTTP | review and prompt |
| `native_code` | process-level compiled module | strong warning/manual review |
| `experimental_memory` | unstable research access | developer mode only |

The sandbox reduces accidents and opportunistic abuse; it is not a perfect security boundary against sophisticated hostile native code. Package signatures and a community index add provenance, not magical safety.

## Persistence

Four distinct stores prevent accidental coupling:

- **game save:** original GoldenEye progress and settings;
- **mod save:** versioned data logically attached to a game save;
- **mod storage:** installation-wide private data for one mod;
- **options:** schema-validated player configuration.

A mod supplies explicit migrations from prior schema versions. Writes are atomic. Unknown/invalid option values fall back with a diagnostic, not a crash. Profiles do not share data unless the Interface says so.

## Assets and copyrighted data

A public mod should contain original work or instructions that transform a user's private imported data. The asset pipeline can support:

- original replacement textures/audio/data;
- declarative transformations applied to named private source assets;
- binary deltas whose legal status and source identity are validated;
- semantic references into the private GameInstall.

It should reject an archive that resembles a ROM or exceeds declared asset constraints. The public index requires authors to affirm their rights and permits takedown/disable metadata.

## Native expert lane

Native mods use the pinned N64ModernRuntime/N64Recomp facilities for code patches, symbol hooks, and new compiled behavior. They declare `native_code`, exact ABI compatibility, architecture artifacts, and platform support.

A native package may expose a safe operation to Lua through a registered extension Interface. It must not replace the standard `mod` root or make all Lua packages native-dependent. Android requires arm64 code and stricter packaging; a desktop-only native mod is visibly incompatible rather than failing at load.

## Author tool

The `gemod` CLI should be installable independently of a full source checkout.

```sh
gemod new harder-pp7
cd harder-pp7
gemod run
gemod validate
gemod lint
gemod pack
```

Expected behavior:

- `new`: prompts minimally, creates manifest, entry, README, tests, and editor settings;
- `run`: locates the installed launcher, uses a development profile, streams attributed logs, and supports safe reload;
- `validate`: checks manifest, files, schemas, references, compatibility, permissions, and archive policy;
- `lint`: static Lua checks plus project-specific lifecycle mistakes;
- `pack`: deterministic ZIP, normalized timestamps/order, checksum, and content inventory;
- `docs`: opens or serves documentation matching the selected Interface version;
- `inspect`: explains package metadata, dependencies, permissions, hashes, and likely conflicts.

The runtime itself performs all security-critical validation. The CLI improves feedback but cannot be trusted as the enforcement point.

## Hot reload and developer console

Hot reload is a developer feature with explicit limits:

- reload the Lua environment and redo the mod transaction;
- preserve only declared reload-safe storage;
- refuse reload when a changed definition cannot safely replace live state;
- restore the prior working transaction on failure;
- show changed registrations and callbacks;
- never claim parity with a clean boot unless a clean-boot test passes.

The console exposes safe queries, logs, registry provenance, event tracing, and mod state. Arbitrary native memory writes remain behind a dangerous developer mode.

## Manager and player experience

The in-app manager should support:

- install from local `.gemod` ZIP and platform file picker/share intent;
- enable/disable and reorder through profiles;
- dependency/conflict explanations;
- permissions and compatibility before enable;
- per-mod options generated from schema;
- update check with explicit confirmation;
- logs and “copy diagnostic bundle” with private data scrubbed;
- safe mode after a crash;
- one-click disable of the last changed mod set;
- import/export of a profile without bundled game data.

Desktop and Android consume identical Lua packages. Native packages declare platform artifacts.

## Community index

Do not build the index before the package and compatibility model works locally. A first index can be a signed/static catalog with:

- ID ownership;
- versions and immutable checksums;
- download/source URLs;
- Interface/game/platform compatibility;
- permissions;
- moderation state and takedown;
- dependencies/conflicts;
- release notes.

Publishing should be GitHub-friendly: validate and pack locally, create a release, then submit/update index metadata through review automation. The launcher verifies package hash and surfaces source identity.

## Tutorial ladder

Documentation should ship in tested rungs:

1. change PP7 damage;
2. add an option;
3. listen to a mission event;
4. add a damage hook;
5. patch mission text;
6. add original replacement art;
7. save mod-specific progress;
8. depend on another mod;
9. diagnose a conflict;
10. build a profile and release;
11. create a test and replay assertion;
12. enter the native expert lane.

Every tutorial is a complete example package run in CI against a synthetic harness and, where needed, the private ROM suite.

## Mod-platform definition of done

- First Lua mod from scaffold to visible result in under 15 minutes.
- One package installs unchanged on desktop and Android.
- No raw memory address appears in beginner docs.
- Failed setup rolls back without corrupting the next launch.
- Conflicts identify fields and owning mods.
- Dependencies, permissions, options, persistence, and updates work through the manager.
- Disabling all mods restores tested vanilla behavior.
- Runtime and CLI accept/reject the same manifests.
- Documentation examples are executable tests.
- A public package contains no required copyrighted game data.
