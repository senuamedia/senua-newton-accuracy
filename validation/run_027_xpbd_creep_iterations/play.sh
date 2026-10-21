#!/usr/bin/env bash
# Run 027, a trace (not registered): why XPBD's hold creeps, in proportion to the step (F4; run 001: 10.9 mm/s at 2 ms
# to 0.17 mm/s at 0.031 ms on a 1 kg cube pushed at 0.6 of the friction limit). Read in the source
# (xpbd/kernels.py, solve_body_contact_positions; compute_contact_constraint_delta): each iteration a contact's friction
# undoes the slip its points have made since the step began, scaled by rigid_contact_relaxation (0.8), against the
# contact's effective mass, and the four corners' corrections are averaged (rigid_contact_con_weighting); 2 iterations by
# default. A cube's friction acts at its bottom corners, a half-size below its centre, so most of a corner's correction
# turns the cube rather than moving its centre (1 / m against r^2 / I = 1.5 / m: 40% of the correction moves the
# centre). What the step's iterations leave of the slip stays in the position and becomes the next step's
# velocity (XPBD reads its velocity back from the poses), so the creep is a fixed share of the push's speed gain a step,
# (F / m) h: proportional to the step.
# Hypothesis: the creep is XPBD's solve left unconverged within the step. Predicted, before the plays:
#   P1  on run 001's hold (1 kg, half-size 0.05 m, friction 0.5, 2.94 N from 0.5 s, 2 s) at 2 ms, the creep falls at
#       every doubling of iterations, 2, 4, 8, 16 and 32 (the default is 2), and at 32 it is under a tenth of its
#       value at 2.
#   P2  on a plate that cannot tip (run 004's: the same 1 kg, half-size 0.05 m, half-height 0.005 m; the
#       same push) at 2 ms and 2 iterations, the creep is under the cube's.
#   P3  with rigid_contact_relaxation 1 (each iteration undoes the whole slip) at 2 iterations, the cube's creep is
#       under its creep at 0.8.
#   Reported, not predicted: the same at 0.5 ms; the cube's largest turn. A check: at 2 iterations (the default,
#   given) the cube's plays are run 001's files byte for byte.
# usage: play.sh <sx_contact binary>   (repository root, Newton from PyPI's environment on; writes the reading)
set -u
B="${1:?usage: play.sh <sx_contact binary>}"
O=validation/run_027_xpbd_creep_iterations; W=$O/runs; mkdir -p $W
: > $W/stats.txt; : > $W/log.txt
HOLD="mass=1 radius=0.05 h0=0 mu=0.5 push=2.94 pushat=0.5 secs=2 solver=xpbd"
one() {  # <name> <dt> <rig settings...>
  local n=$1 dt=$2; shift 2
  python tools/nwt_contact.py $W/${n}_$dt.txt dt=$dt $HOLD "$@" 2>> $W/log.txt | sed "s/^STATS/STATS ${n}_$dt/" >> $W/stats.txt
}
date -u +%FT%TZ > $O/started.txt
for dt in 0.002 0.0005; do
  for it in 2 4 8 16 32; do one cube_it$it $dt opt.iterations=$it & done; wait
  one plate_it2 $dt hz=0.005 opt.iterations=2 &
  one cube_it2_relax1 $dt opt.iterations=2 opt.rigid_contact_relaxation=1.0 &
  wait
done
date -u +%FT%TZ > $O/finished.txt
{
  for dt in 0.002 0.0005; do
    for n in cube_it2 cube_it4 cube_it8 cube_it16 cube_it32 plate_it2 cube_it2_relax1; do
      echo "$n $dt s | $("$B" creep $W/${n}_$dt.txt | tail -1) | most_tilt_urad $(grep "^STATS ${n}_$dt " $W/stats.txt | grep -o 'most_tilt_urad [0-9]*' | cut -d' ' -f2)"
    done
  done
  for dt in 0.002 0.0005; do if cmp -s $W/cube_it2_$dt.txt validation/run_001_design_probes/runs/hold_xpbd_$dt.txt; then r=yes; else r=NO; fi; echo "CHECK cube at 2 iterations, $dt s, byte-identical to run 001's: $r"; done
  echo "plays that stopped being a number: $(grep -c nan_at_step $W/stats.txt)"
} > $O/reading.txt
cat $O/reading.txt
