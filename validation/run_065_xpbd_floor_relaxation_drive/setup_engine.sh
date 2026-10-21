#!/usr/bin/env bash
# Run 065: the engines for XPBD's speed floor (issue 17), its relaxations (issue 25) and its drive (issue 26). From the
# base Newton 1.7.0 environment, each engine is the base environment's own Newton package, copied, with its diffs applied
# in order (no fuzz), and an environment that is the base one with that tree first on the path, as run 053's
# setup_engine.sh lays them out. Writes a manifest of every tree.
#   nofloor          Senua AI's speed-floor patch, in design (patches/in_design/xpbd_no_speed_floor_on_1.7.0.diff)
#   pr4317           pull request #4317 (patches/upstream/pr_4317.diff)
#   pr4317_nofloor   #4317, then the speed-floor patch
#   pr4318           pull request #4318 rebased onto 1.7.0 (patches/upstream/pr_4318_on_1.7.0.diff; it carries its own
#                    forms of #4316 and #4317)
#   pr4318_nofloor   #4318, then the speed-floor patch in its form for #4318's tree (xpbd_no_speed_floor_on_pr4318.diff)
# usage: setup_engine.sh <base venv> <out folder>   (repository root)
set -eu
BASE="$(cd "${1:?usage: setup_engine.sh <base venv> <out folder>}" && pwd)"; mkdir -p "${2:?}"; OUT="$(cd "$2" && pwd)"
SITE=$(ls -d "$BASE"/lib/python3*/site-packages); R=$(pwd)
engine() {  # <name> <diff> [<diff>]
  local e="$OUT/$1" d; shift
  rm -rf "$e"; mkdir -p "$e/src" "$e/bin"
  (cd "$SITE" && tar cf - --exclude=__pycache__ newton) | tar xf - -C "$e/src"
  for d in "$@"; do (cd "$e/src" && patch -s -p1 -F 0 --no-backup-if-mismatch < "$R/$d"); done
  find "$e/src" \( -name '*.orig' -o -name '*.rej' \) -print | grep . && { echo "patch left files in $e" >&2; exit 2; } || true
  printf '%s\n' "# the base environment with this engine's Newton first on the path" ". \"$BASE/bin/activate\"" \
    "export PYTHONPATH=\"$e/src\"" > "$e/bin/activate"
}
mkdir -p "$OUT/stock/bin"
printf '%s\n' "# the base environment as released, nothing ahead of it on the path" ". \"$BASE/bin/activate\"" \
  "unset PYTHONPATH" > "$OUT/stock/bin/activate"
F=patches/in_design/xpbd_no_speed_floor_on_1.7.0.diff
engine nofloor $F
engine pr4317 patches/upstream/pr_4317.diff
engine pr4317_nofloor patches/upstream/pr_4317.diff $F
engine pr4318 patches/upstream/pr_4318_on_1.7.0.diff
engine pr4318_nofloor patches/upstream/pr_4318_on_1.7.0.diff patches/in_design/xpbd_no_speed_floor_on_pr4318.diff
{ echo "base $BASE"; "$BASE/bin/pip" freeze 2>/dev/null
  for e in nofloor pr4317 pr4317_nofloor pr4318 pr4318_nofloor; do
    (cd "$OUT/$e/src" && find newton -type f | LC_ALL=C sort | xargs sha256sum | sed "s|^|$e |"); done
} > "$OUT/manifest.txt"
echo "engines ready in $OUT"
