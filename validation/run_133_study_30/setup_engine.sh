#!/usr/bin/env bash
# Run 133 (Study 30): the engines: "chain", the base environment's Newton with the record's validated friction chains
# (SemiImplicit's and Featherstone's: unit_friction_direction, contact_damping_no_pull, semi_coulomb_friction,
# featherstone_coulomb_friction, Study 18; XPBD's: xpbd_no_speed_floor, xpbd_friction_total, Study 15) and pull request
# #4306 rebased onto 1.7.0; "on", the chain with Senua AI's static friction patch and its XPBD friction slip patch
# (patches/in_design/static_friction_v2_on_chain.diff, xpbd_friction_slip_on_static.diff); stock is the release. All no
# fuzz, first on the path. Beside
# every engine, Newton's USD importer's own dependencies from PyPI, pinned and checked by sha256: usd-core 26.8 and
# newton-usd-schemas 0.6.0. Writes a manifest. usage: setup_engine.sh <base venv> <out folder>   (repository root)
set -eu
BASE="$(cd "${1:?usage: setup_engine.sh <base venv> <out folder>}" && pwd)"; mkdir -p "${2:?}"; OUT="$(cd "$2" && pwd)"
SITE=$(ls -d "$BASE"/lib/python3*/site-packages); R=$(pwd)
rm -rf "$OUT/wheels" "$OUT/usd"; mkdir -p "$OUT/wheels"
"$BASE/bin/pip" download -q --no-deps -d "$OUT/wheels" usd-core==26.8 newton-usd-schemas==0.6.0
(cd "$OUT/wheels" && sha256sum -c - <<'SUMS'
204fb1ef1fc977b827c491f4e9fa39b57518504ed0cacfe12e026e95123cacf1  usd_core-26.8-cp312-none-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl
05e027d2bd1f1b1ed07909a1efb865a24cbba3fd94716a77cc637ea93859217b  newton_usd_schemas-0.6.0-py3-none-any.whl
SUMS
)
"$BASE/bin/pip" install -q --no-deps --target "$OUT/usd" "$OUT"/wheels/*.whl
mkdir -p "$OUT/stock/bin"; printf '%s\n' ". \"$BASE/bin/activate\"" "export PYTHONPATH=\"$OUT/usd\"" > "$OUT/stock/bin/activate"
engine() {  # <name> <diff>...
  local e="$OUT/$1" d; shift; rm -rf "$e"; mkdir -p "$e/src" "$e/bin"
  (cd "$SITE" && tar cf - --exclude=__pycache__ newton) | tar xf - -C "$e/src"
  for d in "$@"; do (cd "$e/src" && patch -s -p1 -F 0 --no-backup-if-mismatch < "$R/$d"); done
  find "$e/src" \( -name '*.orig' -o -name '*.rej' \) -print | grep . && { echo "patch left files in $e" >&2; exit 2; } || true
  printf '%s\n' ". \"$BASE/bin/activate\"" "export PYTHONPATH=\"$e/src:$OUT/usd\"" > "$e/bin/activate"
}
CHAIN="patches/newton-1.7.0/unit_friction_direction.diff patches/newton-1.7.0/contact_damping_no_pull.diff
  patches/newton-1.7.0/semi_coulomb_friction.diff patches/newton-1.7.0/featherstone_coulomb_friction.diff
  patches/newton-1.7.0/xpbd_no_speed_floor.diff patches/newton-1.7.0/xpbd_friction_total.diff
  patches/upstream/pr_4306_on_1.7.0.diff"
engine chain $CHAIN
engine on $CHAIN patches/in_design/static_friction_v2_on_chain.diff patches/in_design/xpbd_friction_slip_on_static.diff
{ echo "base $BASE"; "$BASE/bin/pip" freeze 2>/dev/null; (cd "$OUT/wheels" && sha256sum *.whl | sed "s|^|wheel |")
  for x in chain on; do (cd "$OUT/$x/src" && find newton -type f | LC_ALL=C sort | xargs sha256sum | sed "s|^|$x |"); done
} > "$OUT/manifest.txt"
echo "engines ready in $OUT"
