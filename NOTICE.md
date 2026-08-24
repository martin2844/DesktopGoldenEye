# Notice and clean-room rules

This repository is intended to contain original project code, documentation, build definitions, and tests that do not embed copyrighted GoldenEye 007 data.

Contributors must not commit:

- ROMs, ROM fragments, extracted textures, audio, maps, scripts, dialogue, or other game assets;
- generated recompilation output if it embeds copyrighted game code or data and redistribution has not been cleared;
- leaked or proprietary console SDK material;
- unreleased Xbox 360/XBLA game files;
- signing keys, private test captures containing distributable game assets, or commercial tool binaries.

The intended user flow is that each player supplies their own legally obtained ROM. Import and transformation occur locally, and derived data remains private. Tests that need a ROM run only in a private local suite. Public CI uses synthetic or independently authored fixtures.

This repository is a fork of 1964GEPD and is distributed under GPL-2.0. The
project-authored launcher, scripts, documentation, and modifications are
distributed under the same repository license. Public packages carry a
file-level component inventory, active binary hashes, corresponding GPL source,
and the original optional texture-cache credits. This document is project
policy, not legal advice.

## Current third-party boundaries

- The root 1964 emulator source descends from Graslu's `1964GEPD` repository and the original 1964 0.8.5 GPL-2.0 codebase. Upstream copyright notices are retained.
- The release builder downloads and verifies the official 1964GEPD no-Discord-RPC bundle, then copies only its optimized core, GLideN64, AziAudio, Mouse Injector, required runtime/configuration files, and the GoldenEye HUD cache.
- The GPL plugin source received with the upstream binaries is included in every player package as `1964/source.tar.xz`. The repository contains the complete modified 1964 core source and build scripts.
- The GoldenEye HUD cache is redistributed unchanged and noncommercially under CC BY-NC-ND 3.0 with its original `credits.txt`. GoldFinger and Perfect Dark caches are excluded.
- Jabo binaries and every other unused legacy plugin are excluded from DesktopGoldenEye public releases. They can still be obtained from the original upstream archive.
- See `THIRD_PARTY_NOTICES.md` for the current component inventory and packaging policy.
