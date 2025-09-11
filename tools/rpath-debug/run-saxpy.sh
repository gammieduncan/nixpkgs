#!/usr/bin/env bash
set -euo pipefail

# Build saxpy twice: baseline vs derivation with env.NIX_DEBUG=1, then print RUNPATHs.
#
# Usage:
#   ./run-saxpy.sh /path/to/your/config.nix
#   (the config should set cudaSupport/allowUnfree/cudaCapabilities as needed)

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 /path/to/NIXPKGS_CONFIG.nix" >&2
  exit 1
fi

cfg="$1"

root_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
work_dir="$root_dir/out-saxpy"
rm -rf "$work_dir"
mkdir -p "$work_dir"
pushd "$work_dir" >/dev/null

export NIXPKGS_CONFIG="$cfg"

echo "== Building saxpy baseline (no NIX_DEBUG in derivation) =="
nix build --impure --expr '
let pkgs = import ../../. {}; in pkgs.cudaPackages_12.saxpy
' -o result-baseline

echo "== Building saxpy debug (env.NIX_DEBUG=1 inside derivation) =="
nix build --impure --expr '
let pkgs = import ../../. {}; in pkgs.cudaPackages_12.saxpy.overrideAttrs (_: {
  # ensure structured attrs env path for env attrs
  __structuredAttrs = true;
  env = ({} // { NIX_DEBUG = 1; });
})
' -o result-debug

echo "== RUNPATH diffs =="
if command -v patchelf >/dev/null 2>&1; then
  echo "-- baseline:" 
  patchelf --print-rpath result-baseline/bin/saxpy || true
  echo "-- debug (env.NIX_DEBUG=1):"
  patchelf --print-rpath result-debug/bin/saxpy || true
else
  echo "patchelf not found; please install patchelf to view RUNPATH" >&2
fi

popd >/dev/null
echo "Done. See $work_dir/ for results."

