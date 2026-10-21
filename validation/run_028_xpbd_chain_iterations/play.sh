#!/usr/bin/env bash
# Run 028, a trace (not registered): why XPBD takes energy out of a free two-link chain (F9; run 014: it keeps 69.9% of
# the kinetic energy after 2 s at 10 ms, 89.0% at 2.5 ms, 96.7% at 0.625 ms, 99.1% at 0.156 ms: first order in the
# step). XPBD moves each body by its velocity, projects the joints back together (2 iterations by default, joint
# relaxations 0.7 linear and 0.4 angular) and reads the velocity back from the poses. Two causes are possible: the
# projection itself, which removes the velocity along the joint's constraint each step (first order in the step whatever
# the iterations: an inelastic projection), or the solve left unconverged within the step, as run 027 found for most of
# XPBD's creep at rest.
# Hypothesis: the projection's own dissipation, not its convergence. Predicted, before the plays:
#   P1  on run 014's free chain at 10 ms and 2.5 ms, 32 iterations in place of 2 leave at least half of the energy
#       loss (the chain keeps at most 85% at 10 ms and at most 94.5% at 2.5 ms).
#   P2  the loss stays first order in the step at 32 iterations: the loss at 2.5 ms is between a sixth and a third of
#       the loss at 10 ms.
#   Reported, not predicted: 8 iterations; the angular momentum.
# Check: at 2 iterations (the default, given) the plays are run 014's files byte for byte.
# usage: play.sh <sx_contact binary>   (repository root, Newton from PyPI's environment on; writes the reading)
set -u
B="${1:?usage: play.sh <sx_contact binary>}"
O=validation/run_028_xpbd_chain_iterations; W=$O/runs; mkdir -p $W
ARMS="mass1=1.2 mass2=0.6 radius=0.04 arm1=0.25 len1=0.5 arm2=0.2"
FREE="gravity=0 angle2=-0.9 omega1=2.5 omega2=1.5 secs=2"
dt_of() { awk -v k=$1 'BEGIN { printf "%.12f", 0.01 / k }'; }
date -u +%FT%TZ > $O/started.txt
for k in 1 4; do
  for it in 2 8 32; do
    python tools/nwt_chain.py $W/free_xpbd_it${it}_$k.txt dt=$(dt_of $k) $ARMS $FREE solver=xpbd opt.iterations=$it \
      > $W/free_xpbd_it${it}_$k.stats 2> $W/free_xpbd_it${it}_$k.log &
  done
  wait
done
date -u +%FT%TZ > $O/finished.txt
{
  for k in 1 4; do for it in 2 8 32; do
    s=$(grep -o 'out_of_range_at_step [0-9]*\|nan_at_step [0-9]*' $W/free_xpbd_it${it}_$k.stats || echo "plays")
    echo "free xpbd 1/$k iterations $it | $s | $("$B" chain $W/free_xpbd_it${it}_$k.txt | tail -1)"
  done; done
  for k in 1 4; do
    if cmp -s $W/free_xpbd_it2_$k.txt validation/run_014_chain/runs/free_xpbd_$k.txt; then r=yes; else r=NO; fi
    echo "CHECK 2 iterations, 1/$k, byte-identical to run 014's: $r"
  done
} > $O/reading.txt
cat $O/reading.txt
