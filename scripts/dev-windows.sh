#!/usr/bin/env bash
# Build and validate the native Windows port from WSL without copying ROM data.
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -f "$repo_root/.env" ]]; then
  set -a
  # Local-only paths and hashes; .env is ignored by Git.
  source "$repo_root/.env"
  set +a
fi

stage="${GEMP_WINDOWS_STAGE:-/mnt/c/Users/${USER}/Source/goldeneye-mod-platform/mgb64}"
msys_root="${MSYS2_ROOT:-/mnt/c/msys64}"
action="${1:-build}"
version="${GEMP_VERSION:-dev}"

if [[ ! -x "$msys_root/usr/bin/bash.exe" ]]; then
  echo "MSYS2 was not found at $msys_root. Set MSYS2_ROOT in .env." >&2
  exit 1
fi
if [[ "$stage" != /mnt/c/* ]]; then
  echo "GEMP_WINDOWS_STAGE must be on /mnt/c so native Windows tools can build it." >&2
  exit 1
fi

stage_win="$(wslpath -m "$stage")"

sync_sources() {
  mkdir -p "$stage" "$stage/examples/mods"
  rsync -a --exclude build/ --exclude .git/ "$repo_root/runtime/mgb64/" "$stage/"
  rsync -a "$repo_root/examples/mods/" "$stage/examples/mods/"
}

run_msys() {
  env WSLENV="${WSLENV:+$WSLENV:}GEMP_STAGE_WIN" \
    MSYSTEM=MINGW64 CHERE_INVOKING=1 GEMP_STAGE_WIN="$stage_win" \
    "$msys_root/usr/bin/bash.exe" -lc "$1"
}

build() {
  sync_sources
  run_msys 'PATH=/mingw64/bin:/usr/bin /mingw64/bin/cmake.exe -S "$GEMP_STAGE_WIN" -B "$GEMP_STAGE_WIN/build" -G Ninja -DCMAKE_BUILD_TYPE=Release'
  run_msys 'PATH=/mingw64/bin:/usr/bin /mingw64/bin/cmake.exe --build "$GEMP_STAGE_WIN/build" --target ge007 test_mod_catalog test_mod_runtime -j 8'
  cp "$msys_root/mingw64/bin/SDL2.dll" "$stage/build/SDL2.dll"
  echo "Windows launcher: $stage/build/ge007.exe"
}

test_mods() {
  run_msys 'PATH=/mingw64/bin:/usr/bin "$GEMP_STAGE_WIN/build/test_mod_catalog.exe"'
  run_msys 'PATH=/mingw64/bin:/usr/bin "$GEMP_STAGE_WIN/build/test_mod_runtime.exe"'
}

smoke_launcher() {
  run_msys 'PATH=/mingw64/bin:/usr/bin MGB64_APP_PANEL=mods MGB64_MODS_DIR="$GEMP_STAGE_WIN/examples/mods" MGB64_APP_SMOKE_FRAMES=60 MGB64_APP_SMOKE_SHOT="$GEMP_STAGE_WIN/build/mods-panel.bmp" "$GEMP_STAGE_WIN/build/ge007.exe"'
  echo "Launcher capture: $stage/build/mods-panel.bmp"
}

smoke_game() {
  if [[ -z "${GOLDENEYE_ROM_PATH:-}" || ! -f "$GOLDENEYE_ROM_PATH" ]]; then
    echo "Skipping private ROM smoke: set GOLDENEYE_ROM_PATH in .env." >&2
    return 0
  fi
  local rom_win
  rom_win="$(wslpath -m "$GOLDENEYE_ROM_PATH")"
  env WSLENV="${WSLENV:+$WSLENV:}GEMP_STAGE_WIN:GEMP_ROM_WIN" \
    MSYSTEM=MINGW64 CHERE_INVOKING=1 GEMP_STAGE_WIN="$stage_win" GEMP_ROM_WIN="$rom_win" \
    "$msys_root/usr/bin/bash.exe" -lc 'cd "$GEMP_STAGE_WIN/build"
PATH=/mingw64/bin:/usr/bin SDL_AUDIODRIVER=dummy GE007_MUTE=1 GE007_NO_VSYNC=1 GE007_NO_INPUT_GRAB=1 MGB64_APP_AUTOPLAY=1 MGB64_APP_AUTOPLAY_LEVEL=dam MGB64_ROM="$GEMP_ROM_WIN" MGB64_APP_SAVEDIR=./smoke-save MGB64_MODS_ENABLE_ALL=1 MGB64_MODS_DIR="$GEMP_STAGE_WIN/examples/mods" MGB64_BOOT_SCREENSHOT_FRAME=180 ./ge007.exe'
  echo "Game capture: $stage/build/screenshot_000.bmp"
}

package() {
  run_msys 'cd "$GEMP_STAGE_WIN"
PATH=/mingw64/bin:/usr/bin ./scripts/package_windows_zip.sh --binary build/ge007.exe --version '"$version"
  echo "Portable zip: $stage/dist/mgb64-windows-$version.zip"
}

case "$action" in
  build) build ;;
  test) build; test_mods ;;
  smoke) build; test_mods; smoke_launcher; smoke_game ;;
  package) build; test_mods; package ;;
  all) build; test_mods; smoke_launcher; smoke_game; package ;;
  *)
    echo "Usage: $0 [build|test|smoke|package|all]" >&2
    exit 2
    ;;
esac
