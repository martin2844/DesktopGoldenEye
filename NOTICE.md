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
