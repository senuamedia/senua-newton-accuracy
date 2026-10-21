#!/usr/bin/env bash
# Run 018, a patch in design (not registered): patches/in_design/xpbd_restitution_friction_v2.diff, the second form of
# run 016's patch. Run 016's first form (NEWTON_XPBD_RESTITUTION_FRICTION=1) gave Coulomb's friction at the impact at
# five of seven steps but friction above Coulomb's over the impact (T05 at two steps, T10 at every step). The
# hypothesis: where the restitution pass pulls a contact's separation back and the contact still slips, XPBD's
# position pass gave friction at its bound, mu times a normal impulse the pass has now made smaller, and the first form
# never takes that friction back. The second form (=2) takes it back: an impulse along the slip of mu times the normal
# impulse pulled back. The first form's kernel is unchanged and still selected by =1.
# The five checks, on the first deep dive's ten-test suite (tools/contact_suite.sh, every scene unchanged), against
# run 016's kept suites (Newton 1.6.1 from PyPI: r016_stock_plain, r016_stock_res; the first form: r016_on_res):
#   r018_off_plain   the patched source, the switch unset, XPBD as released
#   r018_off_res     the same, with enable_restitution
#   r018_on1_res     the switch at 1, with enable_restitution: the first form, which must play as in run 016
#   r018_on2_plain   the switch at 2, XPBD as released (the patch must do nothing when the pass does not run)
#   r018_on2_res     the switch at 2, with enable_restitution: the second form at work
# Predicted, before the plays: on2_res passes T04 (rebound 0 at every step), T05 and T10 (Coulomb's friction at and
# after an impact, within the suite's tolerances), T01, T02, T03, T08 and T09, and reads T06 and T07 as stock_res does;
# off_plain, off_res and on2_plain are byte-identical to stock_plain and stock_res; on1_res to run 016's on_res; no
# play stops being a number.
# usage: play.sh <folder holding sx_contact and sx_contact_suite.sh>   (repository root; XPBD_VENV set to the patched
#        source's environment; XPBD_SRC to that source, to record it)
set -u
M="$(cd "${1:?usage: play.sh <runner folder>}" && pwd)"
O=validation/run_018_restitution_friction_take_back; mkdir -p $O
arm() {  # <label> <switch: empty, 1 or 2> <rig settings...>
  local label=$1 sw=$2; shift 2
  ( . "$XPBD_VENV/bin/activate"
    if [ -n "$sw" ]; then export NEWTON_XPBD_RESTITUTION_FRICTION=$sw; else unset NEWTON_XPBD_RESTITUTION_FRICTION; fi
    tools/contact_suite.sh $label solver=xpbd "$@" > $O/play_$label.txt 2> $O/log_$label.txt
    bash "$M/sx_contact_suite.sh" suites/1/$label suites/1/$label/verdicts.txt > /dev/null 2>> $O/log_$label.txt
    echo "runner rc $?" >> $O/play_$label.txt )
}
date -u +%FT%TZ > $O/started.txt
if [ -n "${XPBD_SRC:-}" ]; then
  { git -C "$XPBD_SRC" log --oneline -1; git -C "$XPBD_SRC" status --short
    (cd "$XPBD_SRC" && sha256sum newton/_src/solvers/xpbd/solver_xpbd.py newton/_src/solvers/xpbd/restitution_friction_kernels.py)
  } > $O/patched_source.txt
fi
arm r018_off_plain "" &
arm r018_off_res "" opt.enable_restitution=true &
arm r018_on1_res 1 opt.enable_restitution=true &
wait
arm r018_on2_plain 2 &
arm r018_on2_res 2 opt.enable_restitution=true &
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
  for l in r018_off_plain r018_off_res r018_on1_res r018_on2_plain r018_on2_res; do
    echo "== $l ($(tail -1 $O/play_$l.txt)); plays that stopped being a number: $(grep -c nan_at_step suites/1/$l/stats.txt)"
    grep '^T[01][0-9]\|^SUITE' suites/1/$l/verdicts.txt
  done
  echo "== safe when off, and the first form unchanged"
  same r018_off_plain r016_stock_plain
  same r018_off_res r016_stock_res
  same r018_on2_plain r016_stock_plain
  same r018_on1_res r016_on_res
  echo "== the impact and the bounce, with the second form"
  for k in 1 2 4 8 16 32 64; do
    echo "oblique 1/$k | $("$M/sx_contact" impact suites/1/r018_on2_res/oblique_$k.txt | tail -1)"
    echo "drop 1/$k | $("$M/sx_contact" bounce suites/1/r018_on2_res/drop_$k.txt | tail -1)"
  done
  echo "== the largest turn of the cube (most_tilt_urad), oblique impact"
  for l in r016_stock_plain r016_stock_res r016_on_res r018_on2_res; do
    echo "$l: $(grep 'run oblique_' suites/1/$l/stats.txt | grep -o 'most_tilt_urad [0-9]*' | cut -d' ' -f2 | tr '\n' ' ')"
  done
} > $O/reading.txt
