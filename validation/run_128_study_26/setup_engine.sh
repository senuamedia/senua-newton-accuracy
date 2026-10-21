#!/usr/bin/env bash
# Run 128 (Study 26): the engine: the base environment's Newton with Senua AI's friction combination patch (no fuzz), first
# on the path; stock is the release. Writes a manifest.
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
mkdir -p "$OUT/stock/bin"; printf '%s\n' ". \"$BASE/bin/activate\"" "unset PYTHONPATH" > "$OUT/stock/bin/activate"
engine on patches/in_design/friction_combine_on_1.7.0.diff
{ echo "base $BASE"; "$BASE/bin/pip" freeze 2>/dev/null
  (cd "$OUT/on/src" && find newton -type f | LC_ALL=C sort | xargs sha256sum | sed "s|^|on |")
} > "$OUT/manifest.txt"
echo "engines ready in $OUT"
