#!/usr/bin/env bash
# Run 007, design probe (not registered): the first deep dive's ten-test contact suite (tools/contact_suite.sh: its
# scenes, steps 10 ms over 1 to 64, file names) on each Newton solver with its defaults, and on SemiImplicit and
# Featherstone with the unit-friction patch in design on (run 005); read by the first deep dive's own runner,
# sx_contact_suite.sh, unchanged. The MuJoCo deep dive's run 008 read MuJoCo the same way.
# usage: play.sh <folder holding sx_contact and sx_contact_suite.sh>   (repository root; STOCK_VENV and PATCHED_VENV set)
set -u
M="$(cd "${1:?usage: play.sh <runner folder>}" && pwd)"
O=validation/run_007_contact_suite; mkdir -p $O
one() {  # <label> <venv> <switch> <solver>
  local label=$1 venv=$2 sw=$3 s=$4
  ( . "$venv/bin/activate"
    if [ "$sw" = 1 ]; then export NEWTON_UNIT_FRICTION_DIRECTION=1; else unset NEWTON_UNIT_FRICTION_DIRECTION; fi
    tools/contact_suite.sh $label solver=$s > $O/play_$label.txt 2> $O/log_$label.txt
    bash "$M/sx_contact_suite.sh" suites/1/$label suites/1/$label/verdicts.txt > /dev/null 2>> $O/log_$label.txt
    echo "rc $?" >> $O/play_$label.txt )
}
rm -rf suites/1
for s in xpbd featherstone semi mujoco; do one $s "$STOCK_VENV" 0 $s & done
wait
for s in vbd vbd_alm; do one $s "$STOCK_VENV" 0 $s & done
for s in featherstone semi; do one ${s}_patched "$PATCHED_VENV" 1 $s & done
wait
for l in xpbd featherstone semi mujoco vbd vbd_alm featherstone_patched semi_patched; do
  echo "== $l ($(tail -1 $O/play_$l.txt))"
  grep '^T[01][0-9]\|^SUITE' suites/1/$l/verdicts.txt 2>/dev/null || echo "no verdicts"
done > $O/reading.txt
