#!/usr/bin/env bash
# Run 078 (Study 12): the engines. From the base Newton 1.7.0 environment, each is the base environment's own Newton
# package, copied, with one diff applied (no fuzz), and an environment that is the base one with that tree first on the
# path; stock is the release with nothing ahead of it. Writes a manifest of every tree.
#   semijoint patches/in_design/semi_joint_on_1.7.0.diff
#   fslimit   patches/in_design/featherstone_limit_v2_on_1.7.0.diff
# usage: setup_engine.sh <base venv> <out folder>   (repository root)
set -eu
BASE="$(cd "${1:?usage: setup_engine.sh <base venv> <out folder>}" && pwd)"; mkdir -p "${2:?}"; OUT="$(cd "$2" && pwd)"
SITE=$(ls -d "$BASE"/lib/python3*/site-packages); R=$(pwd)
engine() {  # <name> <diff>
  local e="$OUT/$1"
  rm -rf "$e"; mkdir -p "$e/src" "$e/bin"
  (cd "$SITE" && tar cf - --exclude=__pycache__ newton) | tar xf - -C "$e/src"
  (cd "$e/src" && patch -s -p1 -F 0 --no-backup-if-mismatch < "$R/$2")
  find "$e/src" \( -name '*.orig' -o -name '*.rej' \) -print | grep . && { echo "patch left files in $e" >&2; exit 2; } || true
  printf '%s\n' "# the base environment with this engine's Newton first on the path" ". \"$BASE/bin/activate\"" \
    "export PYTHONPATH=\"$e/src\"" > "$e/bin/activate"
}
mkdir -p "$OUT/stock/bin"
printf '%s\n' "# the base environment as released, nothing ahead of it on the path" ". \"$BASE/bin/activate\"" \
  "unset PYTHONPATH" > "$OUT/stock/bin/activate"
engine semijoint patches/in_design/semi_joint_on_1.7.0.diff
engine fslimit patches/in_design/featherstone_limit_v2_on_1.7.0.diff
{ echo "base $BASE"; "$BASE/bin/pip" freeze 2>/dev/null
  for e in semijoint fslimit; do (cd "$OUT/$e/src" && find newton -type f | LC_ALL=C sort | xargs sha256sum | sed "s|^|$e |"); done
} > "$OUT/manifest.txt"
echo "engines ready in $OUT"
