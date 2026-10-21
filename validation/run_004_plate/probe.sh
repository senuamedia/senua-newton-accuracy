#!/usr/bin/env bash
# Run 004, design probe (not registered): Newton's friction law for SemiImplicit and Featherstone, read on a body that
# cannot tip. Runs 002 and 003 slid a cube; the cube tipped (up to 0.64 rad), which hid the friction law behind the
# rocking. Here the body is a flat plate (10 cm square, 1 cm thick, 1 kg; the rig's new hz setting), set down from
# 2 mm, left 0.3 s to settle, then kicked to 1 m/s along x; friction 0.4; Coulomb's deceleration is 3,920 mm/s2 and
# Coulomb's distance 127,551 um.
# What the kernel predicts (eval_body_contact: friction = vt / H(vt) * min(kf * H(vt), mu * N), H Warp's unscaled Huber
# norm, 1/2 |v|^2 up to the width d and d (|v| - d/2) above it), while the plate slides at about 0.95 m/s and the
# second term is mu * N: friction |v| / H(v) times Coulomb's: about 2.1 times with the default width of 1 m/s, about
# 10.6 times with 0.1 and about 100 times with 0.01 (the plate would stop within a few millimetres). Written before
# the plays; this is a design probe, so the prediction is a check of the reading of the kernel, not a registered rule.
#   SemiImplicit with friction_smoothing 1.0 (default), 0.1, 0.01; Featherstone 1.0 and 0.01; XPBD and the MuJoCo
#   solver with their defaults; at 0.125 ms, and SemiImplicit 1.0 and 0.01 also at 0.031 ms.
# A check on the rig: a cube play (no hz) is byte-identical to run 001's (the rest at 0.125 ms on SemiImplicit).
# usage: probe.sh <sx_contact binary>     (from the repository root, Newton's Python environment on; writes the reading)
set -u
B="${1:?usage: probe.sh <sx_contact binary>}"
T="python tools/nwt_contact.py"; O=validation/run_004_plate; W=$O/runs; mkdir -p $W
PLATE="radius=0.05 hz=0.005 h0=0.002 mu=0.4 kick=1 kickat=0.3 secs=1.3"
p() { local label=$1 dt=$2 s=$3; shift 3; $T $W/plate_${label}_$dt.txt dt=$dt $PLATE solver=$s "$@"; }
{ p semi_1.0 0.000125 semi; p semi_0.1 0.000125 semi opt.friction_smoothing=0.1; p semi_0.01 0.000125 semi opt.friction_smoothing=0.01; } > $W/stats_semi.txt 2> $W/log_semi.txt &
{ p semi_1.0 0.00003125 semi; p semi_0.01 0.00003125 semi opt.friction_smoothing=0.01; } > $W/stats_semi_fine.txt 2> $W/log_semi_fine.txt &
{ p featherstone_1.0 0.000125 featherstone; p featherstone_0.01 0.000125 featherstone opt.friction_smoothing=0.01; } > $W/stats_featherstone.txt 2> $W/log_featherstone.txt &
{ p xpbd 0.000125 xpbd; p mujoco 0.000125 mujoco; } > $W/stats_ref.txt 2> $W/log_ref.txt &
wait
$T $W/check_rest_semi_0.000125.txt dt=0.000125 h0=0.02 mu=0.5 secs=1 solver=semi > $W/stats_check.txt 2>> $W/log_ref.txt
if cmp -s $W/check_rest_semi_0.000125.txt validation/run_001_design_probes/runs/rest_semi_0.000125.txt; then r=yes; else r=NO; fi
echo "CHECK a cube play is byte-identical to run 001's: $r"
for f in $W/plate_*.txt; do
  n=$(basename $f .txt)
  echo "$n | $($B stop $f | tail -1 | grep -o 'slid_um [0-9]* came_back_um [0-9]*') | 301-302 ms $($B accel $f 301 302 | tail -1 | grep -o 'mean_acceleration_mm_s2 [-0-9]*') | 302-305 ms $($B accel $f 302 305 | tail -1 | grep -o 'mean_acceleration_mm_s2 [-0-9]*') | 310-320 ms $($B accel $f 310 320 | tail -1 | grep -o 'mean_acceleration_mm_s2 [-0-9]*') | 330-350 ms $($B accel $f 330 350 | tail -1 | grep -o 'mean_acceleration_mm_s2 [-0-9]*')"
done
