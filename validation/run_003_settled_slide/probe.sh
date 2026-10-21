#!/usr/bin/env bash
# Run 003, design probe (not registered), following run 002: is the violent onset of a slide under a narrow friction
# smoothing an artefact of setting the cube sliding at the instant it first touches the ground? Here the cube is set
# down from 2 mm, left 0.3 s to settle, then kicked to 1 m/s along x (the rig's new kick setting), friction 0.4.
#   SemiImplicit and Featherstone with friction_smoothing 1.0 (the default) and 0.01; XPBD and the MuJoCo solver with
#   their defaults, for reference; at 0.125 and 0.031 ms.
# A check on the rig: a play without a kick is byte-identical to run 001's (the rest at 0.125 ms on SemiImplicit).
# usage: probe.sh <sx_contact binary>     (from the repository root, Newton's Python environment on; writes the reading)
set -u
B="${1:?usage: probe.sh <sx_contact binary>}"
T="python tools/nwt_contact.py"; O=validation/run_003_settled_slide; W=$O/runs; mkdir -p $W
SLIDE="h0=0.002 mu=0.4 kick=1 kickat=0.3 secs=1.3"
play() {  # <label> <solver> [option]: the settled slide at both steps
  local label=$1 s=$2 dt; shift 2
  for dt in 0.000125 0.00003125; do
    # shellcheck disable=SC2086
    $T $W/slide_${label}_$dt.txt dt=$dt $SLIDE solver=$s "$@"
  done
}
{ play semi_1.0 semi; play semi_0.01 semi opt.friction_smoothing=0.01; } > $W/stats_semi.txt 2> $W/log_semi.txt &
{ play featherstone_1.0 featherstone; play featherstone_0.01 featherstone opt.friction_smoothing=0.01; } > $W/stats_featherstone.txt 2> $W/log_featherstone.txt &
{ play xpbd xpbd; play mujoco mujoco; } > $W/stats_ref.txt 2> $W/log_ref.txt &
$T $W/check_rest_semi_0.000125.txt dt=0.000125 h0=0.02 mu=0.5 secs=1 solver=semi > $W/stats_check.txt 2>> $W/log_ref.txt
wait
if cmp -s $W/check_rest_semi_0.000125.txt validation/run_001_design_probes/runs/rest_semi_0.000125.txt; then r=yes; else r=NO; fi
echo "CHECK a play without a kick is byte-identical to run 001's: $r"
for label in semi_1.0 semi_0.01 featherstone_1.0 featherstone_0.01 xpbd mujoco; do
  for dt in 0.000125 0.00003125; do
    f=$W/slide_${label}_$dt.txt
    echo "$label $dt | $($B stop $f | tail -1) | 300-305 ms $($B accel $f 300 305 | tail -1 | grep -o 'mean_acceleration_mm_s2 [-0-9]*') | 310-320 ms $($B accel $f 310 320 | tail -1 | grep -o 'mean_acceleration_mm_s2 [-0-9]*') | 330-350 ms $($B accel $f 330 350 | tail -1 | grep -o 'mean_acceleration_mm_s2 [-0-9]*')"
  done
done
