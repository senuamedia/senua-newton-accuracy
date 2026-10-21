#!/usr/bin/env bash
# Run 011, design probe (not registered): runs 009 and 010 found Newton's MuJoCo solver stopping being a number at
# the first contact with a friction of 1e-5 and of 2e-5, above MuJoCo Warp's stated floor of 1e-5, where run 001 played
# frictions of 0.3 to 0.5 without fault. Where does it start to play? The suite's drop (2 kg, half-size 0.04 m, from
# 80 mm, 0.5 s) at 2.5 ms and 0.156 ms, with frictions from 1e-4 to 0.3, on the MuJoCo solver; the reading is the
# step at which each play stopped being a number, or none.
# usage: probe.sh      (from the repository root, Newton's Python environment on; writes the reading)
set -u
O=validation/run_011_mujoco_solver_low_friction; W=$O/runs; mkdir -p $W
for mu in 0.0001 0.001 0.01 0.03 0.1 0.3; do
  for dt in 0.0025 0.00015625; do
    python tools/nwt_contact.py $W/drop_${mu}_$dt.txt dt=$dt mass=2 radius=0.04 h0=0.08 secs=0.5 mu=$mu solver=mujoco \
      > $W/stats_${mu}_$dt.txt 2>> $W/log.txt
    r=$(grep -o 'nan_at_step [0-9]*' $W/stats_${mu}_$dt.txt || echo "no NaN")
    echo "friction $mu, step $dt | $r"
  done
done
