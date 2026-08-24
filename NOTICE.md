# Notice and clean-room rules

This repository is intended to contain original project code, documentation, build definitions, and tests that do not embed copyrighted GoldenEye 007 data.

Contributors must not commit:

- ROMs, ROM fragments, extracted textures, audio, maps, scripts, dialogue, or other game assets;
- generated recompilation output if it embeds copyrighted game code or data and redistribution has not been cleared;
- leaked or proprietary console SDK material;
- unreleased Xbox 360/XBLA game files;
- signing keys, private test captures containing distributable game assets, or commercial tool binaries.

The intended user flow is that each player supplies their own legally obtained ROM. Import and transformation occur locally, and derived data remains private. Tests that need a ROM run only in a private local suite. Public CI uses synthetic or independently authored fixtures.

This repository is a fork of 1964GEPD and is distributed under GPL-2.0. The project-authored launcher, scripts, documentation, and modifications are distributed under the same repository license. A public binary package still requires a file-level inventory of every bundled plugin and asset. This document is project policy, not legal advice.

## Current third-party boundaries

- `runtime/mgb64/` is a squashed import of MGB64 revision `0d1d40b4`; its upstream license and notices remain inside that subtree.
- The root 1964 emulator source descends from Graslu's `1964GEPD` repository and the original 1964 0.8.5 GPL-2.0 codebase. Upstream copyright notices are retained.
- Windows development builds dynamically link SDL2 and Lua and statically link the pinned wgpu-native archive plus launcher libraries. The portable packager discovers runtime DLLs from the pinned environment and includes the locally available Lua, SDL2, ImGui, Native File Dialog, glad, font, and controller-database notices. The broader public provenance audit remains responsible for confirming the complete notice set, including wgpu-native.
- The launcher downloads the checksum-pinned upstream 1964GEPD binary bundle. The selected play stack uses the Q Branch GPL core, GLideN64, AziAudio, and Mouse Injector. The same upstream archive also contains optional legacy plugins, including Jabo, and CC BY-NC-ND texture caches. Those files are not committed to this repository.
- Noncommercial distribution does not replace license permission. The CC cache may be redistributed only unmodified, noncommercially, with attribution; the Jabo binaries need a documented redistribution basis before this project independently republishes them. Until that audit is complete, they remain obtained from the upstream release rather than rehosted here.
- See `THIRD_PARTY_NOTICES.md` for the current component inventory and packaging policy.
