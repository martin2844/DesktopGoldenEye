# Contributing

Thanks for helping make DesktopGoldenEye easier and more reliable to use.

## Good first contributions

- Reproduce and document a launcher, input, audio, or graphics issue.
- Add ROM-free tests for PowerShell settings/package behavior.
- Improve accessibility, controller profiles, diagnostics, or documentation.
- Qualify a campaign mission and report the exact profile/GPU/Windows version.

## Development rules

1. Branch from `master` and keep each change focused.
2. Never commit ROMs, ROM fragments, extracted game assets, saves, private
   screenshots/captures, or proprietary SDK material.
3. Add a regression test when fixing launcher/package behavior.
4. Build the Release configuration and run the package integrity test.
5. Explain player-visible behavior and license/provenance changes in the PR.
6. Do not add a bundled binary until its exact source, version, license, and
   required notices are recorded in `THIRD_PARTY_NOTICES.md`.

## Mod API proposals

No public scripting API is frozen yet. Proposals should name the GoldenEye
concept being exposed, explain why raw memory offsets are insufficient, define
failure/compatibility behavior, and include a ROM-free test strategy. See
[Modding Model](docs/MODDING_MODEL.md).

## Verification

See [Building on Windows](docs/BUILDING_WINDOWS.md). Private ROM tests stay
local; CI and source contributions must remain game-data-free.
