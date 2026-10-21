#!/usr/bin/env bash
# Run 053 (Study 8, preregistrations/PREREGISTRATION_08.md): an engine folder for each pull request, laid out as Study
# 7's setup_engine.sh lays one out, so Study 7's replay.sh plays it: the base 1.7.0 environment's own Newton package,
# copied, with the pull request's diff applied (no fuzz allowed), first on the path in every patch family's slot
# (unit, normal, xres, vbd, mjlim, xlim), so a run's patched arm plays the pull request; stock is the release with
# nothing ahead of it. Writes a manifest of every tree.
# usage: setup_engine.sh <base venv> <diff folder> <out folder>   (repository root)
#   diff folder: patches/upstream
set -eu
BASE="$(cd "${1:?usage: setup_engine.sh <base venv> <diff folder> <out folder>}" && pwd)"; P="$(cd "${2:?}" && pwd)"
mkdir -p "${3:?}"; OUT="$(cd "$3" && pwd)"
SITE=$(ls -d "$BASE"/lib/python3*/site-packages)
engine() {  # <name> <diff>
  local e="$OUT/$1" fam
  rm -rf "$e"; mkdir -p "$e/src"
  (cd "$SITE" && tar cf - --exclude=__pycache__ newton) | tar xf - -C "$e/src"
  (cd "$e/src" && patch -s -p1 -F 0 --no-backup-if-mismatch < "$2")
  find "$e/src" \( -name '*.orig' -o -name '*.rej' \) -print | grep . && { echo "patch left files in $1" >&2; exit 2; } || true
  for fam in unit normal xres vbd mjlim xlim; do
    mkdir -p "$e/$fam/bin"
    printf '%s\n' "# the base environment with pull request $1's Newton first on the path" ". \"$BASE/bin/activate\"" \
      "export PYTHONPATH=\"$e/src\"" > "$e/$fam/bin/activate"
    ln -sfn "$e/src" "$e/src_$fam"
  done
  mkdir -p "$e/stock/bin"
  printf '%s\n' "# the base environment as released, nothing ahead of it on the path" ". \"$BASE/bin/activate\"" \
    "unset PYTHONPATH" > "$e/stock/bin/activate"
}
engine pr4010 "$P/pr_4010_on_1.7.0.diff"
engine pr4316 "$P/pr_4316.diff"
engine pr4317 "$P/pr_4317.diff"
{ echo "base $BASE"; "$BASE/bin/pip" freeze 2>/dev/null || ls "$SITE" | sed -n 's/\.dist-info$//p'
  for e in pr4010 pr4316 pr4317; do (cd "$OUT/$e/src" && find newton -type f | LC_ALL=C sort | xargs sha256sum | sed "s|^|$e |"); done
} > "$OUT/manifest.txt"
echo "engines ready in $OUT: $(grep -c '^pr[0-9]* [0-9a-f]\{64\}' "$OUT/manifest.txt") files in three trees"
