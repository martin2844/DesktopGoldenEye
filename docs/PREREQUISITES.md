# Prerequisites and start checklist

## What you need before implementation

### Legally obtained game image

Start with a personal dump of the US GoldenEye 007 N64 cartridge. The initial accepted SHA-1 is:

```text
abe01e4aeb033b6c0836819f549c791b26cfde83
```

Verify without uploading the ROM:

```sh
sha1sum "/path/to/your/GoldenEye 007 (USA).z64"
```

On Windows PowerShell:

```powershell
Get-FileHash -Algorithm SHA1 "C:\Games\ROMs\GoldenEye 007 (USA).z64"
```

The importer should eventually accept z64, n64, and v64 byte orders, but Phase 0 may normalize to big-endian z64 first. Do not place the ROM inside this Git repository. Japanese and PAL versions are later compatibility profiles, not interchangeable inputs.

### When the ROM becomes necessary

The ROM is not needed to install compilers, build the launcher, audit provenance, or run the ROM-free mod-platform tests. It is needed for playable GoldenEye validation.

The selected MGB64 baseline consumes an ordinary `.z64`, `.v64`, or `.n64` image directly at runtime and normalizes byte order in memory. No GoldenRecomp-specific transformed ROM or matching ELF is required.

Keep the ROM outside this repository—for example in a private Windows ROM directory—and provide only its local path. Do not upload it, send it through chat, or copy it into an issue or CI artifact. From WSL, a Windows file such as `C:\Games\ROMs\GoldenEye 007 (USA).z64` is normally visible below `/mnt/c/Games/ROMs/`. We will store any configured path only in ignored local configuration.

### Development hardware

Minimum practical starting setup:

- x86-64 desktop with 16 GB RAM; 32 GB is comfortable for parallel C++ builds;
- Vulkan-capable GPU and current drivers;
- 20–30 GB free disk for upstream checkouts, symbols, native builds, and private imports;
- a Bluetooth or USB controller recognized by Windows and Linux.

Android hardware, SDK, NDK, JDK, and ADB are not required for the PC alpha. If the optional port begins later, test at least one Qualcomm/Adreno device and one ARM/Mali device before claiming broad support.

### Accounts and community access

No account is required to build locally. These become useful later:

- GitHub account for upstream issues, forks, CI, and releases;
- Discord/forum accounts for N64Recomp and GoldenEye modding communities;
- Android signing identity only when distributing test APKs beyond local debug builds;
- optional public package/index hosting after the mod format is stable.

Do not create organization, store, or signing commitments during Phase 0.

## Toolchain recommendation

### Shared native tools

- Git 2.34 or newer;
- CMake 3.24 or newer;
- Ninja 1.10 or newer;
- Clang/LLVM 17+ as the reproducible primary compiler;
- GCC 11+ as a secondary compatibility compiler on Linux;
- Python 3.11+ with a project virtual environment;
- Lua 5.4 for the embedded Interface and local experiments;
- pkg-config;
- SDL2 development files initially, unless the chosen upstream migration proves SDL3;
- Vulkan loader/headers, validation layers, shader compiler, and diagnostic tools;
- zlib and other libraries required by the pinned upstream build;
- Git LFS only if original large test fixtures are later introduced—never for ROM data.

### Optional Android tools—install later

Use a dedicated Android SDK location for WSL/Linux builds rather than mixing Windows and Linux tool paths.

Provisional baseline to confirm during the spike:

- JDK 17;
- Android Studio or command-line SDK manager;
- Android SDK Platform 35 or the currently supported stable platform selected at implementation time;
- Android Build Tools matching that platform;
- Android NDK r27c or a pinned supported NDK;
- CMake 3.28.x from the SDK or a pinned host CMake;
- Gradle wrapper committed by the project;
- ADB;
- Vulkan validation layers for debug devices where supported.

Exact SDK/NDK versions must be pinned after the first passing build. “Latest” is not a reproducible version.

## This computer: audit on 2026-08-23

Environment: Ubuntu 22.04 under WSL2 on a Windows host, x86-64, Ryzen 7 5700G.

| Tool | State |
|---|---|
| Git 2.34.1 | installed |
| Ninja 1.13.0 | installed |
| GCC/G++ 11.4.0 | installed |
| Python 3.13.2 | installed |
| Lua 5.4.7 | installed |
| LuaJIT 2.1 snapshot | installed |
| Node 22.13.1 | installed; optional |
| Native Windows CMake 4.4.2 via MSYS2 | installed |
| Clang/LLVM | missing |
| Java/JDK | missing |
| ADB | missing |
| Android SDK manager | missing |
| Android NDK | missing |
| Gradle | missing; project should use wrapper later |
| Native Windows SDL2 via MSYS2 | installed |
| Vulkan diagnostic tools | missing |

