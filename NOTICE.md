# Notice and clean-room rules

This repository is intended to contain original project code, documentation, build definitions, and tests that do not embed copyrighted GoldenEye 007 data.

Contributors must not commit:

- ROMs, ROM fragments, extracted textures, audio, maps, scripts, dialogue, or other game assets;
- generated recompilation output if it embeds copyrighted game code or data and redistribution has not been cleared;
- leaked or proprietary console SDK material;
- unreleased Xbox 360/XBLA game files;
- signing keys, private test captures containing distributable game assets, or commercial tool binaries.

The intended user flow is that each player supplies their own legally obtained ROM. Import and transformation occur locally, and derived data remains private. Tests that need a ROM run only in a private local suite. Public CI uses synthetic or independently authored fixtures.

The Phase 0 provenance review must classify each upstream file and generated artifact before any public binary release. This document is project policy, not legal advice.

## Current third-party boundaries

- `runtime/mgb64/` is a squashed import of MGB64 revision `0d1d40b4`; its upstream license and notices remain inside that subtree.
- Windows development builds dynamically link SDL2 and Lua and statically link the pinned wgpu-native archive plus launcher libraries. The portable packager discovers runtime DLLs from the pinned environment and includes the locally available Lua, SDL2, ImGui, Native File Dialog, glad, font, and controller-database notices. The broader public provenance audit remains responsible for confirming the complete notice set, including wgpu-native.
- A successful local asset-free build is not itself a completed provenance review. Public distribution remains gated on the file-level audit recorded in the roadmap and risk register.
