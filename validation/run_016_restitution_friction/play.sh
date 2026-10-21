#!/usr/bin/env bash
# Run 016, a patch in design (not registered): patches/in_design/xpbd_restitution_friction.diff, Newton v1.6.1 with
# XPBD's restitution pass replaced, only when the solver is made with NEWTON_XPBD_RESTITUTION_FRICTION=1 (read once),
# by a copy that adds Coulomb's friction on the normal impulse the pass applies. Run 015 found that XPBD's own
# enable_restitution removes its bounce with a restitution of 0 but cuts friction at an impact to 4% to 43% of
# Coulomb's; Newton's source shows why: the restitution pass applies normal impulses only, while XPBD's friction is
# bounded by the position pass's own normal correction.
# The five checks, on the first deep dive's ten-test suite (tools/contact_suite.sh, every scene unchanged), six arms,
# each its own suite folder:
#   r016_stock_plain  Newton 1.6.1 from PyPI (run 001's environment), XPBD as released
#   r016_stock_res    the same, with enable_restitution (run 015's arm, played again)
#   r016_off_plain    Newton v1.6.1 from source with the patch applied, the switch unset, XPBD as released
#   r016_off_res      the same, with enable_restitution
#   r016_on_plain     the switch set, XPBD as released (the patch must do nothing when the pass does not run)
#   r016_on_res       the switch set, with enable_restitution: the patch at work
# Predicted, before the plays: on_res passes T04 (rebound 0 at every step), T05 and T10 (Coulomb's friction at an
# impact), as stock_plain does; T01, T02, T03 and T09 pass and T06 and T07 read as stock_res; every file of off_plain
# and off_res is byte-identical to stock_plain and stock_res, and every file of on_plain to stock_plain; no play
# stops being a number.
# usage: play.sh <folder holding sx_contact and sx_contact_suite.sh>   (repository root; STOCK_VENV and XPBD_VENV set
#        to Newton 1.6.1 from PyPI and to the patched source's environment)
set -u
M="$(cd "${1:?usage: play.sh <runner folder>}" && pwd)"
O=validation/run_016_restitution_friction; mkdir -p $O
arm() {  # <label> <venv> <switch 0|1> <rig settings...>
  local label=$1 venv=$2 sw=$3; shift 3
  ( . "$venv/bin/activate"
    if [ "$sw" = 1 ]; then export NEWTON_XPBD_RESTITUTION_FRICTION=1; else unset NEWTON_XPBD_RESTITUTION_FRICTION; fi
    tools/contact_suite.sh $label solver=xpbd "$@" > $O/play_$label.txt 2> $O/log_$label.txt
    bash "$M/sx_contact_suite.sh" suites/1/$label suites/1/$label/verdicts.txt > /dev/null 2>> $O/log_$label.txt
    echo "runner rc $?" >> $O/play_$label.txt )
}
date -u +%FT%TZ > $O/started.txt
if [ -n "${XPBD_SRC:-}" ]; then  # the patched source the environment plays: its commit, what differs, the two files
  { git -C "$XPBD_SRC" log --oneline -1; git -C "$XPBD_SRC" status --short
    (cd "$XPBD_SRC" && sha256sum newton/_src/solvers/xpbd/solver_xpbd.py newton/_src/solvers/xpbd/restitution_friction_kernels.py)
  } > $O/patched_source.txt
fi
arm r016_stock_plain "$STOCK_VENV" 0 &
arm r016_stock_res "$STOCK_VENV" 0 opt.enable_restitution=true &
arm r016_off_plain "$XPBD_VENV" 0 &
wait
arm r016_off_res "$XPBD_VENV" 0 opt.enable_restitution=true &
arm r016_on_plain "$XPBD_VENV" 1 &
arm r016_on_res "$XPBD_VENV" 1 opt.enable_restitution=true &
wait
date -u +%FT%TZ > $O/finished.txt
same() {  # <label a> <label b>: the play files (not stats.txt or CONFIG) byte for byte
  local n=0 d=0 f
  for f in suites/1/$1/*_[0-9]*.txt; do
    n=$((n + 1)); cmp -s "$f" "suites/1/$2/$(basename "$f")" || { d=$((d + 1)); echo "DIFFERS $1 $2 $(basename "$f")"; }
  done
  echo "IDENTITY $1 against $2: $((n - d)) of $n byte-identical"
}
{
  for l in r016_stock_plain r016_stock_res r016_off_plain r016_off_res r016_on_plain r016_on_res; do
    echo "== $l ($(tail -1 $O/play_$l.txt)); plays that stopped being a number: $(grep -c nan_at_step suites/1/$l/stats.txt)"
    grep '^T[01][0-9]\|^SUITE' suites/1/$l/verdicts.txt
  done
  echo "== safe when off"
  same r016_off_plain r016_stock_plain
  same r016_off_res r016_stock_res
  same r016_on_plain r016_stock_plain
  echo "== against the earlier plays of the same arms"
  same r016_stock_plain xpbd
  same r016_stock_res xpbd_restitution
  echo "== the impact and the bounce, with the patch"
  for k in 1 2 4 8 16 32 64; do
    echo "oblique 1/$k | $("$M/sx_contact" impact suites/1/r016_on_res/oblique_$k.txt | tail -1)"
    echo "drop 1/$k | $("$M/sx_contact" bounce suites/1/r016_on_res/drop_$k.txt | tail -1)"
  done
  echo "== the largest turn of the cube (most_tilt_urad), oblique impact"
  for l in r016_stock_plain r016_stock_res r016_on_res; do
    echo "$l: $(grep 'run oblique_' suites/1/$l/stats.txt | grep -o 'most_tilt_urad [0-9]*' | cut -d' ' -f2 | tr '\n' ' ')"
  done
} > $O/reading.txt
