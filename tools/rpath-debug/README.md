RPATH toggle investigation helpers

This folder contains a tiny CMake probe and two helper scripts to compare CMake install-time RPATH behavior with and without `NIX_DEBUG`.

Contents
- probe/: minimal CMake project that prints key variables and installs a trivial binary.
- run-probe.sh: runs A/B builds (unset vs `NIX_DEBUG=1`), diffs CMake artifacts, and shows whether `RPATH_CHANGE` is emitted.
- run-saxpy.sh: builds `cudaPackages_12.saxpy` twice (baseline vs derivation `env.NIX_DEBUG=1`), shows RUNPATHs.

Quick start
1) Local CMake probe (no CUDA required)
   - cd tools/rpath-debug
   - ./run-probe.sh
   - Inspect `out-probe/summary.txt` and `out-probe/diffs/` for differences. Look for `RPATH_CHANGE` and implicit link dir changes.

2) Compare saxpy RUNPATHs (CUDA)
   - cd tools/rpath-debug
   - ./run-saxpy.sh ~/.config/nixpkgs/config-sm_89.nix
   - The script prints RUNPATH for `result-baseline` and `result-debug` (derivation with `env.NIX_DEBUG=1`).

Notes
- `run-saxpy.sh` uses `nix build --expr` to apply a local `overrideAttrs` that sets `env.NIX_DEBUG=1` for the debug case; it leaves your local nixpkgs tree untouched.
- Both scripts are safe to run repeatedly; they clear their own build/output directories.

