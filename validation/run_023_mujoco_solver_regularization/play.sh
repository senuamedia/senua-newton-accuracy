#!/usr/bin/env bash
# Run 023, a trace (not registered): which part of the pyramidal cone makes Newton's MuJoCo solver stop being a number
# at a friction of 0.001 or less (F3; runs 011, 012). Run 012 predicted, and found, that the elliptic cone plays where
# the pyramid fails, and named the pyramid's near-parallel edges, n + mu t and n - mu t, as the cause. Read since in
# MuJoCo Warp (constraint.py, the contact rows; _efc_row): each pyramid edge's regularization is
# R = 2 mu^2 (1 + mu^2) invweight / impratio x (1 - imp) / imp, and the solver weighs the row by D = 1 / R. So D grows
# as 1 / mu^2: about 1e7 for this cube at a friction of 0.001 (invweight 1 / 2 kg, imp 0.9 to 0.95 by the default solimp),
# beyond what 32-bit numbers resolve beside the cube's mass (their relative spacing is 1.2e-7), and 1e5 at 0.01. The
# elliptic cone's friction rows have R = invweight / impratio x (1 - imp) / imp, no mu^2.
# Hypothesis: the cause is the size of D, not the edges' angle. Then impratio, which scales R and leaves the edges
# alone, moves the failure: what fails is the product mu^2 / impratio on the pyramid, and 1 / impratio on the
# elliptic cone.
# The suite's drop of runs 011 and 012 (2 kg, half-size 0.04 m, from 80 mm, 0.5 s) at 2.5 ms and 0.15625 ms, Newton
# 1.6.1 from PyPI, solver=mujoco, every option at its default except the cone and impratio given below.
# Predicted, before the plays:
#   P1  the pyramid at a friction of 0.001 with impratio 0.01 (R as at 0.01 with impratio 1) plays.
#   P2  the pyramid at 1e-4 with impratio 1e-4 (R again as at 0.01) plays.
#   P3  the pyramid at 0.01 with impratio 100, and at 0.1 with impratio 10,000 (R as at 0.001), stop being a number.
#   P4  the elliptic cone at 0.01 with impratio 1e6 (its friction rows' D as large as the pyramid's at 0.001) stops
#       being a number.
#   P5  the pyramid at 0.001 and at 0.01 with impratio 1, as run 012, are run 012's files byte for byte.
#   Reported, not predicted: the pyramid at 0.001 with MuJoCo's CG solver (opt.solver=cg) in place of its Newton solver.
# usage: play.sh      (repository root, Newton from PyPI's environment on; writes the reading)
set -u
O=validation/run_023_mujoco_solver_regularization; W=$O/runs; mkdir -p $W
: > $W/log.txt
one() {  # <name> <dt> <rig settings...>
  local n=$1 dt=$2; shift 2
  python tools/nwt_contact.py $W/${n}_$dt.txt dt=$dt mass=2 radius=0.04 h0=0.08 secs=0.5 solver=mujoco "$@" \
    > $W/stats_${n}_$dt.txt 2>> $W/log.txt
}
date -u +%FT%TZ > $O/started.txt
for dt in 0.0025 0.00015625; do
  one pyr_0.001_imp1 $dt mu=0.001 opt.cone=pyramidal &
  one pyr_0.01_imp1 $dt mu=0.01 opt.cone=pyramidal &
  wait
  one pyr_0.001_imp0.01 $dt mu=0.001 opt.cone=pyramidal opt.impratio=0.01 &
  one pyr_0.0001_imp0.0001 $dt mu=0.0001 opt.cone=pyramidal opt.impratio=0.0001 &
  wait
  one pyr_0.01_imp100 $dt mu=0.01 opt.cone=pyramidal opt.impratio=100 &
  one pyr_0.1_imp10000 $dt mu=0.1 opt.cone=pyramidal opt.impratio=10000 &
  wait
  one ell_0.01_imp1e6 $dt mu=0.01 opt.cone=elliptic opt.impratio=1000000 &
  one pyr_0.001_imp1_cg $dt mu=0.001 opt.cone=pyramidal opt.solver=cg &
  wait
done
date -u +%FT%TZ > $O/finished.txt
{
  for n in pyr_0.001_imp1 pyr_0.01_imp1 pyr_0.001_imp0.01 pyr_0.0001_imp0.0001 pyr_0.01_imp100 pyr_0.1_imp10000 ell_0.01_imp1e6 pyr_0.001_imp1_cg; do
    for dt in 0.0025 0.00015625; do
      r=$(grep -o 'nan_at_step [0-9]*' $W/stats_${n}_$dt.txt || echo "plays")
      echo "$n, step $dt | $r | $(grep -o 'extra .*' $W/stats_${n}_$dt.txt)"
    done
  done
  for dt in 0.0025 0.00015625; do
    for mu in 0.001 0.01; do
      if cmp -s $W/pyr_${mu}_imp1_$dt.txt validation/run_012_mujoco_solver_cone/runs/drop_pyramidal_${mu}_$dt.txt; then r=yes; else r=NO; fi
      echo "P5 the pyramid at $mu, impratio 1, step $dt, byte-identical to run 012's: $r"
    done
  done
} > $O/reading.txt
cat $O/reading.txt
