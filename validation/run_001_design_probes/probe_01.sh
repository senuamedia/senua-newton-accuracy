#!/usr/bin/env bash
# Design probe 01 (not registered): the first deep dive's one-cube known-answer scenes, the same scenes as the MuJoCo
# deep dive's probe 01, played on Newton v1.6.1 as installed from PyPI (newton[sim]==1.6.1), on each of its five
# solvers with their own defaults (and VBD a second time on the contact path Newton says will become its default), at
# 2 ms and at 1/4, 1/16 and 1/64 of it, on Warp's CPU device; read by the same Simplex measuring program. The solvers
# play in parallel, one process each; each play is its own process.
# usage: probe_01.sh <sx_contact binary> [solver ...]        (from the repository root, Newton's Python environment on)
set -u
B="${1:?usage: probe_01.sh <sx_contact binary> [solver ...]}"; shift
SOLVERS="${*:-xpbd featherstone semi mujoco vbd vbd_alm}"
T="python tools/nwt_contact.py"; O=validation/run_001_design_probes; W=$O/runs; mkdir -p $W
STEPS="0.002 0.0005 0.000125 0.00003125"
play() {  # one solver, every scene at every step
  local s=$1 dt
  for dt in $STEPS; do
    # the hold: 1 kg, half-size 0.05 m, friction 0.5, pushed with 0.6 of what friction can hold (2.94 N) from 0.5 s
    $T $W/hold_${s}_$dt.txt dt=$dt h0=0 mu=0.5 push=2.94 pushat=0.5 secs=2 solver=$s
    # set down from 20 mm and left to rest
    $T $W/rest_${s}_$dt.txt dt=$dt h0=0.02 mu=0.5 secs=1 solver=$s
    # dropped from 100 mm with no friction: the bounce
    $T $W/bounce_${s}_$dt.txt dt=$dt h0=0.1 mu=0 secs=1 solver=$s
    # landing obliquely: from 50 mm at 2 m/s, friction 0.3
    $T $W/oblique_${s}_$dt.txt dt=$dt h0=0.05 vx0=2 mu=0.3 secs=0.5 solver=$s
    # a slide that ends: resting, given 1 m/s along x, friction 0.4 (Coulomb's distance 127.55 mm)
    $T $W/slide_${s}_$dt.txt dt=$dt h0=0 vx0=1 mu=0.4 secs=1 solver=$s
  done
  # determinism: the hold at 2 ms played a second time
  $T $W/hold_${s}_again.txt dt=0.002 h0=0 mu=0.5 push=2.94 pushat=0.5 secs=2 solver=$s
}
for s in $SOLVERS; do play $s > $W/stats_$s.txt 2> $W/log_$s.txt & done
wait
for s in $SOLVERS; do
  if cmp -s $W/hold_${s}_0.002.txt $W/hold_${s}_again.txt; then echo "DETERMINISM $s hold played twice: byte-identical"
  else echo "DETERMINISM $s hold played twice: DIFFERS"; fi
  for dt in $STEPS; do
    echo "$s hold $dt | $($B creep $W/hold_${s}_$dt.txt | tail -1)"
    echo "$s rest $dt | $($B rest $W/rest_${s}_$dt.txt | tail -1)"
    echo "$s bounce $dt | $($B bounce $W/bounce_${s}_$dt.txt | tail -1)"
    echo "$s oblique $dt | $($B impact $W/oblique_${s}_$dt.txt | tail -1)"
    echo "$s slide $dt | $($B stop $W/slide_${s}_$dt.txt | tail -1)"
  done
done
