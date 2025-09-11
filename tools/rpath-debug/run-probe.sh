#!/usr/bin/env bash
set -euo pipefail

# A/B compare CMake install-time RPATH behavior with and without NIX_DEBUG.

root_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
src_dir="$root_dir/probe"
work_dir="$root_dir/out-probe"

rm -rf "$work_dir"
mkdir -p "$work_dir"

pushd "$work_dir" >/dev/null

echo "== Configure + build + install: baseline (NIX_DEBUG unset) =="
cmake -S "$src_dir" -B buildA -DCMAKE_VERBOSE_MAKEFILE=ON
cmake --build buildA
cmake --install buildA --prefix "$PWD/outA"

echo "== Configure + build + install: debug (NIX_DEBUG=1) =="
NIX_DEBUG=1 cmake -S "$src_dir" -B buildB -DCMAKE_VERBOSE_MAKEFILE=ON
NIX_DEBUG=1 cmake --build buildB
NIX_DEBUG=1 cmake --install buildB --prefix "$PWD/outB"

mkdir -p diffs

echo "== Grepping cmake_install.cmake for RPATH_CHANGE ==" | tee summary.txt
{
  echo "-- buildA (baseline)";
  rg -n "RPATH_(CHECK|CHANGE)" buildA/cmake_install.cmake || true
  echo "-- buildB (NIX_DEBUG=1)";
  rg -n "RPATH_(CHECK|CHANGE)" buildB/cmake_install.cmake || true
} | tee -a summary.txt

echo "== Comparing CMakeCache.txt ==" | tee -a summary.txt
diff -u buildA/CMakeCache.txt buildB/CMakeCache.txt > diffs/CMakeCache.diff || true
echo "  wrote diffs/CMakeCache.diff" | tee -a summary.txt

echo "== Comparing compiler implicit dirs and logs ==" | tee -a summary.txt
diff -u <(rg -n "IMPLICIT_LINK_(DIRECTORIES|LIBRARIES)" buildA/CMakeFiles/*Compiler.cmake || true) \
        <(rg -n "IMPLICIT_LINK_(DIRECTORIES|LIBRARIES)" buildB/CMakeFiles/*Compiler.cmake || true) \
        > diffs/implicit-link-vars.diff || true
echo "  wrote diffs/implicit-link-vars.diff" | tee -a summary.txt

diff -u buildA/CMakeFiles/CMakeOutput.log buildB/CMakeFiles/CMakeOutput.log > diffs/CMakeOutput.diff || true
echo "  wrote diffs/CMakeOutput.diff" | tee -a summary.txt

echo "== RUNPATH of installed probe binaries ==" | tee -a summary.txt
if command -v patchelf >/dev/null 2>&1; then
  echo "-- outA/bin/rpath-probe" | tee -a summary.txt
  patchelf --print-rpath outA/bin/rpath-probe 2>/dev/null | tee -a summary.txt || echo "(no RUNPATH)" | tee -a summary.txt
  echo "-- outB/bin/rpath-probe" | tee -a summary.txt
  patchelf --print-rpath outB/bin/rpath-probe 2>/dev/null | tee -a summary.txt || echo "(no RUNPATH)" | tee -a summary.txt
else
  echo "patchelf not found; skipping RUNPATH dump" | tee -a summary.txt
fi

popd >/dev/null
echo "Done. See $work_dir/summary.txt and $work_dir/diffs/*"

