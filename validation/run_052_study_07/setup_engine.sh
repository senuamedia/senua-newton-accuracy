#!/usr/bin/env bash
# Run 052 (Study 7, preregistrations/PREREGISTRATION_07.md): one engine's environments for the replay. From a base
# environment holding Newton from PyPI, each patch family gets a source tree (the base environment's own Newton package,
# copied, with the family's patch applied) and an environment that is the base one with that tree first on the path.
# The normal contact's tree is the unit friction's with its patch on top, as on 1.6.1. Writes a manifest of every tree.
# usage: setup_engine.sh <base venv> <patch folder> <out folder>   (repository root)
#   patch folder: patches/newton-1.7.0 for 1.7.0; for 1.6.1, the record's patches (patches/ and patches/in_design/)
set -eu
BASE="$(cd "${1:?usage: setup_engine.sh <base venv> <patch folder> <out folder>}" && pwd)"; P="$(cd "${2:?}" && pwd)"
mkdir -p "${3:?}"; OUT="$(cd "$3" && pwd)"
SITE=$(ls -d "$BASE"/lib/python3*/site-packages)
pick() {  # <name>: the family's patch file, in the folder given or, for 1.6.1, in its in_design folder
  if [ -f "$P/$1" ]; then echo "$P/$1"; elif [ -f "$P/in_design/$1" ]; then echo "$P/in_design/$1"; else echo "no patch $1" >&2; exit 2; fi
}
tree() {  # <family> <patch> [<tree to start from>]
  local fam=$1 p=$2 from=${3:-}
  rm -rf "$OUT/src_$fam"; mkdir -p "$OUT/src_$fam"
  if [ -n "$from" ]; then cp -R "$OUT/src_$from/newton" "$OUT/src_$fam/"; else (cd "$SITE" && tar cf - --exclude=__pycache__ newton) | tar xf - -C "$OUT/src_$fam"; fi
  (cd "$OUT/src_$fam" && patch -s -p1 --no-backup-if-mismatch < "$p")
  find "$OUT/src_$fam" \( -name '*.orig' -o -name '*.rej' \) -print | grep . && { echo "patch left files in $fam" >&2; exit 2; } || true
  mkdir -p "$OUT/$fam/bin"
  printf '%s\n' "# the base environment with the $fam patch family's Newton first on the path" ". \"$BASE/bin/activate\"" \
    "export PYTHONPATH=\"$OUT/src_$fam\"" > "$OUT/$fam/bin/activate"
}
tree unit "$(pick unit_friction_direction.diff)"
tree normal "$(pick contact_damping_no_pull.diff)" unit
tree xres "$(pick xpbd_restitution_friction_v2.diff)"
tree vbd "$(pick vbd_carried_velocity_v2.diff)"
tree mjlim "$(pick mujoco_limit_force_space.diff)"
tree xlim "$(pick xpbd_joint_angle_v3.diff)"
rm -rf "$OUT/stock"; mkdir -p "$OUT/stock/bin"
printf '%s\n' "# the base environment as released, nothing ahead of it on the path" ". \"$BASE/bin/activate\"" \
  "unset PYTHONPATH" > "$OUT/stock/bin/activate"
{ echo "base $BASE"; "$BASE/bin/pip" freeze 2>/dev/null || ls "$SITE" | sed -n 's/\.dist-info$//p'
  for fam in unit normal xres vbd mjlim xlim; do (cd "$OUT/src_$fam" && find newton -type f | LC_ALL=C sort | xargs sha256sum | sed "s|^|$fam |"); done
} > "$OUT/manifest.txt"
echo "engine ready in $OUT: $(grep -c '^[a-z]* [0-9a-f]\{64\}' "$OUT/manifest.txt") files in six trees"
