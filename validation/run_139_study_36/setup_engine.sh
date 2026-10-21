#!/usr/bin/env bash
# Run 139 (Study 36): the engines: the base environment's Newton with Senua AI's VBD displacement patch (dsp), and with
# the displacement patch and the VBD pose carry (carry: off and on by NEWTON_VBD_POSE_CARRY), no fuzz, first on the path.
# Writes a manifest.
# usage: setup_engine.sh <base venv> <out folder>   (repository root)
set -eu
BASE="$(cd "${1:?usage: setup_engine.sh <base venv> <out folder>}" && pwd)"; mkdir -p "${2:?}"; OUT="$(cd "$2" && pwd)"
SITE=$(ls -d "$BASE"/lib/python3*/site-packages); R=$(pwd)
engine() {  # <name> <diff> [<diff>]
  local e="$OUT/$1" d; shift; rm -rf "$e"; mkdir -p "$e/src" "$e/bin"
  (cd "$SITE" && tar cf - --exclude=__pycache__ newton) | tar xf - -C "$e/src"
  for d in "$@"; do (cd "$e/src" && patch -s -p1 -F 0 --no-backup-if-mismatch < "$R/$d"); done
  find "$e/src" \( -name '*.orig' -o -name '*.rej' \) -print | grep . && { echo "patch left files in $e" >&2; exit 2; } || true
  printf '%s\n' ". \"$BASE/bin/activate\"" "export PYTHONPATH=\"$e/src\"" > "$e/bin/activate"
}
engine dsp patches/in_design/vbd_displacement_on_1.7.0.diff
engine carry patches/in_design/vbd_displacement_on_1.7.0.diff patches/in_design/vbd_pose_carry_on_displacement.diff
{ echo "base $BASE"; "$BASE/bin/pip" freeze 2>/dev/null
  for e in dsp carry; do (cd "$OUT/$e/src" && find newton -type f | LC_ALL=C sort | xargs sha256sum | sed "s|^|$e |"); done
} > "$OUT/manifest.txt"
echo "engines ready in $OUT"
