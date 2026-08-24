# Third-party component inventory

This is the current engineering inventory, not legal advice. No GoldenEye ROM is included or fetched by this repository.

| Component | Role | Current source | Packaging position |
|---|---|---|---|
| 1964 0.8.5 / 1964GEPD | x86 emulator core | Source in this repository | GPL-2.0; fork source and modifications may be distributed with license/notices/source obligations satisfied |
| GLideN64 + GlideHQ | selected graphics stack | Checksum-pinned upstream binary bundle | Active dependency; retain upstream notices and complete exact-version/source inventory before an independent binary release |
| Mouse Injector 2.3 | selected mouse/WASD input | Checksum-pinned upstream binary bundle | Active dependency; upstream history identifies BSD licensing, but exact bundled source/binary correspondence must be recorded |
| AziAudio | selected audio plugin | Checksum-pinned upstream binary bundle | Active dependency; exact version, source, and notice must be recorded |
| Jabo Direct3D 6/8 | optional legacy graphics plugins | Checksum-pinned upstream binary bundle | Not selected by Q Branch. Noncommercial intent alone is not redistribution permission; do not independently rehost until permission/license provenance is documented |
| GoldenEye/GoldFinger/Perfect Dark texture caches | optional enhanced HUD/textures | Checksum-pinned upstream binary bundle | Credits declare CC BY-NC-ND 3.0. Redistribute only unmodified, noncommercially, with attribution; keep separable from the GPL core |
| MGB64 and bundled libraries | experimental mod runtime | `runtime/mgb64` subtree | Preserve subtree licenses and notices; see its `LICENSE` and `NOTICE.md` |

For now, Setup downloads the exact upstream 1964GEPD no-Discord-RPC release and verifies SHA-1 and SHA-256. This avoids silently substituting binaries and preserves the archive's original structure and credits while the publishable package is audited.

The playable default is `1964-qbranch.exe` + `GLideN64.dll` + `Mouse_Injector.dll` + `AziAudio.dll`. Jabo and other legacy plugins are not required for the quality profile and can later be offered as explicitly labeled compatibility options if their redistribution basis is recorded.
