# Third-party notices

DesktopGoldenEye is an unofficial GPL-2.0 fork and aggregate distribution. No
GoldenEye ROM or extracted game content is included or downloaded.

## Components in the public Windows package

| Component | Role | License / credit | Corresponding source |
|---|---|---|---|
| [1964 0.8.5](https://sourceforge.net/projects/schibo/files/1964%200.8.5/) and [1964GEPD](https://github.com/Graslu/1964GEPD) | Emulator core and GoldenEye/Perfect Dark fixes | GPL-2.0; 1964 copyright 1999–2002 Joel Middendorf; fork work by Graslu and contributors | Exact corresponding upstream source in release `1964/source.tar.xz`; DesktopGoldenEye fork changes in this repository |
| [GLideN64](https://github.com/gonetz/GLideN64) | Active graphics plugin | GPL-2.0; Sergey Lipskiy and contributors; its bundled license credits glN64, gles2n64, Glide64, z64, and GLideHQ contributors | `1964/source.tar.xz`, directories beginning `GLideN64-` |
| Mouse Injector | Active mouse/WASD input plugin | GPL-2.0; Carnivorous Society / Mouse Injector contributors | `1964/source.tar.xz`, directory `MouseInjectorPlugin` |
| [AziAudio](https://github.com/Azimer/AziAudio) | Active audio plugin | GPL-2.0; Azimer and contributors | `1964/source.tar.xz`, directory `AziAudioSrc0551` |
| zlib | Compression library used by the core | zlib License; Jean-loup Gailly and Mark Adler | Root `zlib/` source and `1964/source.tar.xz` |
| Microsoft Visual C++ 2010 Runtime | Runtime required by the bundled AziAudio binary | Microsoft redistributable runtime terms | `1964/msvcr100.dll`; source is not part of this project |
| Project64 unofficial RDB v4.23 | GoldenEye ROM configuration database | Credited in-file to Nekokabu, MASA, Smiff, and the Project64 team | `1964/Project64.rdb` |

The exact upstream aggregate archive is the official 1964GEPD
`1964 GEPD Edition (No DRP)` release dated 2023-07-03. The package builder pins
it by SHA-1 `D7C7099A41E8AE3427EAE22D8F95796D9DFC44A8` and SHA-256
`DAD8CE4CBDDDCB8447CE59BF194AD0ACF4C237A45A566CFFF7D3A1310CCE6F6E`.
Every DesktopGoldenEye release also records hashes of its active executables in
`release-manifest.json`.

## Optional GoldenEye HUD texture cache

The public package includes these upstream cache files unchanged:

- `GOLDENEYE_HIRESTEXTURES.dat`
- `GOLDENEYE_HIRESTEXTURES.htc`
- `credits.txt`

Original credits, preserved verbatim in `credits.txt`:

- GoldenEye/GoldFinger texture pack by Carnivorous
- GoldenEye ammo icons by Flargy, used with permission

The upstream credits designate this work
[Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Unported](https://creativecommons.org/licenses/by-nc-nd/3.0/).
DesktopGoldenEye distributes the cache unmodified and noncommercially. Disable
**Enhanced HUD textures** in the launcher if you do not want to use it.

## Deliberately excluded from public packages

The upstream aggregate also contains Jabo Direct3D, older GLideN64/Glide64
builds, controller plugins, test plugins, Perfect Dark/GoldFinger caches, and
legacy runtime DLLs. DesktopGoldenEye does not use or redistribute those files.
They remain available from the checksum-pinned upstream release for users who
need to investigate legacy compatibility.

The full GPL-2.0 text is in [LICENSE](LICENSE). This inventory is intended to be
specific and auditable, but it is not legal advice.