Python 3.13 is usable for many tools, but dependencies may lag it. Prefer a Python 3.11 or 3.12 project environment if the pinned tooling fails on 3.13.

### Windows host audit

Windows command interop works and Windows Git is installed at `C:\Program Files\Git\cmd\git.exe`. Visual Studio 2022 Build Tools and the C++ workload are installed. The working MGB64 build uses MSYS2 MinGW64 with GCC 16.2, CMake 4.4.2, Ninja, SDL2, Git, Python/Pillow, pkg-config, and zip. MSVC remains useful for research but is not required for the selected runtime.

Run the reproducible workflow from the repository root:

```sh
./scripts/dev-windows.sh all
```

## Suggested Ubuntu/WSL desktop bootstrap

Review package names for the configured Ubuntu repositories before running:

```sh
sudo apt update
sudo apt install \
  build-essential clang lld cmake ninja-build git pkg-config \
  python3 python3-venv python3-pip \
  libsdl2-dev libvulkan-dev vulkan-tools mesa-vulkan-drivers \
  glslang-tools spirv-tools libz-dev
```

Useful debug packages:

```sh
sudo apt install gdb lldb ccache valgrind
```

Then verify:

```sh
cmake --version
ninja --version
clang++ --version
vulkaninfo --summary
pkg-config --modversion sdl2
```

WSL graphics support depends on WSLg, Windows GPU drivers, and Vulkan translation support. If the native window/renderer behaves differently under WSL, build and test the Windows desktop Adapter natively rather than diagnosing WSL as though it were a release platform.

## Optional Android bootstrap

The least surprising route is Android Studio on the host for SDK/device management plus a deliberately configured Linux SDK in WSL for command-line builds. Avoid sharing binary NDK toolchains across operating systems.

High-level steps:

1. Install JDK 17.
2. Install Android Studio and enable the SDK Platform, Build Tools, NDK, CMake, Platform Tools, and command-line tools.
3. Enable Developer Options and USB debugging on the phone.
4. Confirm `adb devices` shows an authorized physical device.
5. Confirm the device's Vulkan feature level and GPU family.
6. Let the future project Gradle wrapper own Gradle; do not rely on a global Gradle.
7. Put local SDK paths in ignored `local.properties`, never committed absolute paths.

The first Android artifact should be a renderer/lifecycle probe, not the whole game.

## Upstream source checkouts needed

Implementation should use a bootstrap script or CMake dependency manifest, but the initial research set is:

- N64Recomp;
- N64ModernRuntime;
- RT64 and its required submodules;
- GoldenRecomp;
- GoldenEye decompilation for symbols and behavioral comparison;
- Gen1Recomp as a product/mod-tooling reference, not a code dependency.

Clone recursively where the upstream requires submodules and record exact revisions. Keep research checkouts outside the product source tree until the dependency layout is decided.

## Knowledge useful to start

You do not need to master all of this first. The project will touch:

- modern C++ ownership, build systems, and cross-platform debugging;
- MIPS/N64 memory, threads, graphics commands, timing, and ROM formats;
- Lua C API, sandboxing, schemas, and compatibility design;
- JNI/Kotlin and Android lifecycle/storage/audio/input;
- Vulkan/render host integration;
- package resolution and semantic versioning;
- reproducible builds and copyright-conscious asset pipelines.

The best learning order is CMake/C++ build → runnable desktop baseline → runtime tracing → one semantic Lua operation → Android host spike. Learning Android and mod platform design before a reproducible game baseline creates rework.

## First-start readiness checklist

- [ ] Personal ROM hash matches the supported US revision.
- [ ] ROM is stored outside Git and backed up privately.
- [ ] CMake, Clang, Ninja, SDL, and Vulkan tools are installed.
- [ ] A basic Vulkan program/window works in the chosen desktop environment.
- [ ] Upstream repositories and submodules clone successfully.
- [ ] Selected upstream revision builds from a clean directory.
- [ ] Controller and audio output work in that baseline.
- [ ] Optional, post-desktop: a physical Android arm64 Vulkan device and SDK/NDK toolchain are available.
- [ ] Phase 0 provenance owner and evidence log are established.
- [ ] No copyrighted game artifacts appear in `git status`.

## Time expectations

For one experienced developer working part-time, this is a multi-month project, not a weekend port. A realistic first decision window is 2–4 weeks for the Windows baseline and provenance evidence. The first genuinely friendly Windows/Linux modding alpha is more plausibly 4–8 months part-time, depending mainly on baseline correctness and Linux portability. A later Android renderer/lifecycle spike adds at least 2–4 weeks for a feasibility decision and substantially more for a supported product. Community-grade breadth and polish can take 9–18 months.

These are planning ranges, not delivery promises. The roadmap is gated so the project can stop or narrow scope before investing in the expensive layers.
