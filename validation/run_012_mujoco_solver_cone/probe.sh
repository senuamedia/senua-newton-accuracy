#!/usr/bin/env bash
# Run 012, design probe (not registered): run 011 found Newton's MuJoCo solver stopping being a number at the first
# contact of a shape with a friction of 0.001 or less, and playing from 0.01. Prediction, written before the plays:
# the default friction cone is a pyramid whose opposite edges are n + mu t and n - mu t; at a friction of 0.001 they
# differ in the third decimal place of a 32-bit number, so the constraint's matrix is nearly singular in MuJoCo Warp's
# 32-bit arithmetic. If that is the cause, the elliptic cone (one normal row and two friction rows, no near-parallel
# edges) plays where the pyramid fails. The suite's drop of run 011 (2 kg, half-size 0.04 m, from 80 mm, 0.5 s) at
# 2.5 ms and 0.156 ms, frictions 0, 1e-5, 1e-4, 1e-3 and 0.01, on the MuJoCo solver with the pyramidal cone (its
# default, given explicitly) and the elliptic cone (the rig's opt.cone).
# A check on the rig: the friction 0.01 drop with the default cone, given explicitly, must be byte-identical to run
# 011's without it.
# usage: probe.sh      (from the repository root, Newton's Python environment on; writes the reading)
set -u
O=validation/run_012_mujoco_solver_cone; W=$O/runs; mkdir -p $W
for cone in pyramidal elliptic; do
  for mu in 0 0.00001 0.0001 0.001 0.01; do
    for dt in 0.0025 0.00015625; do
      python tools/nwt_contact.py $W/drop_${cone}_${mu}_$dt.txt dt=$dt mass=2 radius=0.04 h0=0.08 secs=0.5 mu=$mu \
        solver=mujoco opt.cone=$cone > $W/stats_${cone}_${mu}_$dt.txt 2>> $W/log.txt
      r=$(grep -o 'nan_at_step [0-9]*' $W/stats_${cone}_${mu}_$dt.txt || echo "plays")
      echo "cone $cone, friction $mu, step $dt | $r"
    done
  done
done
for dt in 0.0025 0.00015625; do
  if cmp -s $W/drop_pyramidal_0.01_$dt.txt validation/run_011_mujoco_solver_low_friction/runs/drop_0.01_$dt.txt; then r=yes; else r=NO; fi
  echo "CHECK the default cone given explicitly, friction 0.01, step $dt, byte-identical to run 011's: $r"
done
