#!/usr/bin/env bash
# Run 002, design probe (not registered): the cause of known issue N1 tested directly. Run 001 found SemiImplicit and
# Featherstone stop a 1 m/s slide (friction 0.4) at about a third of Coulomb's distance, decelerating at about 2/v
# times Coulomb's rate. The cause reported (draft PR #4010) is the Huber norm that smooths the friction's direction,
# friction_smoothing, 1.0 m/s by default. If it is the cause, narrowing it brings the slide back to Coulomb's.
#   the slide that ends, both solvers, friction_smoothing 1.0 (the default, given), 0.1, 0.01 and 0.001, at 1/16 and
#   1/64 of 2 ms; and the hold at 0.6 of the limit under the same, at 1/64 (does narrowing it change the creep).
# usage: probe.sh <sx_contact binary>     (from the repository root, Newton's Python environment on; writes the reading)
set -u
B="${1:?usage: probe.sh <sx_contact binary>}"
T="python tools/nwt_contact.py"; O=validation/run_002_friction_smoothing; W=$O/runs; mkdir -p $W
play() {  # one solver, every smoothing
  local s=$1 fs dt
  for fs in 1.0 0.1 0.01 0.001; do
    for dt in 0.000125 0.00003125; do
      $T $W/slide_${s}_${fs}_$dt.txt dt=$dt h0=0 vx0=1 mu=0.4 secs=1 solver=$s opt.friction_smoothing=$fs
    done
    $T $W/hold_${s}_${fs}_0.00003125.txt dt=0.00003125 h0=0 mu=0.5 push=2.94 pushat=0.5 secs=2 solver=$s opt.friction_smoothing=$fs
  done
}
for s in semi featherstone; do play $s > $W/stats_$s.txt 2> $W/log_$s.txt & done
wait
for s in semi featherstone; do
  for fs in 1.0 0.1 0.01 0.001; do
    for dt in 0.000125 0.00003125; do
      f=$W/slide_${s}_${fs}_$dt.txt
      echo "$s smoothing $fs slide $dt | $($B stop $f | tail -1) | $($B accel $f 10 20 | tail -1 | grep -o 'mean_acceleration_mm_s2 [-0-9]*')"
    done
    echo "$s smoothing $fs hold 0.00003125 | $($B creep $W/hold_${s}_${fs}_0.00003125.txt | tail -1)"
  done
done
# a check on the rig: the default given explicitly must play as run 001 played it without
for s in semi featherstone; do
  for dt in 0.000125 0.00003125; do
    if cmp -s validation/run_001_design_probes/runs/slide_${s}_$dt.txt $W/slide_${s}_1.0_$dt.txt; then r=yes; else r=NO; fi
    echo "CHECK $s slide $dt with friction_smoothing=1.0 given, byte-identical to run 001's: $r"
  done
done
