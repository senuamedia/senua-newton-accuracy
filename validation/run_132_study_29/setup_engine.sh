#!/usr/bin/env bash
# Run 132 (Study 29, copied from run 131): the engine: "chain", the base environment's Newton with the record's validated friction chains
# (SemiImplicit's and Featherstone's: unit_friction_direction, contact_damping_no_pull, semi_coulomb_friction,
# featherstone_coulomb_friction, Study 18; XPBD's: xpbd_no_speed_floor, xpbd_friction_total, Study 15); stock is the
# release; "mjc", the release with Senua AI's MuJoCo noslip patch (Study 11), whose MuJoCo solver on its CPU path is
# MuJoCo C, the reference. All no fuzz, first on the path. Writes a manifest.
# usage: setup_engine.sh <base venv> <out folder>   (repository root)
set -eu
BASE="$(cd "${1:?usage: setup_engine.sh <base venv> <out folder>}" && pwd)"; mkdir -p "${2:?}"; OUT="$(cd "$2" && pwd)"
SITE=$(ls -d "$BASE"/lib/python3*/site-packages); R=$(pwd)
mkdir -p "$OUT/stock/bin"; printf '%s\n' ". \"$BASE/bin/activate\"" "unset PYTHONPATH" > "$OUT/stock/bin/activate"
engine() {  # <name> <diff>...
  local e="$OUT/$1" d; shift; rm -rf "$e"; mkdir -p "$e/src" "$e/bin"
  (cd "$SITE" && tar cf - --exclude=__pycache__ newton) | tar xf - -C "$e/src"
  for d in "$@"; do (cd "$e/src" && patch -s -p1 -F 0 --no-backup-if-mismatch < "$R/$d"); done
  find "$e/src" \( -name '*.orig' -o -name '*.rej' \) -print | grep . && { echo "patch left files in $e" >&2; exit 2; } || true
  printf '%s\n' ". \"$BASE/bin/activate\"" "export PYTHONPATH=\"$e/src\"" > "$e/bin/activate"
}
engine chain patches/newton-1.7.0/unit_friction_direction.diff patches/newton-1.7.0/contact_damping_no_pull.diff \
  patches/newton-1.7.0/semi_coulomb_friction.diff patches/newton-1.7.0/featherstone_coulomb_friction.diff \
  patches/newton-1.7.0/xpbd_no_speed_floor.diff patches/newton-1.7.0/xpbd_friction_total.diff
engine mjc patches/newton-1.7.0/mujoco_noslip.diff
{ echo "base $BASE"; "$BASE/bin/pip" freeze 2>/dev/null
  for x in chain mjc; do (cd "$OUT/$x/src" && find newton -type f | LC_ALL=C sort | xargs sha256sum | sed "s|^|$x |"); done
} > "$OUT/manifest.txt"
echo "engines ready in $OUT"
