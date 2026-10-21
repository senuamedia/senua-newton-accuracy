#!/usr/bin/env bash
# Run 044, a trace (not registered): the floor of XPBD's creep at rest. Run 027 found most of XPBD's creep is its solve
# left unconverged, but a floor proportional to the step remains at 16 and 32 iterations (1,531 um/s at 2 ms and
# 380 um/s at 0.5 ms on run 001's hold, a quarter of the push's speed gain a step, (F / m) h).
# Read in the source (xpbd/kernels.py, solve_body_contact_positions): each iteration a corner's friction correction is
# limited by mu times that same iteration's normal correction at that corner ("limit friction based on incremental
# normal force, good approximation to limiting on total force"), not by mu times the normal force the contact carries.
# At rest the normal corrections of a step add up to the step's sink, g h^2, and they shrink from iteration to
# iteration as the penetration is undone, while a corner's friction correction mostly turns the cube (its corners are
# a half-size below its centre) and the turn is undone by the normal correction, so the friction must undo the slip
# several times over within the same budget. Hypothesis: the floor is that limit, the friction running out of
# incremental normal correction before the slip is undone; what is left becomes the next step's speed.
# Run 001's hold (1 kg, half-size 0.05 m, 2.94 N along x from 0.5 s, 2 s) on XPBD, Newton 1.6.1 from PyPI.
# Predicted, before the plays:
#   P1  with the friction coefficient 5 in place of 0.5 (the same push, now 0.06 of the friction limit, so the limit
#       is ten times further away) at 32 iterations, the creep is under a tenth of run 027's at 0.5: under 153 um/s at
#       2 ms and under 38 um/s at 0.5 ms.
#   P2  with friction 0.5 and the push halved (1.47 N, 0.3 of the friction limit) at 32 iterations, the creep is under
#       half of run 027's with the full push: under 765 um/s at 2 ms and under 190 um/s at 0.5 ms (a limit that binds
#       acts more than in proportion to the push).
#   P3  the floor is converged: at 64 iterations, 2 ms, the creep is within 5 in 100 of its value at 32 (1,531 um/s).
#   Reported, not predicted: friction 1 at 32 iterations; a plate that cannot tip (run 027's, half-height 0.005 m) at
#   32 iterations; rigid_contact_relaxation 0.5 and 1 at 32 iterations; the full push at 32 iterations at 0.125 ms.
#   A check: friction 0.5, 32 iterations, 2 ms and 0.5 ms, given, are run 027's files byte for byte.
# usage: play.sh <sx_contact binary>   (repository root, Newton from PyPI's environment on; writes the reading)
set -u
B="${1:?usage: play.sh <sx_contact binary>}"
O=validation/run_044_xpbd_creep_floor; W=$O/runs; mkdir -p $W
: > $W/stats.txt; : > $W/log.txt
HOLD="mass=1 radius=0.05 h0=0 pushat=0.5 secs=2 solver=xpbd"
one() {  # <name> <dt> <rig settings...>
  local n=$1 dt=$2; shift 2
  python tools/nwt_contact.py $W/${n}_$dt.txt dt=$dt $HOLD "$@" 2>> $W/log.txt | sed "s/^STATS/STATS ${n}_$dt/" >> $W/stats.txt
}
date -u +%FT%TZ > $O/started.txt
for dt in 0.002 0.0005; do
  one mu05_it32 $dt mu=0.5 push=2.94 opt.iterations=32 &
  one mu5_it32 $dt mu=5 push=2.94 opt.iterations=32 &
  one mu05_half_it32 $dt mu=0.5 push=1.47 opt.iterations=32 &
  wait
done
one mu05_it64 0.002 mu=0.5 push=2.94 opt.iterations=64 &
one mu1_it32 0.002 mu=1 push=2.94 opt.iterations=32 &
one plate_it32 0.002 mu=0.5 push=2.94 hz=0.005 opt.iterations=32 &
wait
one relax05_it32 0.002 mu=0.5 push=2.94 opt.iterations=32 opt.rigid_contact_relaxation=0.5 &
one relax1_it32 0.002 mu=0.5 push=2.94 opt.iterations=32 opt.rigid_contact_relaxation=1.0 &
one mu05_it32 0.000125 mu=0.5 push=2.94 opt.iterations=32 &
wait
date -u +%FT%TZ > $O/finished.txt
{
  for f in $W/*_0*.txt; do
    n=$(basename $f .txt)
    echo "$n | $("$B" creep $f | tail -1) | most_tilt_urad $(grep "^STATS $n " $W/stats.txt | grep -o 'most_tilt_urad [0-9]*' | cut -d' ' -f2)"
  done
  for dt in 0.002 0.0005; do if cmp -s $W/mu05_it32_$dt.txt validation/run_027_xpbd_creep_iterations/runs/cube_it32_$dt.txt; then r=yes; else r=NO; fi; echo "CHECK friction 0.5, 32 iterations, $dt s, byte-identical to run 027's: $r"; done
  echo "plays that stopped being a number: $(grep -c nan_at_step $W/stats.txt)"
} > $O/reading.txt
cat $O/reading.txt
